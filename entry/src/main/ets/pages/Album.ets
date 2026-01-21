import { common, wantAgent } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { display, LoadingDialog, promptAction, SegmentButtonV2Items, TabSegmentButtonV2, window } from '@kit.ArkUI'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { zlib } from '@kit.BasicServicesKit'
import { fileIo, fileUri, picker } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import {
  MovingPhotoView,
  MovingPhotoViewAttribute,
  MovingPhotoViewController,
  photoAccessHelper
} from '@kit.MediaLibraryKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { notificationManager } from '@kit.NotificationKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { getAccountInfo, getLoginStatus } from '../common/Account'
import { getDnsServer } from '../common/Dnsserver'
import { sha256hash } from '../common/Hash'
import { getCurrentNetworkBearerType } from '../common/Network'
import { getPreferType } from '../common/Prefertype'
import { dsmRequest, getDsmApiMaxVersion } from '../common/Request'
import { getSizeString, getTimeString } from '../common/Stringformat'
import Progress from './Progress'

interface Resolution {
  height: number,
  width: number
}

interface PhotoAdditional {
  resolution: Resolution
}

interface PhotoItem {
  id: number,
  filename: string,
  filesize: number,
  time: number,
  folder_id: number,
  url: string,
  path: string,
  resolution: Resolution,
  type: string,
  thumbnailUri: string,
  movingPhoto?: photoAccessHelper.MovingPhoto,
  movingPhotoImageUri?: string,
  movingPhotoVideoUri?: string
}

interface PhotoResItem {
  id: number,
  filename: string,
  filesize: number,
  time: number,
  folder_id: number,
  type: string,
  additional: PhotoAdditional
}

interface TimelineItem {
  date: string,
  count: number
}

interface TimelineResponse {
  section: TimelineSectionItem[]
}

interface TimelineSectionItem {
  offset: number,
  limit: number,
  list: TimelineListItem[]
}

interface TimelineListItem {
  year: number,
  month: number,
  day: number,
  item_count: number
}

interface AlbumItem {
  id: number,
  item_count: number,
  name: string
}

@ComponentV2
export default struct Album {
  @Provider() isShowProgressSheet: boolean = false
  @Provider() transferredSize: number = 0
  @Provider() totalSize: number = 0
  @Local preferType: number = 1
  @Local selectedIndex: number = 0
  @Local loading: boolean = false
  @Local timelineArray: TimelineItem[] = []
  @Local photoArray: PhotoItem[] = []
  @Local albumArray: AlbumItem[] = []
  @Local albumPhotoArray: PhotoItem[] = []
  @Local isLogin: boolean = false
  @Local previewPhoto: PhotoItem | undefined = undefined
  @Local previewAlbum: AlbumItem | undefined = undefined
  @Local isShowInfoSheet: boolean = false
  @Local hoverId: number = -1
  @Local photoItemWidth: number = 0
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  account = ''
  folderMap = new Map<number, string>()
  photoFinished = true
  controller: MovingPhotoViewController = new MovingPhotoViewController()
  backDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'back'
  })
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })
  debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'debugSetting'
  })
  loadingDialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '加载中...'
    })
  })
  deleteDialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '删除中...'
    })
  })

  isPhotoVisiable(photoIndex: number, dateIndex: number) {
    let minIndex = 0
    for (let i = 0; i < dateIndex; i++) {
      minIndex += this.timelineArray[i].count
    }
    return photoIndex >= minIndex && photoIndex < minIndex + this.timelineArray[dateIndex].count
  }

  async pushPhotoIntoPhotoArray(account: string, photoItem: PhotoItem, album: boolean) {
    if (photoItem.type === 'photo') {
      const inPhotoItem = photoItem
      const dir = this.context.cacheDir + '/albumphotothumbnail/' + sha256hash(account)
      let thumbnailPath = dir + '/' + sha256hash(inPhotoItem.path) + '.jpeg'
      if (photoItem.filename.endsWith('.mv.png')) {
        thumbnailPath = dir + '/' + sha256hash(inPhotoItem.path) + '.mp4'
      }
      const thumbnailPathExist = fileIo.accessSync(thumbnailPath)
      if (!thumbnailPathExist) {
        if (!fileIo.accessSync(dir)) {
          await fileIo.mkdir(dir, true)
        }
        if (photoItem.filename.endsWith('.mv.png')) {
          thumbnailPath = dir + '/' + sha256hash(inPhotoItem.path) + '.zip'
        }
        const file = fileIo.openSync(thumbnailPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
        const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
        netBoost.setSceneDesc({
          scene: 'download',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const session = rcp.createSession({
          requestConfiguration: {
            tracing: {
              httpEventsHandler: {
                onDataReceive: async (incomingData) => {
                  await fileStream.write(incomingData)
                },
                onDataEnd: async () => {
                  session.close()
                  netBoost.setSceneDesc({
                    scene: 'download',
                    sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                  })
                  fileStream.closeSync()
                  if (!photoItem.filename.endsWith('.mv.png')) {
                    const imageSource = image.createImageSource(thumbnailPath)
                    const pixelMap = await imageSource.createPixelMap()
                    const imageInfo = pixelMap.getImageInfoSync()
                    let times = 1
                    if (imageInfo.size.width > 300 || imageInfo.size.height > 300) {
                      times = 300 / Math.max(imageInfo.size.width, imageInfo.size.height)
                    }
                    pixelMap.scaleSync(times, times)
                    const file = fileIo.openSync(thumbnailPath, fileIo.OpenMode.WRITE_ONLY)
                    const imagePacker = image.createImagePacker()
                    await imagePacker.packToFile(pixelMap, file.fd, {
                      format: 'image/jpeg',
                      quality: 50
                    })
                    await imagePacker.release()
                    await pixelMap.release()
                    await imageSource.release()
                    fileIo.closeSync(file)
                    inPhotoItem.thumbnailUri = fileUri.getUriFromPath(thumbnailPath)
                    if (!album) {
                      this.photoArray.push(inPhotoItem)
                    }
                    if (album) {
                      this.albumPhotoArray.push(inPhotoItem)
                    }
                  }
                  if (photoItem.filename.endsWith('.mv.png')) {
                    await fileIo.mkdir(dir + '/' + sha256hash(inPhotoItem.path))
                    await zlib.decompressFile(thumbnailPath,
                      dir + '/' + sha256hash(inPhotoItem.path))
                    await fileIo.unlink(thumbnailPath)
                    const movingPhotoFiles =
                      await fileIo.listFile(dir + '/' + sha256hash(inPhotoItem.path))
                    const movingPhotoFilePaths =
                      movingPhotoFiles.map(item => dir + '/' + sha256hash(inPhotoItem.path) + '/' +
                        item)
                    const promises = movingPhotoFilePaths.map(async (item) => {
                      const houzhui = item.substring(item.lastIndexOf('.'))
                      await fileIo.rename(item, dir + '/' + sha256hash(inPhotoItem.path) + '/' +
                      sha256hash(inPhotoItem.path) + houzhui)
                      await fileIo.moveFile(dir + '/' + sha256hash(inPhotoItem.path) + '/' +
                      sha256hash(inPhotoItem.path) + houzhui,
                        dir + '/' + sha256hash(inPhotoItem.path) + houzhui)
                    })
                    await Promise.all(promises)
                    await fileIo.rmdir(dir + '/' + sha256hash(inPhotoItem.path))
                    const imageUri =
                      fileUri.getUriFromPath(dir + '/' + sha256hash(inPhotoItem.path) + '.heic')
                    const videoUri =
                      fileUri.getUriFromPath(dir + '/' + sha256hash(inPhotoItem.path) + '.mp4')
                    inPhotoItem.type = 'movingphoto'
                    inPhotoItem.movingPhotoImageUri = imageUri
                    inPhotoItem.movingPhotoVideoUri = videoUri
                    inPhotoItem.movingPhoto =
                      await photoAccessHelper.MediaAssetManager.loadMovingPhoto(this.context, imageUri, videoUri)
                    if (!album) {
                      this.photoArray.push(inPhotoItem)
                    }
                    if (album) {
                      this.albumPhotoArray.push(inPhotoItem)
                    }
                  }
                }
              }
            },
            dns: {
              dnsRules: getDnsServer(this.context)
            },
            security: {
              remoteValidation: this.debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
                'system') as 'system' | 'skip'
            }
          },
          headers: {
            referer: account.split('\0')[0]
          }
        })
        try {
          const response = await session.get(inPhotoItem.url)
          session.close()
          netBoost.setSceneDesc({
            scene: 'download',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
          })
          if (response.statusCode !== 200) {
            session.close()
            netBoost.setSceneDesc({
              scene: 'download',
              sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
            })
            fileStream.closeSync()
            await promptAction.openToast({
              message: 'HTTP 请求失败，状态码：' + response.statusCode
            })
          }
        } catch (err) {
          session.close()
          netBoost.setSceneDesc({
            scene: 'download',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
          })
          fileStream.closeSync()
          await promptAction.openToast({
            message: '下载失败，错误码：' + err.code
          })
        }
      }
      if (thumbnailPathExist) {
        if (!photoItem.filename.endsWith('.mv.png')) {
          inPhotoItem.thumbnailUri = fileUri.getUriFromPath(thumbnailPath)
          if (!album) {
            this.photoArray.push(inPhotoItem)
          }
          if (album) {
            this.albumPhotoArray.push(inPhotoItem)
          }
        }
        if (photoItem.filename.endsWith('.mv.png')) {
          const imageUri = fileUri.getUriFromPath(dir + '/' + sha256hash(inPhotoItem.path) + '.heic')
          const videoUri = fileUri.getUriFromPath(dir + '/' + sha256hash(inPhotoItem.path) + '.mp4')
          inPhotoItem.type = 'movingphoto'
          inPhotoItem.movingPhotoImageUri = imageUri
          inPhotoItem.movingPhotoVideoUri = videoUri
          inPhotoItem.movingPhoto =
            await photoAccessHelper.MediaAssetManager.loadMovingPhoto(this.context, imageUri, videoUri)
          if (!album) {
            this.photoArray.push(inPhotoItem)
          }
          if (album) {
            this.albumPhotoArray.push(inPhotoItem)
          }
        }
      }
    }
    if (photoItem.type === 'video') {
      if (!album) {
        this.photoArray.push(photoItem)
      }
      if (album) {
        this.albumPhotoArray.push(photoItem)
      }
    }
  }

  async get(refresh: number = 2, notRefreshWhenAccountSame = false) {
    this.isLogin = await getLoginStatus()
    if (!this.isLogin) {
      this.timelineArray = []
      this.photoArray = []
      this.albumPhotoArray = []
      this.account = ''
      this.folderMap.clear()
      this.photoFinished = true
    }
    if (this.isLogin) {
      const accountInfo = await getAccountInfo()
      const account = accountInfo.path + '\0' + accountInfo.name
      if (this.account !== account) {
        this.timelineArray = []
        this.photoArray = []
        this.albumPhotoArray = []
        this.folderMap.clear()
        this.photoFinished = true
      }
      if (this.account === account && notRefreshWhenAccountSame) {
        return
      }
      this.account = account
      if (refresh !== 0) {
        this.albumArray = []
        this.loadingDialogControllerProgress.open()
        const albumres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Album',
          '&method=list&offset=0&limit=5000')
        this.loadingDialogControllerProgress.close()
        if (albumres !== 'fail') {
          this.albumArray = albumres['list']
        }
      }
      if (refresh !== 1) {
        if (!this.photoFinished) {
          return
        }
        this.timelineArray = []
        this.photoArray = []
        this.loadingDialogControllerProgress.open()
        const timelineres =
          await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Timeline', '&method=get')
        this.loadingDialogControllerProgress.close()
        if (timelineres !== 'fail') {
          const timelineSection = timelineres as TimelineResponse
          let timelineList: TimelineListItem[] = []
          timelineSection.section.forEach(item => {
            const list = item.list
            if (list && item.offset === 0) {
              timelineList = timelineList.concat(list)
            }
          })
          timelineList.forEach(item => {
            this.timelineArray.push({
              date: item.year + '-' + String(item.month).padStart(2, '0') + '-' + String(item.day).padStart(2, '0'),
              count: item.item_count
            })
          })
          this.loadingDialogControllerProgress.open()
          const keyres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.API.Auth.Key',
            '&method=grant&allow_api=SYNO.FileStation.Download&allow_methods=["download"]')
          this.loadingDialogControllerProgress.close()
          if (keyres !== 'fail') {
            const tid = keyres['tid'] as string
            const textEncoder = new util.TextEncoder()
            if (getCurrentNetworkBearerType() === 0) {
              const promptAction = this.UIContext.getPromptAction()
              const data = await promptAction.showDialog({
                title: '流量使用提醒',
                message: '当前正在使用流量上网，确定加载？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
              if (data.index === 0) {
                return
              }
            }
            this.photoFinished = false
            let offset = 0
            while (!this.photoFinished) {
              if (this.account !== account) {
                return
              }
              const photores = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Item',
                '&method=list&offset=' + offset + '&limit=5000&additional=["resolution"]')
              if (photores !== 'fail') {
                const photos = photores['list'] as PhotoResItem[]
                if (photos.length === 0) {
                  this.photoFinished = true
                  return
                }
                for (let i = 0; i < photos.length; i++) {
                  const item = photos[i]
                  if (this.account !== account) {
                    return
                  }
                  if (!this.folderMap.has(item.folder_id)) {
                    const folderres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Folder',
                      '&method=get&id=' + item.folder_id)
                    if (folderres !== 'fail') {
                      if (this.account !== account) {
                        return
                      }
                      const folderPath = folderres['folder']['name'] as string
                      const path = '/home/Photos' + folderPath + '/'
                      this.folderMap.set(item.folder_id, path)
                      await this.pushPhotoIntoPhotoArray(account, {
                        id: item.id,
                        filename: item.filename,
                        filesize: item.filesize,
                        time: item.time,
                        folder_id: item.folder_id,
                        url: accountInfo.path + '/fbdownload/' +
                        item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') +
                          '?tid=' + tid + '&mode=open&dlink=' + Array.from(textEncoder.encodeInto(path + item.filename))
                          .map(byte => byte.toString(16).padStart(2, '0')).join(''),
                        path: path + item.filename,
                        resolution: item.additional.resolution,
                        type: item.type,
                        thumbnailUri: ''
                      }, false)
                    }
                  } else {
                    await this.pushPhotoIntoPhotoArray(account, {
                      id: item.id,
                      filename: item.filename,
                      filesize: item.filesize,
                      time: item.time,
                      folder_id: item.folder_id,
                      url: accountInfo.path + '/fbdownload/' +
                      item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') +
                        '?tid=' + tid + '&mode=open&dlink=' +
                      Array.from(textEncoder.encodeInto(this.folderMap.get(item.folder_id) + item.filename))
                        .map(byte => byte.toString(16).padStart(2, '0')).join(''),
                      path: this.folderMap.get(item.folder_id) + item.filename,
                      resolution: item.additional.resolution,
                      type: item.type,
                      thumbnailUri: ''
                    }, false)
                  }
                }
                offset += 5000
              }
              if (photores === 'fail') {
                this.photoFinished = true
              }
            }
          }
        }
      }
    }
  }

  async getAlbumPhoto() {
    this.albumPhotoArray = []
    this.loadingDialogControllerProgress.open()
    const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.API.Auth.Key',
      '&method=grant&allow_api=SYNO.FileStation.Download&allow_methods=["download"]')
    this.loadingDialogControllerProgress.close()
    if (res !== 'fail') {
      const tid = res['tid'] as string
      const accountInfo = await getAccountInfo()
      const account = accountInfo.path + '\0' + accountInfo.name
      const textEncoder = new util.TextEncoder()
      if (getCurrentNetworkBearerType() === 0) {
        const promptAction = this.UIContext.getPromptAction()
        const data = await promptAction.showDialog({
          title: '流量使用提醒',
          message: '当前正在使用流量上网，确定加载？',
          buttons: [
            {
              text: '取消',
              color: $r('sys.color.font_primary')
            },
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
        if (data.index === 0) {
          return
        }
      }
      let finished = false
      let offset = 0
      while (!finished) {
        if (this.account !== account) {
          return
        }
        const photores = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Item',
          '&method=list&offset=' + offset + '&limit=5000&additional=["resolution"]&album_id=' + this.previewAlbum?.id)
        if (photores !== 'fail') {
          const photos = photores['list'] as PhotoResItem[]
          if (photos.length === 0) {
            finished = true
            return
          }
          const photoArray: PhotoItem[] = []
          for (let i = 0; i < photos.length; i++) {
            const item = photos[i]
            if (this.account !== account) {
              return
            }
            if (!this.folderMap.has(item.folder_id)) {
              const folderres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Folder',
                '&method=get&id=' + item.folder_id)
              if (folderres !== 'fail') {
                if (this.account !== account) {
                  return
                }
                const folderPath = folderres['folder']['name'] as string
                const path = '/home/Photos' + folderPath + '/'
                this.folderMap.set(item.folder_id, path)
                await this.pushPhotoIntoPhotoArray(account, {
                  id: item.id,
                  filename: item.filename,
                  filesize: item.filesize,
                  time: item.time,
                  folder_id: item.folder_id,
                  url: accountInfo.path + '/fbdownload/' +
                  item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') +
                    '?tid=' + tid + '&mode=open&dlink=' + Array.from(textEncoder.encodeInto(path + item.filename))
                    .map(byte => byte.toString(16).padStart(2, '0')).join(''),
                  path: path + item.filename,
                  resolution: item.additional.resolution,
                  type: item.type,
                  thumbnailUri: ''
                }, true)
              }
            } else {
              await this.pushPhotoIntoPhotoArray(account, {
                id: item.id,
                filename: item.filename,
                filesize: item.filesize,
                time: item.time,
                folder_id: item.folder_id,
                url: accountInfo.path + '/fbdownload/' +
                item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') +
                  '?tid=' + tid + '&mode=open&dlink=' +
                Array.from(textEncoder.encodeInto(this.folderMap.get(item.folder_id) + item.filename))
                  .map(byte => byte.toString(16).padStart(2, '0')).join(''),
                path: this.folderMap.get(item.folder_id) + item.filename,
                resolution: item.additional.resolution,
                type: item.type,
                thumbnailUri: ''
              }, true)
            }
          }
          offset += 5000
        }
        if (photores === 'fail') {
          finished = true
        }
      }
    }
  }

  @Builder
  InfoSheetBuilder() {
    List() {
      ListItem() {
        if (this.previewPhoto) {
          Column() {
            Text() {
              Span('名称：')
                .fontWeight(FontWeight.Medium)
              Span(this.previewPhoto.filename)
            }

            Text() {
              Span('时间：')
                .fontWeight(FontWeight.Medium)
              Span(getTimeString(this.previewPhoto.time))
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            Text() {
              Span('大小：')
                .fontWeight(FontWeight.Medium)
              Span(getSizeString(this.previewPhoto.filesize))
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            if (this.previewPhoto.type !== 'movingphoto') {
              Text() {
                Span('尺寸：')
                  .fontWeight(FontWeight.Medium)
                Span(this.previewPhoto.resolution.width + 'x' + this.previewPhoto.resolution.height)
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            Text() {
              Span('路径：')
                .fontWeight(FontWeight.Medium)
              Span(this.previewPhoto.path)
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .padding({
            bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
            left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
            right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
          })
          .width('100%')
        }
      }
    }
  }

  @Builder
  ProgressSheetBuilder() {
    Progress()
  }

  @Builder
  MenuBuilder(item: PhotoItem) {
    Menu() {
      MenuItem({
        content: '详情'
      })
        .onClick(() => {
          this.isShowInfoSheet = true
        })
      if (item.type !== 'movingphoto') {
        MenuItem({
          content: '下载'
        })
          .onClick(async () => {
            if (item.type === 'photo') {
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '下载中...'
                })
              })
              dialogControllerProgress.open()
              const version = await getDsmApiMaxVersion(this.context, '', 'SYNO.FileStation.Download')
              if (version !== 'fail') {
                const dir = this.context.tempDir + '/downloadphoto'
                if (!fileIo.accessSync(dir)) {
                  await fileIo.mkdir(dir, true)
                }
                const path = dir + '/' + item.filename
                const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
                netBoost.setSceneDesc({
                  scene: 'download',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                })
                const accountInfo = await getAccountInfo()
                const session = rcp.createSession({
                  requestConfiguration: {
                    tracing: {
                      httpEventsHandler: {
                        onDataReceive: async (incomingData) => {
                          await fileStream.write(incomingData)
                        },
                        onDataEnd: async () => {
                          session.close()
                          netBoost.setSceneDesc({
                            scene: 'download',
                            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                          })
                          fileStream.closeSync()
                          const uri = fileUri.getUriFromPath(path)
                          let houzhui = ''
                          const lastDotIndex = item.filename.lastIndexOf('.')
                          if (lastDotIndex !== -1) {
                            houzhui = item.filename.slice(lastDotIndex + 1)
                          }
                          const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
                          const uris = await phAccessHelper.showAssetsCreationDialog([uri], [{
                            fileNameExtension: houzhui,
                            photoType: photoAccessHelper.PhotoType.IMAGE
                          }])
                          if (uris.length === 1) {
                            const srcFile = fileIo.openSync(uri)
                            const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                            await fileIo.copyFile(srcFile.fd, destFile.fd)
                            fileIo.closeSync(srcFile)
                            fileIo.closeSync(destFile)
                            await fileIo.unlink(path)
                            await promptAction.openToast({
                              message: '保存成功'
                            })
                          }
                        }
                      }
                    },
                    dns: {
                      dnsRules: getDnsServer(this.context)
                    },
                    security: {
                      remoteValidation: this.debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
                        'system') as 'system' | 'skip'
                    }
                  },
                  headers: {
                    'accept-language': 'zh-CN',
                    referer: accountInfo.path
                  },
                  cookies: {
                    id: accountInfo.sid
                  }
                })
                try {
                  const response =
                    await session.get(accountInfo.path + '/webapi/entry.cgi?api=SYNO.FileStation.Download&version=' +
                      version + '&method=download&mode=download&path=' + encodeURIComponent(item.path))
                  dialogControllerProgress.close()
                  session.close()
                  netBoost.setSceneDesc({
                    scene: 'download',
                    sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                  })
                  if (response.statusCode !== 200) {
                    session.close()
                    netBoost.setSceneDesc({
                      scene: 'download',
                      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                    })
                    fileStream.closeSync()
                    await promptAction.openToast({
                      message: 'HTTP 请求失败，状态码：' + response.statusCode
                    })
                  }
                } catch (err) {
                  dialogControllerProgress.close()
                  session.close()
                  netBoost.setSceneDesc({
                    scene: 'download',
                    sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                  })
                  fileStream.closeSync()
                  await promptAction.openToast({
                    message: '下载失败，错误码：' + err.code
                  })
                }
                return
              }
              dialogControllerProgress.close()
            }
            if (item.type === 'video') {
              if (getCurrentNetworkBearerType() === 0) {
                const cellularDataUseRemind = this.commonSettingDataPreferences.getSync('cellularDataUseRemind', 0)
                if (cellularDataUseRemind === 0 ||
                  (cellularDataUseRemind === 1 && item.filesize > 200 * Math.pow(1024, 2))) {
                  const promptAction = this.UIContext.getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '流量使用提醒',
                    message: '当前正在使用流量上网，下载此视频将消耗约 ' + getSizeString(item.filesize) +
                      ' 流量，确定下载？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                  if (data.index === 0) {
                    return
                  }
                }
              }
              try {
                const documentSaveOptions = new picker.DocumentSaveOptions()
                const selectFileDownloadPath =
                  this.commonSettingDataPreferences.getSync('selectFileDownloadPath', false)
                if (!selectFileDownloadPath) {
                  documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD
                }
                if (selectFileDownloadPath) {
                  const lastDotIndex = item.filename.lastIndexOf('.')
                  if (lastDotIndex !== -1) {
                    documentSaveOptions.newFileNames = [item.filename.substring(0, lastDotIndex)]
                    documentSaveOptions.fileSuffixChoices = ['.' + item.filename.substring(lastDotIndex + 1)]
                  }
                  if (lastDotIndex === -1) {
                    documentSaveOptions.newFileNames = [item.filename]
                    documentSaveOptions.fileSuffixChoices = ['']
                  }
                }
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                if (uris.length === 1) {
                  let filePath = ''
                  if (!selectFileDownloadPath) {
                    filePath = new fileUri.FileUri(uris[0] + '/' + item.filename).path
                  }
                  if (selectFileDownloadPath) {
                    filePath = uris[0]
                  }
                  const prepareDownloadDialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '下载准备中...'
                    })
                  })
                  prepareDownloadDialogControllerProgress.open()
                  const version = await getDsmApiMaxVersion(this.context, '', 'SYNO.FileStation.Download')
                  prepareDownloadDialogControllerProgress.close()
                  if (version !== 'fail') {
                    const wandAgent = await wantAgent.getWantAgent({
                      wants: [
                        {
                          bundleName: 'com.songjy.synologydsmhelper',
                          abilityName: 'EntryAbility'
                        }
                      ],
                      actionType: wantAgent.OperationType.START_ABILITY,
                      requestCode: 0,
                      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
                    })
                    const continuousTaskNotificationInfo =
                      await backgroundTaskManager.startBackgroundRunning(this.context, ['dataTransfer'], wandAgent)
                    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                    const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
                    netBoost.setSceneDesc({
                      scene: 'download',
                      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                    })
                    const accountInfo = await getAccountInfo()
                    const session = rcp.createSession({
                      requestConfiguration: {
                        transfer: {
                          timeout: {
                            transferMs: 0
                          }
                        },
                        tracing: {
                          httpEventsHandler: {
                            onDataReceive: async (incomingData) => {
                              await fileStream.write(incomingData)
                              this.transferredSize = this.transferredSize + incomingData.byteLength
                              try {
                                await notificationManager.publish({
                                  content: {
                                    notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                                    systemLiveView: {
                                      typeCode: 8,
                                      title: '正在下载文件：' + item.filename,
                                      text: '进度：' + Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 +
                                        '% (' + getSizeString(this.transferredSize) + '/' +
                                      getSizeString(this.totalSize) + ')'
                                    }
                                  },
                                  id: continuousTaskNotificationInfo.notificationId,
                                  notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                                  template: {
                                    name: 'downloadTemplate',
                                    data: {
                                      title: '正在下载文件，进度：' +
                                        Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 + '%',
                                      fileName: item.filename,
                                      progressValue: Number((this.transferredSize / this.totalSize).toFixed(2)) * 100
                                    }
                                  }
                                })
                              } catch {
                              }
                            },
                            onDataEnd: async () => {
                              session.close()
                              netBoost.setSceneDesc({
                                scene: 'download',
                                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                              })
                              fileStream.closeSync()
                              await backgroundTaskManager.stopBackgroundRunning(this.context)
                              this.isShowProgressSheet = false
                              this.context.eventHub.off('cancelDownload')
                              if (this.transferredSize < item.filesize - 1) {
                                this.transferredSize = 0
                                this.totalSize = 0
                                await promptAction.openToast({
                                  message: '下载失败'
                                })
                              }
                              if (this.transferredSize >= item.filesize - 1) {
                                this.transferredSize = 0
                                this.totalSize = 0
                                await promptAction.openToast({
                                  message: '下载成功'
                                })
                              }
                            }
                          }
                        },
                        dns: {
                          dnsRules: getDnsServer(this.context)
                        },
                        security: {
                          remoteValidation: this.debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
                            'system') as 'system' | 'skip'
                        }
                      },
                      headers: {
                        'accept-language': 'zh-CN',
                        referer: accountInfo.path
                      },
                      cookies: {
                        id: accountInfo.sid
                      }
                    })
                    backgroundTaskManager.on('continuousTaskCancel', async () => {
                      session.cancel()
                      await promptAction.openToast({
                        message: '下载失败'
                      })
                    })
                    this.context.eventHub.on('cancelDownload', () => {
                      session.cancel()
                    })
                    this.totalSize = item.filesize
                    this.isShowProgressSheet = true
                    try {
                      const response = await session.get(accountInfo.path +
                        '/webapi/entry.cgi?api=SYNO.FileStation.Download&version=' +
                        version + '&method=download&mode=download&path=' + encodeURIComponent(item.path))
                      if (response.statusCode !== 200) {
                        session.close()
                        netBoost.setSceneDesc({
                          scene: 'download',
                          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                        })
                        fileStream.closeSync()
                        await backgroundTaskManager.stopBackgroundRunning(this.context)
                        this.isShowProgressSheet = false
                        this.transferredSize = 0
                        this.totalSize = 0
                        this.context.eventHub.off('cancelDownload')
                        await promptAction.openToast({
                          message: 'HTTP 请求失败，状态码：' + response.statusCode
                        })
                      }
                    } catch (err) {
                      session.close()
                      netBoost.setSceneDesc({
                        scene: 'download',
                        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                      })
                      fileStream.closeSync()
                      try {
                        await backgroundTaskManager.stopBackgroundRunning(this.context)
                      } catch {
                      }
                      this.isShowProgressSheet = false
                      this.transferredSize = 0
                      this.totalSize = 0
                      this.context.eventHub.off('cancelDownload')
                      if (err.code !== 1007900992) {
                        await promptAction.openToast({
                          message: '下载失败，错误码：' + err.code
                        })
                      }
                    }
                  }
                }
              } catch (err) {
                await promptAction.openToast({
                  message: '发生错误，错误码：' + err.code
                })
              }
            }
          })
      }
      MenuItem({
        content: '删除'
      })
        .contentFontColor($r('sys.color.warning'))
        .onClick(async () => {
          const promptAction = this.UIContext.getPromptAction()
          const data = await promptAction.showDialog({
            title: '提示',
            message: '删除成功后无法恢复，确定删除？',
            buttons: [
              {
                text: '取消',
                color: $r('sys.color.font_primary')
              },
              {
                text: '删除',
                color: $r('sys.color.warning')
              }
            ]
          })
          if (data.index === 1) {
            this.deleteDialogControllerProgress.open()
            const startres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.Delete',
              '&method=start&path=' + encodeURIComponent(item.path))
            if (startres !== 'fail') {
              const taskId = startres['taskid'] as string
              let finished = false
              while (!finished) {
                const statusres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.Delete',
                  '&method=status&taskid=' + taskId)
                if (statusres !== 'fail') {
                  if (statusres['finished']) {
                    finished = true
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                    this.previewPhoto = undefined
                    this.backDataPreferences.putSync('album', false)
                    await this.get()
                    if (this.previewAlbum) {
                      await this.getAlbumPhoto()
                    }
                  }
                }
                if (statusres === 'fail') {
                  finished = true
                }
              }
            }
            this.deleteDialogControllerProgress.close()
          }
        })
    }
  }

  build() {
    Scroll() {
      Column() {
        if (!this.isLogin) {
          Text('未登录账号')
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        if (this.isLogin) {
          if (!this.previewPhoto && !this.previewAlbum) {
            TabSegmentButtonV2({
              items: new SegmentButtonV2Items([
                { text: '照片' },
                { text: '相册' }
              ]),
              selectedIndex: this.selectedIndex!!
            })
              .margin({
                bottom: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
            Refresh({
              refreshing: $$this.loading
            }) {
              Column() {
                if (this.selectedIndex === 0) {
                  List() {
                    ListItem() {
                      Text(this.photoArray.filter(item => item.type === 'photo').length + '张照片和' +
                      this.photoArray.filter(item => item.type === 'video').length + '个视频')
                        .enableAutoSpacing(true)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    }
                    .width('100%')

                    Repeat<TimelineItem>(this.timelineArray)
                      .each((timelineItem: RepeatItem<TimelineItem>) => {
                        ListItemGroup() {
                          ListItem() {
                            Text(timelineItem.item.date)
                          }

                          ListItem() {
                            List() {
                              Repeat<PhotoItem>(this.photoArray.filter((photoItem,
                                photoIndex): boolean => this.isPhotoVisiable(photoIndex, timelineItem.index)))
                                .each((photoItem: RepeatItem<PhotoItem>) => {
                                  ListItem() {
                                    Column() {
                                      if (photoItem.item.type === 'photo') {
                                        Image(photoItem.item.url)
                                          .alt($r('app.media.imageloading'))
                                          .aspectRatio(1)
                                          .autoResize(true)
                                          .copyOption(CopyOptions.LocalDevice)
                                          .objectFit(ImageFit.Auto)
                                          .onError(async (err) => {
                                            await promptAction.openToast({
                                              message: '发生错误，错误信息：' + err.message
                                            })
                                          })
                                          .onClick(() => {
                                            this.previewPhoto = photoItem.item
                                            this.backDataPreferences.putSync('album', true)
                                          })
                                      }
                                      if (photoItem.item.type === 'movingphoto') {
                                        MovingPhotoView({
                                          movingPhoto: photoItem.item.movingPhoto,
                                          controller: this.controller,
                                          imageAIOptions: {
                                            types: [ImageAnalyzerType.SUBJECT, ImageAnalyzerType.TEXT,
                                              ImageAnalyzerType.OBJECT_LOOKUP]
                                          }
                                        })
                                          .aspectRatio(1)
                                          .muted(true)
                                          .objectFit(ImageFit.Auto)
                                          .onError(async () => {
                                            await promptAction.openToast({
                                              message: '加载动态照片时发生错误'
                                            })
                                          })
                                          .onClick(() => {
                                            this.previewPhoto = photoItem.item
                                            this.backDataPreferences.putSync('album', true)
                                          })
                                      }
                                      if (photoItem.item.type === 'video') {
                                        Video({
                                          src: photoItem.item.url,
                                          posterOptions: {
                                            showFirstFrame: true
                                          }
                                        })
                                          .aspectRatio(1)
                                          .enabled(false)
                                          .objectFit(ImageFit.Auto)
                                          .onError(async (err) => {
                                            await promptAction.openToast({
                                              message: '发生错误，错误码：' + err.code
                                            })
                                          })
                                      }
                                    }
                                    .onClick(() => {
                                      this.previewPhoto = photoItem.item
                                      this.backDataPreferences.putSync('album', true)
                                    })
                                  }
                                })
                                .virtualScroll()
                            }
                            .height(Math.ceil(this.photoArray.filter((photoItem,
                              photoIndex): boolean => this.isPhotoVisiable(photoIndex, timelineItem.index)).length /
                              4) * this.photoItemWidth)
                            .lanes(4)
                            .margin({
                              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                            })
                          }
                        }
                        .margin({
                          top: timelineItem.index !== 0 ? $r('sys.float.ohos_id_elements_margin_vertical_m') : 0
                        })
                      })
                      .virtualScroll()
                  }
                  .height('100%')
                }
                if (this.selectedIndex === 1) {
                  if (this.albumArray.length === 0) {
                    Text('无数据')
                  }
                  Column() {
                    ForEach(this.albumArray, (albumItem: AlbumItem, albumIndex) => {
                      if (albumIndex !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(albumItem.name)
                          .fontWeight(FontWeight.Medium)
                          .layoutWeight(1)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                        Text(String(albumItem.item_count))
                          .fontColor($r('sys.color.font_secondary'))
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                          })
                        Image($r('app.media.right'))
                          .fillColor($r('sys.color.icon_fourth'))
                          .height(12)
                          .width(12)
                      }
                      .borderRadius(12)
                      .padding(12)
                      .stateStyles({
                        normal: {
                          .backgroundColor(this.hoverId === albumIndex ? $r('sys.color.interactive_hover') :
                            $r('sys.color.comp_background_primary'))
                        },
                        pressed: {
                          .backgroundColor($r('sys.color.comp_background_secondary'))
                        }
                      })
                      .width('100%')
                      .onHover((isHover) => {
                        if (!isHover) {
                          this.hoverId = -1
                        }
                        if (isHover) {
                          this.hoverId = albumIndex
                        }
                      })
                      .onClick(async () => {
                        this.previewAlbum = albumItem
                        this.backDataPreferences.putSync('album', true)
                        await this.getAlbumPhoto()
                      })
                    })
                  }
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .padding($r('sys.float.ohos_id_corner_radius_mark'))
                }
              }
            }
            .layoutWeight(1)
            .width('100%')
            .onRefreshing(async () => {
              await this.get(this.selectedIndex)
              this.loading = false
            })
          }
          if (this.previewPhoto) {
            Column() {
              Row() {
                Column() {
                  Image($r('app.media.back'))
                }
                .borderRadius(20)
                .height(40)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .padding(11)
                .stateStyles({
                  normal: {
                    .backgroundColor($r('sys.color.interactive_hover'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .onClick(() => {
                  this.previewPhoto = undefined
                  this.backDataPreferences.putSync('album', false)
                })

                Text(this.previewPhoto.filename)
                  .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .maxLines(1)
                  .textOverflow({
                    overflow: TextOverflow.Ellipsis
                  })
                Column() {
                  Image($r('app.media.menu'))
                }
                .borderRadius(20)
                .height(40)
                .padding(11)
                .stateStyles({
                  normal: {
                    .backgroundColor($r('sys.color.interactive_hover'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .bindMenu(this.MenuBuilder(this.previewPhoto))
              }

              if (this.previewPhoto.type === 'photo') {
                Image(this.previewPhoto.url)
                  .alt($r('app.media.imageloading'))
                  .copyOption(CopyOptions.LocalDevice)
                  .enableAnalyzer(true)
                  .layoutWeight(1)
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                  })
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .gesture(
                    PanGesture({
                      direction: PanDirection.Left | PanDirection.Right
                    })
                      .onActionEnd(async (gestureEvent) => {
                        let photoArray: PhotoItem[] = []
                        if (!this.previewAlbum) {
                          photoArray = this.photoArray
                        }
                        if (this.previewAlbum) {
                          photoArray = this.albumPhotoArray
                        }
                        const index = photoArray.findIndex(item => item.id === this.previewPhoto?.id)
                        const maxIndex = photoArray.length - 1
                        if (gestureEvent.offsetX > 0) {
                          if (index !== 0) {
                            this.previewPhoto = photoArray[index - 1]
                            this.backDataPreferences.putSync('album', true)
                          }
                          if (index === 0) {
                            await promptAction.openToast({
                              message: '已是第一张'
                            })
                          }
                        }
                        if (gestureEvent.offsetX < 0) {
                          if (index !== maxIndex) {
                            this.previewPhoto = photoArray[index + 1]
                            this.backDataPreferences.putSync('album', true)
                          }
                          if (index === maxIndex) {
                            await promptAction.openToast({
                              message: '已是最后一张'
                            })
                          }
                        }
                      })
                  )
              }
              if (this.previewPhoto.type === 'movingphoto') {
                MovingPhotoView({
                  movingPhoto: this.previewPhoto.movingPhoto,
                  controller: this.controller,
                  imageAIOptions: {
                    types: [ImageAnalyzerType.SUBJECT, ImageAnalyzerType.TEXT, ImageAnalyzerType.OBJECT_LOOKUP]
                  }
                })
                  .autoPlay(true)
                  .layoutWeight(1)
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
                  .objectFit(ImageFit.Contain)
                  .width('100%')
                  .onError(async () => {
                    await promptAction.openToast({
                      message: '加载动态照片时发生错误'
                    })
                  })
                  .onClick(() => {
                    this.controller.startPlayback()
                  })
                  .gesture(
                    PanGesture({
                      direction: PanDirection.Left | PanDirection.Right
                    })
                      .onActionEnd(async (gestureEvent) => {
                        let photoArray: PhotoItem[] = []
                        if (!this.previewAlbum) {
                          photoArray = this.photoArray
                        }
                        if (this.previewAlbum) {
                          photoArray = this.albumPhotoArray
                        }
                        const index = photoArray.findIndex(item => item.id === this.previewPhoto?.id)
                        const maxIndex = photoArray.length - 1
                        if (gestureEvent.offsetX > 0) {
                          if (index !== 0) {
                            this.previewPhoto = photoArray[index - 1]
                            this.backDataPreferences.putSync('album', true)
                          }
                          if (index === 0) {
                            await promptAction.openToast({
                              message: '已是第一张'
                            })
                          }
                        }
                        if (gestureEvent.offsetX < 0) {
                          if (index !== maxIndex) {
                            this.previewPhoto = photoArray[index + 1]
                            this.backDataPreferences.putSync('album', true)
                          }
                          if (index === maxIndex) {
                            await promptAction.openToast({
                              message: '已是最后一张'
                            })
                          }
                        }
                      })
                  )
                Column() {
                  SaveButton({
                    icon: SaveIconStyle.FULL_FILLED,
                    text: SaveDescription.SAVE
                  })
                    .onClick(async (event, result) => {
                      if (result === SaveButtonOnClickResult.SUCCESS) {
                        const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
                        const assetChangeRequest =
                          photoAccessHelper.MediaAssetChangeRequest.createAssetRequest(this.context,
                            photoAccessHelper.PhotoType.IMAGE, 'heif', {
                              subtype: photoAccessHelper.PhotoSubtype.MOVING_PHOTO
                            })
                        assetChangeRequest.addResource(photoAccessHelper.ResourceType.IMAGE_RESOURCE,
                          this.previewPhoto?.movingPhotoImageUri)
                        assetChangeRequest.addResource(photoAccessHelper.ResourceType.VIDEO_RESOURCE,
                          this.previewPhoto?.movingPhotoVideoUri)
                        await phAccessHelper.applyChanges(assetChangeRequest)
                        await promptAction.openToast({
                          message: '保存成功'
                        })
                      }
                    })
                }
                .margin({
                  bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .width('100%')
              }
              if (this.previewPhoto.type === 'video') {
                Video({
                  src: this.previewPhoto.url,
                  posterOptions: {
                    showFirstFrame: true
                  }
                })
                  .analyzerConfig({
                    types: [ImageAnalyzerType.SUBJECT, ImageAnalyzerType.SUBJECT, ImageAnalyzerType.OBJECT_LOOKUP]
                  })
                  .autoPlay(true)
                  .enableAnalyzer(true)
                  .enableShortcutKey(true)
                  .layoutWeight(1)
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                  })
                  .objectFit(ImageFit.Auto)
                  .onError(async (err) => {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  })
                  .bindSheet(this.isShowProgressSheet!!, this.ProgressSheetBuilder(), {
                    height: SheetSize.FIT_CONTENT,
                    preferType: this.preferType,
                    showClose: false,
                    onWillDismiss: () => {
                    },
                    onDisappear: () => {
                      this.context.eventHub.emit('cancelDownload')
                    }
                  })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              title: {
                title: '详情'
              }
            })
          }
          if (this.previewAlbum) {
            List() {
              ListItem() {
                Row() {
                  Column() {
                    Image($r('app.media.back'))
                  }
                  .borderRadius(20)
                  .height(40)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .padding(11)
                  .stateStyles({
                    normal: {
                      .backgroundColor($r('sys.color.interactive_hover'))
                    },
                    pressed: {
                      .backgroundColor($r('sys.color.interactive_pressed'))
                    }
                  })
                  .visualEffect(new hdsEffect.HdsEffectBuilder()
                    .pointLight({
                      sourceType: hdsEffect.PointLightSourceType.SOFT,
                      illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                    })
                    .buildEffect())
                  .width(40)
                  .onClick(() => {
                    this.previewAlbum = undefined
                    this.backDataPreferences.putSync('album', false)
                  })

                  Text(this.previewAlbum.name)
                    .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                    .fontWeight(FontWeight.Bold)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({
                      overflow: TextOverflow.Ellipsis
                    })
                }
              }
              .margin({
                bottom: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })

              if (this.albumPhotoArray.length === 0) {
                ListItem() {
                  Text('无数据')
                }
                .width('100%')
              }
              ListItem() {
                List() {
                  Repeat<PhotoItem>(this.albumPhotoArray)
                    .each((photoItem: RepeatItem<PhotoItem>) => {
                      ListItem() {
                        Column() {
                          if (photoItem.item.type === 'photo') {
                            Image(photoItem.item.url)
                              .alt($r('app.media.imageloading'))
                              .aspectRatio(1)
                              .autoResize(true)
                              .copyOption(CopyOptions.LocalDevice)
                              .objectFit(ImageFit.Auto)
                              .onError(async (err) => {
                                await promptAction.openToast({
                                  message: '发生错误，错误信息：' + err.message
                                })
                              })
                              .onClick(() => {
                                this.previewPhoto = photoItem.item
                                this.backDataPreferences.putSync('album', true)
                              })
                          }
                          if (photoItem.item.type === 'movingphoto') {
                            MovingPhotoView({
                              movingPhoto: photoItem.item.movingPhoto,
                              controller: this.controller,
                              imageAIOptions: {
                                types: [ImageAnalyzerType.SUBJECT, ImageAnalyzerType.TEXT,
                                  ImageAnalyzerType.OBJECT_LOOKUP]
                              }
                            })
                              .aspectRatio(1)
                              .muted(true)
                              .objectFit(ImageFit.Auto)
                              .onError(async () => {
                                await promptAction.openToast({
                                  message: '加载动态照片时发生错误'
                                })
                              })
                              .onClick(() => {
                                this.previewPhoto = photoItem.item
                                this.backDataPreferences.putSync('album', true)
                              })
                          }
                          if (photoItem.item.type === 'video') {
                            Video({
                              src: photoItem.item.url,
                              posterOptions: {
                                showFirstFrame: true
                              }
                            })
                              .aspectRatio(1)
                              .enabled(false)
                              .objectFit(ImageFit.Auto)
                              .onError(async (err) => {
                                await promptAction.openToast({
                                  message: '发生错误，错误码：' + err.code
                                })
                              })
                          }
                        }
                        .onClick(() => {
                          this.previewPhoto = photoItem.item
                          this.backDataPreferences.putSync('album', true)
                        })
                      }
                    })
                    .virtualScroll()
                }
                .height('100%')
                .lanes(4)
              }
              .layoutWeight(1)
            }
            .edgeEffect(EdgeEffect.None)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      const lastWindow = await window.getLastWindow(this.context)
      this.photoItemWidth = (this.UIContext.px2vp(lastWindow.getWindowProperties().windowRect.width) - 32) / 4
      lastWindow.on('windowSizeChange', (size) => {
        this.photoItemWidth = (this.UIContext.px2vp(size.width) - 32) / 4
      })
      this.context.eventHub.on('backAlbum', () => {
        if (this.previewPhoto && !this.previewAlbum) {
          this.previewPhoto = undefined
          this.backDataPreferences.putSync('album', false)
        }
        if (this.previewPhoto && this.previewAlbum) {
          this.previewPhoto = undefined
          return
        }
        if (this.previewAlbum) {
          this.previewAlbum = undefined
          this.backDataPreferences.putSync('album', false)
        }
      })
      this.context.eventHub.on('refreshAlbum', async () => {
        this.previewPhoto = undefined
        this.previewAlbum = undefined
        this.backDataPreferences.putSync('album', false)
        await this.get(2, true)
      })
      await this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshAlbum')
      this.context.eventHub.off('backAlbum')
      display.off('change')
    })
  }
}