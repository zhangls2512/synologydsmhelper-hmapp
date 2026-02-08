import { dataSharePredicates, preferences } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { deviceInfo } from '@kit.BasicServicesKit'
import { Environment, fileIo, fileUri } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { AccountInfo, getAccountHash, getAccountInfo } from './Account'
import { read, write } from './File'
import { getPermission } from './Permission'
import { BackupSetting } from '../pages/Backupsetting'

export interface BackupTask {
  id: string,
  type: string,
  srcFileUri: string,
  modifyTime: number,
  path: string,
  status: string
}

interface PhotoItem {
  uri: string,
  name: string,
  size: number,
  modifyTime: number,
  albumId: number
}

interface AlbumItem {
  id: string,
  name: string
}

export async function startBackupTask(context: Context, id: string) {
  const accountInfo = await getAccountInfo()
  if (accountInfo.id) {
    const filePath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/' + id + '.txt'
    const filestring = await read(filePath, true)
    if (filestring !== 'fail') {
      const backupTask = JSON.parse(filestring) as BackupTask
      const transferTaskDataPreferences = preferences.getPreferencesSync(context, {
        name: 'transferTask'
      })
      const id = util.generateRandomUUID()
      transferTaskDataPreferences.putSync(id, JSON.stringify({
        id: id,
        path: backupTask.path,
        name: new fileUri.FileUri(backupTask.srcFileUri).name,
        transferredSize: 0,
        totalSize: fileIo.statSync(backupTask.srcFileUri).size,
        status: 'pending',
        errCode: 0,
        type: 'upload',
        accountInfo: accountInfo,
        srcFileUri: backupTask.srcFileUri,
        backupTaskId: id
      }))
      backupTask.status = 'pending'
      await write(filePath, JSON.stringify(backupTask))
    }
  }
}

export async function getBackupTaskList(context: Context) {
  const accountInfo = await getAccountInfo()
  if (accountInfo.id) {
    const backupTaskArray: BackupTask[] = []
    const dirPath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/'
    if (fileIo.accessSync(dirPath)) {
      const fileNames = await fileIo.listFile(dirPath)
      const promises = fileNames.map(async (item) => {
        const filestring = await read(dirPath + item)
        backupTaskArray.push(JSON.parse(filestring))
      })
      await Promise.all(promises)
      return backupTaskArray
    }
  }
  return []
}

export async function updateBackupTaskStatus(context: Context, accountInfo: AccountInfo, id: string,
  success: boolean) {
  const filePath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/' + id + '.txt'
  const filestring = await read(filePath, true)
  if (filestring !== 'fail') {
    const backupTask = JSON.parse(filestring) as BackupTask
    backupTask.status = success ? 'success' : 'fail'
    await write(filePath, JSON.stringify(backupTask))
  }
}

export async function deleteBackupTask(context: Context, accountInfo: AccountInfo, id: string) {
  const filePath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/' + id + '.txt'
  if (fileIo.accessSync(filePath)) {
    await fileIo.unlink(filePath)
  }
}

export async function generateBackupTaskList(context: Context, type: string) {
  const accountInfo = await getAccountInfo()
  if (accountInfo.id) {
    const backupTaskArray: BackupTask[] = []
    const dirPath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/'
    if (fileIo.accessSync(dirPath)) {
      const fileNames = await fileIo.listFile(dirPath)
      const promises = fileNames.map(async (item) => {
        const filestring = await read(dirPath + item)
        backupTaskArray.push(JSON.parse(filestring))
      })
      await Promise.all(promises)
    }
    const finishedArray = backupTaskArray.filter(item => item.type === type && item.status !== 'pending')
    let latestMotifyTime = 0
    finishedArray.forEach((item) => {
      if (item.modifyTime > latestMotifyTime) {
        latestMotifyTime = item.modifyTime
      }
    })
    if (type === '相册') {
      const allow = getPermission('ohos.permission.READ_IMAGEVIDEO')
      if (allow) {
        const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context)
        const albumRes =
          await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.USER, photoAccessHelper.AlbumSubtype.ANY, {
            fetchColumns: [],
            predicates: new dataSharePredicates.DataSharePredicates()
          })
        const albums = await albumRes.getAllObjects()
        const albumArray = albums.map((item): AlbumItem => {
          return {
            id: item.albumUri.substring(item.albumUri.lastIndexOf('/') + 1),
            name: item.albumName
          }
        })
        const photoRes = await phAccessHelper.getAssets({
          fetchColumns: ['uri', 'display_name', 'size', 'date_modified', 'title', 'owner_album_id'],
          predicates: new dataSharePredicates.DataSharePredicates()
        })
        await phAccessHelper.release()
        const photos = await photoRes.getAllObjects()
        const photoArray = photos.map((item): PhotoItem => {
          return {
            uri: item.uri,
            name: item.displayName,
            size: item.get('size') as number,
            modifyTime: item.get('date_modified') as number,
            albumId: item.get('owner_album_id') as number
          }
        })
        for (let i = 0; i < photoArray.length; i++) {
          const item = photoArray[i]
          if (item.modifyTime > latestMotifyTime) {
            const backupTaskIndex = backupTaskArray.findIndex(backupTaskItem => backupTaskItem.srcFileUri === item.uri)
            if (backupTaskIndex !== -1) {
              backupTaskArray.splice(backupTaskIndex, 1)
              await deleteBackupTask(context, accountInfo, backupTaskArray[backupTaskIndex].id)
            }
            let albumName = ''
            const album = albumArray.find(albumItem => albumItem.id === String(item.albumId))
            if (album) {
              albumName = '/' + album.name
            }
            const id = util.generateRandomUUID()
            backupTaskArray.push({
              id: id,
              type: type,
              srcFileUri: item.uri,
              modifyTime: item.modifyTime,
              path: '/home/Photos/backup/' + deviceInfo.marketName + albumName,
              status: 'pending'
            })
            await write(dirPath + id + '.txt', JSON.stringify({
              id: id,
              type: type,
              srcFileUri: item.uri,
              modifyTime: item.modifyTime,
              path: '/home/Photos/backup/' + deviceInfo.marketName + albumName,
              status: 'pending'
            }))
          }
        }
      }
    }
    let dir = ''
    if (type === '文档') {
      const allow = getPermission('ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY')
      if (allow) {
        dir = Environment.getUserDocumentDir()
      }
    }
    if (type === '桌面') {
      const allow = getPermission('ohos.permission.READ_WRITE_DESKTOP_DIRECTORY')
      if (allow) {
        dir = Environment.getUserDesktopDir()
      }
    }
    if (type !== '相册' && dir) {
      const res = await fileIo.listFile(dir, {
        recursion: true
      })
      for (let i = 0; i < res.length; i++) {
        const item = res[i]
        const path = dir + '/' + item
        const stat = fileIo.statSync(path)
        if (!stat.isDirectory() && stat.mtime > latestMotifyTime) {
          const uri = fileUri.getUriFromPath(path)
          const backupTaskIndex = backupTaskArray.findIndex(item => item.srcFileUri === uri)
          if (backupTaskIndex !== -1) {
            backupTaskArray.splice(backupTaskIndex, 1)
            await deleteBackupTask(context, accountInfo, backupTaskArray[backupTaskIndex].id)
          }
          const id = util.generateRandomUUID()
          backupTaskArray.push({
            id: id,
            type: type,
            srcFileUri: uri,
            modifyTime: stat.mtime,
            path: '/home/' + type + '备份/' + deviceInfo.marketName + '/' + item.substring(0, item.lastIndexOf('/')),
            status: 'pending'
          })
          await write(dirPath + id + '.txt', JSON.stringify({
            id: id,
            type: type,
            srcFileUri: uri,
            modifyTime: stat.mtime,
            path: '/home/' + type + '备份/' + deviceInfo.marketName + '/' + item.substring(0, item.lastIndexOf('/')),
            status: 'pending'
          }))
        }
      }
    }
    const promises = backupTaskArray.map(async (item) => {
      if (item.type === type && item.status === 'pending') {
        await startBackupTask(context, item.id)
      }
    })
    await Promise.all(promises)
  }
}

export async function autoBackup(context: Context) {
  const accountInfo = await getAccountInfo()
  if (accountInfo.id) {
    const filePath = context.filesDir + '/backupsetting/' + getAccountHash(accountInfo) + '.txt'
    const filestring = await read(filePath, true)
    if (filestring !== 'fail') {
      const autoTypes = (JSON.parse(filestring) as BackupSetting).autoTypes
      const promises = autoTypes.map(async (item) => {
        await generateBackupTaskList(context, item)
      })
      await Promise.all(promises)
    }
  }
}