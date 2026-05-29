import { dataSharePredicates, sendablePreferences } from '@kit.ArkData'
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

export interface AlbumItem {
  id: string,
  name: string,
  uri: string
}

export async function getAlbumList(context: Context) {
  const allow = getPermission('ohos.permission.READ_IMAGEVIDEO')
  if (allow) {
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context)
    const albumRes =
      await phAccessHelper.getAlbums(photoAccessHelper.AlbumType.USER, photoAccessHelper.AlbumSubtype.ANY, {
        fetchColumns: [],
        predicates: new dataSharePredicates.DataSharePredicates()
      })
    await phAccessHelper.release()
    const albums = await albumRes.getAllObjects()
    return albums.map((item): AlbumItem => {
      return {
        id: item.albumUri.substring(item.albumUri.lastIndexOf('/') + 1),
        name: item.albumName,
        uri: item.albumUri
      }
    })
  }
  return []
}

export async function startBackupTask(context: Context, id: string) {
  const accountInfo = await getAccountInfo(context)
  if (accountInfo.id) {
    const filePath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/' + id + '.txt'
    const filestring = await read(filePath, true)
    if (filestring !== 'fail') {
      const backupTask = JSON.parse(filestring) as BackupTask
      const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(context, {
        name: 'transferTask'
      })
      const transferTaskId = util.generateRandomUUID()
      transferTaskDataPreferences.putSync(transferTaskId, JSON.stringify({
        id: transferTaskId,
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
  const accountInfo = await getAccountInfo(context)
  if (accountInfo.id) {
    const backupTaskArray: BackupTask[] = []
    const dirPath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/'
    if (fileIo.accessSync(dirPath)) {
      const fileNames = await fileIo.listFile(dirPath)
      for (let i = 0; i < fileNames.length; i++) {
        const item = fileNames[i]
        const filestring = await read(dirPath + item)
        backupTaskArray.push(JSON.parse(filestring))
      }
      return backupTaskArray
    }
  }
  return []
}

export async function updateBackupTaskStatus(context: Context, accountInfo: AccountInfo, id: string,
  success: boolean) {
  try {
    const filePath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/' + id + '.txt'
    const filestring = await read(filePath, true)
    if (filestring !== 'fail') {
      const backupTask = JSON.parse(filestring) as BackupTask
      backupTask.status = success ? 'success' : 'fail'
      await write(filePath, JSON.stringify(backupTask))
    }
  } catch {
  }
}

export async function deleteBackupTask(context: Context, accountInfo: AccountInfo, id: string) {
  const filePath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/' + id + '.txt'
  if (fileIo.accessSync(filePath)) {
    await fileIo.unlink(filePath)
  }
}

export async function generateBackupTaskList(context: Context, type: string, albumUris: string[]) {
  const accountInfo = await getAccountInfo(context)
  if (accountInfo.id) {
    let backupTaskArray = await getBackupTaskList(context)
    backupTaskArray = backupTaskArray.filter(item => item.type === type)
    const finishedArray = backupTaskArray.filter(item => item.status !== 'pending')
    let latestMotifyTime = 0
    finishedArray.forEach(item => {
      if (item.modifyTime > latestMotifyTime) {
        latestMotifyTime = item.modifyTime
      }
    })
    backupTaskArray = backupTaskArray.filter(item => item.status === 'pending')
    const dirPath = getAccountHash(accountInfo, context, context.filesDir + '/backuptask') + '/'
    if (type === '相册') {
      const allow = getPermission('ohos.permission.READ_IMAGEVIDEO')
      if (allow) {
        const albumArray = await getAlbumList(context)
        const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context)
        const photoRes = await phAccessHelper.getAssets({
          fetchColumns: ['uri', 'display_name', 'size', 'date_modified', 'owner_album_id'],
          predicates: new dataSharePredicates.DataSharePredicates()
        })
        await phAccessHelper.release()
        const photos = await photoRes.getAllObjects()
        for (let i = 0; i < photos.length; i++) {
          const item = photos[i]
          if (item.get('date_modified') > latestMotifyTime) {
            const backupTaskIndex =
              backupTaskArray.findIndex(backupTaskItem => backupTaskItem.srcFileUri === item.uri)
            if (backupTaskIndex !== -1) {
              await deleteBackupTask(context, accountInfo, backupTaskArray[backupTaskIndex].id)
              backupTaskArray.splice(backupTaskIndex, 1)
            }
            let albumName = ''
            let albumUri = ''
            const album = albumArray.find(albumItem => albumItem.id === String(item.get('owner_album_id')))
            if (album) {
              albumName = album.name
              albumUri = album.uri
            }
            if (albumUris.length === 0 || albumUris.includes(albumUri)) {
              const id = util.generateRandomUUID()
              backupTaskArray.push({
                id: id,
                type: type,
                srcFileUri: item.uri,
                modifyTime: item.get('date_modified') as number,
                path: '/home/Photos/backup/' + deviceInfo.marketName + (albumName ? ('/' + albumName) : ''),
                status: 'pending'
              })
              await write(dirPath + id + '.txt', JSON.stringify({
                id: id,
                type: type,
                srcFileUri: item.uri,
                modifyTime: item.get('date_modified') as number,
                path: '/home/Photos/backup/' + deviceInfo.marketName + (albumName ? ('/' + albumName) : ''),
                status: 'pending'
              }))
            }
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
        const path = dir + item
        const stat = fileIo.statSync(path)
        if (!stat.isDirectory() && stat.mtime > latestMotifyTime) {
          const uri = fileUri.getUriFromPath(path)
          const backupTaskIndex = backupTaskArray.findIndex(item => item.srcFileUri === uri)
          if (backupTaskIndex !== -1) {
            await deleteBackupTask(context, accountInfo, backupTaskArray[backupTaskIndex].id)
            backupTaskArray.splice(backupTaskIndex, 1)
          }
          const id = util.generateRandomUUID()
          backupTaskArray.push({
            id: id,
            type: type,
            srcFileUri: uri,
            modifyTime: stat.mtime,
            path: '/home/' + type + '备份/' + deviceInfo.marketName + item.substring(0, item.lastIndexOf('/')),
            status: 'pending'
          })
          await write(dirPath + id + '.txt', JSON.stringify({
            id: id,
            type: type,
            srcFileUri: uri,
            modifyTime: stat.mtime,
            path: '/home/' + type + '备份/' + deviceInfo.marketName + item.substring(0, item.lastIndexOf('/')),
            status: 'pending'
          }))
        }
      }
    }
    for (let i = 0; i < backupTaskArray.length; i++) {
      const item = backupTaskArray[i]
      await startBackupTask(context, item.id)
    }
  }
}

export async function autoBackup(context: Context) {
  const accountInfo = await getAccountInfo(context)
  if (accountInfo.id) {
    const filePath = context.filesDir + '/backupsetting/' + getAccountHash(accountInfo) + '.txt'
    const filestring = await read(filePath, true)
    if (filestring !== 'fail') {
      const backupSetting = JSON.parse(filestring) as BackupSetting
      for (let i = 0; i < backupSetting.autoTypes.length; i++) {
        const item = backupSetting.autoTypes[i]
        await generateBackupTaskList(context, item, backupSetting.albumUris)
      }
    }
  }
}