import { common } from '@kit.AbilityKit'
import { dataSharePredicates, sendablePreferences } from '@kit.ArkData'
import { taskpool, url, util } from '@kit.ArkTS'
import {
  display,
  LoadingDialog,
  promptAction,
  SegmentButtonV2Items,
  TabSegmentButtonV2,
  uiMaterial,
  window
} from '@kit.ArkUI'
import { fileIo, fileUri, picker } from '@kit.CoreFileKit'
import { map, mapCommon, MapComponent, petalMaps, site } from '@kit.MapKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getAccountHash, getAccountInfo, getLoginStatus } from '../common/Account'
import { getDnsServer } from '../common/Dnsserver'
import { getCurrentNetworkBearerType } from '../common/Network'
import { checkPermission } from '../common/Permission'
import { getFlushPreference, setTempPreference } from '../common/Preference'
import { getPreferType } from '../common/Prefertype'
import { pushPhotoIntoPhotoArray } from '../common/Pushphoto'
import { dsmRequest, getDsmApiMaxVersion } from '../common/Request'
import { getSizeString, getTimeStringFromSecond } from '../common/Stringformat'
import Addphotointoalbum from './Addphotointoalbum'
import Progress from './Progress'
import Renamealbum from './Renamealbum'

interface Resolution {
  height: number,
  width: number
}

export interface PhotoThumbnail {
  sm: string,
  cache_key: string
}

interface PhotoExif {
  aperture: string,
  camera: string,
  exposure_time: string,
  focal_length: string,
  iso: string
}

interface PhotoGps {
  latitude: number,
  longitude: number
}

interface PhotoAdditional {
  resolution: Resolution,
  thumbnail: PhotoThumbnail,
  exif: PhotoExif,
  gps: PhotoGps
}

export interface PhotoItem {
  id: number,
  filename: string,
  filesize: number,
  time: number,
  folder_id: number,
  url: string,
  path: string,
  additional: PhotoAdditional,
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

export interface AlbumItem {
  id: number,
  item_count: number,
  name: string
}

@ComponentV2
export default struct Album {
  @Provider() isShowAddphotointoalbumSheet: boolean = false
  @Provider() isShowRenamealbumSheet: boolean = false
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
  @Local buttonHoverId: number = -1
  @Local photoItemWidth: number = 0
  @Local photoAddress: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  folderMap = new Map<number, string>()
  account = ''
  photoFinished = true
  editId = -1
  editName = ''
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  isPhotoVisiable(photoIndex: number, dateIndex: number) {
    let minIndex = 0
    for (let i = 0; i < dateIndex; i++) {
      minIndex += this.timelineArray[i].count
    }
    return photoIndex >= minIndex && photoIndex < minIndex + this.timelineArray[dateIndex].count
  }

  async get(refresh: number = 2, notRefreshWhenAccountSame = false) {
    this.isLogin = await getLoginStatus(this.context)
    if (!this.isLogin) {
      this.timelineArray = []
      this.photoArray = []
      this.albumPhotoArray = []
      this.account = ''
      this.folderMap.clear()
      this.photoFinished = true
    }
    if (this.isLogin) {
      if (refresh !== 0) {
        this.albumArray = []
        this.dialogControllerProgress.open()
        const albumres = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.Album', new url.URLParams({
          method: 'list',
          offset: '0',
          limit: '5000'
        }).toString())
        this.dialogControllerProgress.close()
        if (albumres !== 'fail') {
          this.albumArray = albumres['list']
        }
      }
      const accountInfo = await getAccountInfo(this.context)
      const account = getAccountHash(accountInfo)
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
      if (refresh !== 1) {
        if (!this.photoFinished) {
          return
        }
        this.timelineArray = []
        this.photoArray = []
        this.dialogControllerProgress.open()
        const timelineres = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.Timeline', new url.URLParams({
          method: 'get'
        }).toString())
        this.dialogControllerProgress.close()
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
              date: item.year + '年' + item.month + '月' + item.day + '日',
              count: item.item_count
            })
          })
          this.dialogControllerProgress.open()
          const keyres = await dsmRequest(this.context, '', 'SYNO.API.Auth.Key', new url.URLParams({
            method: 'grant',
            allow_api: 'SYNO.FileStation.Download',
            allow_methods: JSON.stringify(['download'])
          }).toString())
          this.dialogControllerProgress.close()
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
              const photores = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.Item', new url.URLParams({
                method: 'list',
                offset: String(offset),
                limit: '5000',
                additional: JSON.stringify(['exif', 'gps', 'resolution', 'thumbnail'])
              }).toString())
              if (photores !== 'fail') {
                const photos = photores['list'] as PhotoResItem[]
                if (photos.length === 0) {
                  this.photoFinished = true
                  return
                }
                for (let i = 0; i < photos.length; i++) {
                  const item = photos[i]
                  if (!this.folderMap.has(item.folder_id)) {
                    if (this.account !== account) {
                      return
                    }
                    const folderres = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.Folder', new url.URLParams({
                      method: 'get',
                      id: String(item.folder_id)
                    }).toString())
                    if (folderres !== 'fail') {
                      const folderPath = folderres['folder']['name'] as string
                      let path = '/home/Photos' + folderPath
                      if (folderPath !== '/') {
                        path += '/'
                      }
                      this.folderMap.set(item.folder_id, path)
                      if (this.account !== account) {
                        return
                      }
                      const task = new taskpool.Task(pushPhotoIntoPhotoArray, this.context, accountInfo, {
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
                        additional: item.additional,
                        type: item.type,
                        thumbnailUri: ''
                      } as PhotoItem, item.additional.thumbnail)
                      const res = await taskpool.execute(task)
                      if (this.account !== account) {
                        return
                      }
                      this.photoArray.push(res as PhotoItem)
                    }
                  } else {
                    if (this.account !== account) {
                      return
                    }
                    const task = new taskpool.Task(pushPhotoIntoPhotoArray, this.context, accountInfo, {
                      id: item.id,
                      filename: item.filename,
                      filesize: item.filesize,
                      time: item.time,
                      folder_id: item.folder_id,
                      url: accountInfo.path + '/fbdownload/' +
                        item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') + '?tid=' + tid +
                        '&mode=open&dlink=' +
                        Array.from(textEncoder.encodeInto(this.folderMap.get(item.folder_id) + item.filename))
                          .map(byte => byte.toString(16).padStart(2, '0')).join(''),
                      path: this.folderMap.get(item.folder_id) + item.filename,
                      additional: item.additional,
                      type: item.type,
                      thumbnailUri: ''
                    } as PhotoItem, item.additional.thumbnail)
                    const res = await taskpool.execute(task)
                    if (this.account !== account) {
                      return
                    }
                    this.photoArray.push(res as PhotoItem)
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
    this.dialogControllerProgress.open()
    const res = await dsmRequest(this.context, '', 'SYNO.API.Auth.Key', new url.URLParams({
      method: 'grant',
      allow_api: 'SYNO.FileStation.Download',
      allow_methods: JSON.stringify(['download'])
    }).toString())
    this.dialogControllerProgress.close()
    if (res !== 'fail') {
      const tid = res['tid'] as string
      const accountInfo = await getAccountInfo(this.context)
      const account = getAccountHash(accountInfo)
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
      const albumId = this.previewAlbum?.id
      while (!finished) {
        if (this.account !== account || this.previewAlbum?.id !== albumId) {
          return
        }
        const photores = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.Item', new url.URLParams({
          method: 'list',
          offset: String(offset),
          limit: '5000',
          additional: JSON.stringify(['exif', 'gps', 'resolution', 'thumbnail']),
          album_id: String(this.previewAlbum?.id)
        }).toString())
        if (photores !== 'fail') {
          const photos = photores['list'] as PhotoResItem[]
          if (photos.length === 0) {
            finished = true
            return
          }
          for (let i = 0; i < photos.length; i++) {
            const item = photos[i]
            if (!this.folderMap.has(item.folder_id)) {
              if (this.account !== account || this.previewAlbum?.id !== albumId) {
                return
              }
              const folderres = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.Folder', new url.URLParams({
                method: 'get',
                id: String(item.folder_id)
              }).toString())
              if (folderres !== 'fail') {
                const folderPath = folderres['folder']['name'] as string
                let path = '/home/Photos' + folderPath
                if (folderPath !== '/') {
                  path += '/'
                }
                this.folderMap.set(item.folder_id, path)
                if (this.account !== account || this.previewAlbum?.id !== albumId) {
                  return
                }
                const task = new taskpool.Task(pushPhotoIntoPhotoArray, this.context, accountInfo, {
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
                  additional: item.additional,
                  type: item.type,
                  thumbnailUri: ''
                } as PhotoItem, item.additional.thumbnail)
                const res = await taskpool.execute(task)
                if (this.account !== account) {
                  return
                }
                this.albumPhotoArray.push(res as PhotoItem)
              }
            } else {
              if (this.account !== account || this.previewAlbum?.id !== albumId) {
                return
              }
              const task = new taskpool.Task(pushPhotoIntoPhotoArray, this.context, accountInfo, {
                id: item.id,
                filename: item.filename,
                filesize: item.filesize,
                time: item.time,
                folder_id: item.folder_id,
                url: accountInfo.path + '/fbdownload/' +
                  item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') + '?tid=' + tid + '&mode=open&dlink=' +
                  Array.from(textEncoder.encodeInto(this.folderMap.get(item.folder_id) + item.filename))
                    .map(byte => byte.toString(16).padStart(2, '0')).join(''),
                path: this.folderMap.get(item.folder_id) + item.filename,
                additional: item.additional,
                type: item.type,
                thumbnailUri: ''
              } as PhotoItem, item.additional.thumbnail)
              const res = await taskpool.execute(task)
              if (this.account !== account) {
                return
              }
              this.albumPhotoArray.push(res as PhotoItem)
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

  getDayNightMode() {
    const colorMode = getFlushPreference(this.context, 'commonSetting', 'colorMode', 0)
    if (colorMode === 0) {
      return mapCommon.DayNightMode.AUTO
    }
    if (colorMode === 1) {
      return mapCommon.DayNightMode.DAY
    }
    if (colorMode === 2) {
      return mapCommon.DayNightMode.NIGHT
    }
    return mapCommon.DayNightMode.AUTO
  }

  @Builder
  AddphotointoalbumSheetBuilder() {
    Addphotointoalbum({
      addId: this.editId
    })
  }

  @Builder
  RenamealbumSheetBuilder() {
    Renamealbum({
      editId: this.editId,
      editName: this.editName
    })
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
            .enableAutoSpacing(true)

            Text() {
              Span('时间：')
                .fontWeight(FontWeight.Medium)
              Span(getTimeStringFromSecond(this.previewPhoto.time))
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

            Text() {
              Span('尺寸：')
                .fontWeight(FontWeight.Medium)
              Span(this.previewPhoto.additional.resolution.width + 'x' +
                this.previewPhoto.additional.resolution.height)
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            Text() {
              Span('路径：')
                .fontWeight(FontWeight.Medium)
              Span(this.previewPhoto.path)
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            if (this.previewPhoto.additional.exif.camera) {
              Text() {
                Span('相机型号：')
                  .fontWeight(FontWeight.Medium)
                Span(this.previewPhoto.additional.exif.camera)
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.previewPhoto.additional.exif.aperture) {
              Text() {
                Span('光圈：')
                  .fontWeight(FontWeight.Medium)
                Span(this.previewPhoto.additional.exif.aperture)
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.previewPhoto.additional.exif.exposure_time) {
              Text() {
                Span('曝光时间：')
                  .fontWeight(FontWeight.Medium)
                Span(this.previewPhoto.additional.exif.exposure_time)
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.previewPhoto.additional.exif.focal_length) {
              Text() {
                Span('焦距：')
                  .fontWeight(FontWeight.Medium)
                Span(this.previewPhoto.additional.exif.focal_length)
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.previewPhoto.additional.exif.iso) {
              Text() {
                Span('感光度：')
                  .fontWeight(FontWeight.Medium)
                Span(this.previewPhoto.additional.exif.iso)
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            }
            if (this.previewPhoto.additional.gps) {
              Text() {
                Span('纬度：')
                  .fontWeight(FontWeight.Medium)
                Span(String(this.previewPhoto.additional.gps.latitude))
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })

              Text() {
                Span('经度：')
                  .fontWeight(FontWeight.Medium)
                Span(String(this.previewPhoto.additional.gps.longitude))
              }
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })

              Text() {
                Span('地点：')
                  .fontWeight(FontWeight.Medium)
                Span(String(this.photoAddress))
                  .fontColor($r('sys.color.font_emphasize'))
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
              .onClick(async () => {
                if (this.previewPhoto) {
                  const geo =
                    await map.convertCoordinate(mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, {
                      latitude: this.previewPhoto.additional.gps.latitude,
                      longitude: this.previewPhoto.additional.gps.longitude
                    })
                  await petalMaps.openMapPoiDetail(this.context, {
                    destinationPosition: {
                      latitude: geo.latitude,
                      longitude: geo.longitude
                    }
                  })
                }
              })

              MapComponent({
                mapOptions: {
                  position: {
                    target: {
                      latitude: map.convertCoordinateSync(mapCommon.CoordinateType.WGS84,
                        mapCommon.CoordinateType.GCJ02, {
                          latitude: this.previewPhoto.additional.gps.latitude,
                          longitude: this.previewPhoto.additional.gps.longitude
                        }).latitude,
                      longitude: map.convertCoordinateSync(mapCommon.CoordinateType.WGS84,
                        mapCommon.CoordinateType.GCJ02, {
                          latitude: this.previewPhoto.additional.gps.latitude,
                          longitude: this.previewPhoto.additional.gps.longitude
                        }).longitude
                    },
                    zoom: 17
                  },
                  rotateGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomControlsEnabled: false,
                  compassControlsEnabled: false,
                  dayNightMode: this.getDayNightMode(),
                  approveNumberEnabled: true
                },
                mapCallback: () => {
                }
              })
                .height(300)
                .margin({
                  top: $r('sys.float.ohos_id_text_margin_vertical')
                })
            }
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
      MenuItem({
        content: '下载'
      })
        .onClick(async () => {
          const promptAction = this.UIContext.getPromptAction()
          if (item.type === 'photo') {
            this.dialogControllerProgress.open()
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
              const accountInfo = await getAccountInfo(this.context)
              const session = rcp.createSession({
                requestConfiguration: {
                  tracing: {
                    httpEventsHandler: {
                      onDataReceive: async (incomingData) => {
                        await fileStream.write(incomingData)
                      },
                      onDataEnd: () => {
                        session.close()
                        this.dialogControllerProgress.close()
                        netBoost.setSceneDesc({
                          scene: 'download',
                          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                        })
                        fileStream.closeSync()
                      }
                    }
                  },
                  dns: {
                    dnsRules: getDnsServer(this.context)
                  },
                  security: {
                    remoteValidation: getFlushPreference(this.context, 'debugSetting',
                      'closeRemoteValidationWhenLinkDsm', 'system') as 'system' | 'skip',
                    tlsRange: {
                      min: 'TlsV1.2'
                    }
                  }
                },
                headers: {
                  referer: accountInfo.path,
                  'x-syno-token': accountInfo.synotoken
                },
                cookies: {
                  id: accountInfo.sid
                }
              })
              try {
                const response = await session.get(accountInfo.path + '/webapi/entry.cgi?' + new url.URLParams({
                  api: 'SYNO.FileStation.Download',
                  version: String(version),
                  method: 'download',
                  path: item.path,
                  mode: 'download'
                }).toString())
                if (response.statusCode >= 200 && response.statusCode < 300) {
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
                  await phAccessHelper.release()
                  if (uris.length === 1) {
                    const srcFile = fileIo.openSync(uri)
                    const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                    await fileIo.copyFile(srcFile.fd, destFile.fd)
                    fileIo.closeSync(srcFile)
                    fileIo.closeSync(destFile)
                    await promptAction.openToast({
                      message: '保存成功'
                    })
                  }
                } else {
                  await promptAction.openToast({
                    message: 'HTTP 请求失败，状态码：' + response.statusCode
                  })
                }
              } catch (err) {
                session.close()
                this.dialogControllerProgress.close()
                netBoost.setSceneDesc({
                  scene: 'download',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                })
                fileStream.closeSync()
                await promptAction.openToast({
                  message: '下载失败，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
                })
              }
              await fileIo.unlink(path)
              return
            }
            this.dialogControllerProgress.close()
          }
          if (item.type === 'video') {
            if (getCurrentNetworkBearerType() === 0) {
              const cellularDataUseRemind =
                getFlushPreference(this.context, 'commonSetting', 'cellularDataUseRemind', 0)
              if (cellularDataUseRemind === 0 ||
                (cellularDataUseRemind === 1 && item.filesize > 200 * Math.pow(1024, 2))) {
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
            const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(this.context, {
              name: 'transferTask'
            })
            const transferTaskId = util.generateRandomUUID()
            try {
              const documentSaveOptions = new picker.DocumentSaveOptions()
              const selectFileDownloadPath =
                getFlushPreference(this.context, 'commonSetting', 'selectFileDownloadPath', false)
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
                this.dialogControllerProgress.open()
                const version = await getDsmApiMaxVersion(this.context, '', 'SYNO.FileStation.Download')
                this.dialogControllerProgress.close()
                if (version !== 'fail') {
                  const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                  const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
                  netBoost.setSceneDesc({
                    scene: 'download',
                    sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                  })
                  const accountInfo = await getAccountInfo(this.context)
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
                          },
                          onDownloadProgress: (totalSize, transferredSize) => {
                            this.transferredSize = transferredSize
                            this.totalSize = totalSize
                          },
                          onDataEnd: () => {
                            this.isShowProgressSheet = false
                            session.close()
                            netBoost.setSceneDesc({
                              scene: 'download',
                              sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                            })
                            fileStream.closeSync()
                            this.context.eventHub.off('cancelDownload')
                            this.transferredSize = 0
                            this.totalSize = 0
                          }
                        }
                      },
                      dns: {
                        dnsRules: getDnsServer(this.context)
                      },
                      security: {
                        remoteValidation: getFlushPreference(this.context, 'debugSetting',
                          'closeRemoteValidationWhenLinkDsm', 'system') as 'system' | 'skip',
                        tlsRange: {
                          min: 'TlsV1.2'
                        }
                      }
                    },
                    headers: {
                      referer: accountInfo.path,
                      'x-syno-token': accountInfo.synotoken
                    },
                    cookies: {
                      id: accountInfo.sid
                    }
                  })
                  this.totalSize = item.filesize
                  this.context.eventHub.on('cancelDownload', () => {
                    session.cancel()
                  })
                  this.isShowProgressSheet = true
                  try {
                    const response = await session.get(accountInfo.path + '/webapi/entry.cgi?' + new url.URLParams({
                      api: 'SYNO.FileStation.Download',
                      version: String(version),
                      method: 'download',
                      path: item.path,
                      mode: 'download'
                    }).toString())
                    if (response.statusCode >= 200 && response.statusCode < 300) {
                      await promptAction.openToast({
                        message: '下载完成'
                      })
                      transferTaskDataPreferences.putSync(transferTaskId, JSON.stringify({
                        id: transferTaskId,
                        name: item.filename,
                        status: 'success',
                        type: 'download'
                      }))
                    } else {
                      await promptAction.openToast({
                        message: 'HTTP 请求失败，状态码：' + response.statusCode
                      })
                      transferTaskDataPreferences.putSync(transferTaskId, JSON.stringify({
                        id: transferTaskId,
                        name: item.filename,
                        status: 'fail',
                        errCode: response.statusCode,
                        type: 'download'
                      }))
                    }
                  } catch (err) {
                    this.isShowProgressSheet = false
                    session.close()
                    netBoost.setSceneDesc({
                      scene: 'download',
                      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                    })
                    fileStream.closeSync()
                    this.context.eventHub.off('cancelDownload')
                    this.transferredSize = 0
                    this.totalSize = 0
                    if (err.code !== 1007900992) {
                      await promptAction.openToast({
                        message: '下载失败，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
                      })
                      transferTaskDataPreferences.putSync(transferTaskId, JSON.stringify({
                        id: transferTaskId,
                        name: item.filename,
                        status: 'fail',
                        errCode: err.code,
                        type: 'download'
                      }))
                    }
                    if (err.code === 1007900992) {
                      transferTaskDataPreferences.putSync(transferTaskId, JSON.stringify({
                        id: transferTaskId,
                        name: item.filename,
                        status: 'cancel',
                        type: 'download'
                      }))
                    }
                  }
                }
              }
            } catch (err) {
              await promptAction.openToast({
                message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
              })
              transferTaskDataPreferences.putSync(transferTaskId, JSON.stringify({
                id: transferTaskId,
                name: item.filename,
                status: 'fail',
                errCode: err.code,
                type: 'download'
              }))
            }
          }
        })
      MenuItem({
        content: '加入相册'
      })
        .onClick(() => {
          this.editId = item.id
          this.isShowAddphotointoalbumSheet = true
        })
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
            this.dialogControllerProgress.open()
            const startres = await dsmRequest(this.context, '', 'SYNO.FileStation.Delete', new url.URLParams({
              method: 'start',
              path: item.path
            }).toString())
            if (startres !== 'fail') {
              const taskId = startres['taskid'] as string
              let finished = false
              while (!finished) {
                const statusres = await dsmRequest(this.context, '', 'SYNO.FileStation.Delete', new url.URLParams({
                  method: 'status',
                  taskid: taskId
                }).toString())
                if (statusres !== 'fail') {
                  if (statusres['finished']) {
                    finished = true
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                    setTimeout(async () => {
                      if (item.type === 'photo') {
                        await fileIo.unlink(new fileUri.FileUri(item.thumbnailUri).path)
                      }
                    }, 5000)
                    this.previewPhoto = undefined
                    setTempPreference(this.context, 'back', 'album', false)
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
            this.dialogControllerProgress.close()
          }
        })
      if (this.previewAlbum) {
        MenuItem({
          content: '从相册中删除'
        })
          .contentFontColor($r('sys.color.warning'))
          .onClick(async () => {
            this.dialogControllerProgress.open()
            const res = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.NormalAlbum', new url.URLParams({
              method: 'delete_item',
              item: JSON.stringify([item.id]),
              id: String(this.previewAlbum?.id)
            }).toString())
            this.dialogControllerProgress.close()
            if (res !== 'fail') {
              await promptAction.openToast({
                message: '删除成功'
              })
              this.previewPhoto = undefined
              await this.getAlbumPhoto()
              await this.get(1)
            }
          })
      }
    }
  }

  @Builder
  AlbumMenuBuilder(item: AlbumItem) {
    Menu() {
      MenuItem({
        startIcon: $r('app.media.rename'),
        content: '重命名'
      })
        .onClick(() => {
          this.editId = item.id
          this.editName = item.name
          this.isShowRenamealbumSheet = true
        })
      MenuItem({
        startIcon: $r('app.media.delete'),
        content: '删除'
      })
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
            this.dialogControllerProgress.open()
            const res = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.Album', new url.URLParams({
              method: 'delete',
              id: JSON.stringify([item.id])
            }).toString())
            this.dialogControllerProgress.close()
            if (res !== 'fail') {
              await promptAction.openToast({
                message: '删除成功'
              })
              this.loading = true
            }
          }
        })
    }
  }

  build() {
    Scroll() {
      Column() {
        if (!this.isLogin) {
          Text('未登录账号')
            .height('100%')
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
              selectedIndex: this.selectedIndex!!,
              enableStateAnimation: true
            })
              .margin({
                bottom: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
            if (this.selectedIndex === 0 && !this.previewPhoto) {
              Row() {
                Blank()
                Column() {
                  Image($r('app.media.upload'))
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
                .systemMaterial(new uiMaterial.ImmersiveMaterial({
                  style: uiMaterial.ImmersiveStyle.REGULAR,
                  interactive: true,
                  lightEffect: {
                    color: Color.White
                  }
                }))
                .width(40)
                .onClick(async () => {
                  const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(this.context, {
                    name: 'transferTask'
                  })
                  const accountInfo = await getAccountInfo(this.context)
                  await checkPermission(this.context, this.UIContext, 'ohos.permission.MEDIA_LOCATION', true)
                  const photoPicker = new photoAccessHelper.PhotoViewPicker()
                  const pickerres = await photoPicker.select({
                    MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
                    showDateOnScrollbar: true,
                    preferredCompatibleMode: photoAccessHelper.PreferredCompatibleMode.CURRENT,
                    maxSelectNumber: 500,
                    isOriginalSupported: false,
                    isDestroyedWithNavigation: true
                  })
                  const promises = pickerres.photoUris.map(async (item) => {
                    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
                    const predicates = new dataSharePredicates.DataSharePredicates()
                    predicates.equalTo('uri', item)
                    const fetchResult = await phAccessHelper.getAssets({
                      fetchColumns: [],
                      predicates: predicates
                    })
                    await phAccessHelper.release()
                    const photoAsset = await fetchResult.getFirstObject()
                    const id = util.generateRandomUUID()
                    if (!photoAsset.displayName.endsWith('.heic')) {
                      transferTaskDataPreferences.putSync(id, JSON.stringify({
                        id: id,
                        path: '/home/Photos',
                        name: photoAsset.displayName,
                        transferredSize: 0,
                        totalSize: fileIo.statSync(item).size,
                        status: 'pending',
                        errCode: 0,
                        type: 'upload',
                        accountInfo: accountInfo,
                        srcFileUri: item
                      }))
                    }
                  })
                  await Promise.all(promises)
                  if (pickerres.photoUris.length > 0) {
                    await promptAction.openToast({
                      message: pickerres.photoUris.length + ' 项传输任务已添加'
                    })
                  }
                })
              }
              .width('100%')
            }
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
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                    })
                    .width('100%')

                    Repeat<TimelineItem>(this.timelineArray)
                      .each((timelineItem: RepeatItem<TimelineItem>) => {
                        ListItemGroup() {
                          ListItem() {
                            Text(timelineItem.item.date)
                              .enableAutoSpacing(true)
                              .fontSize($r('sys.float.ohos_id_text_size_headline9'))
                              .fontWeight(FontWeight.Bold)
                          }

                          ListItem() {
                            List() {
                              Repeat<PhotoItem>(this.photoArray.filter((photoItem,
                                photoIndex): boolean => this.isPhotoVisiable(photoIndex, timelineItem.index)))
                                .each((photoItem: RepeatItem<PhotoItem>) => {
                                  ListItem() {
                                    Column() {
                                      if (photoItem.item.type === 'photo') {
                                        Image(photoItem.item.thumbnailUri)
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
                                          .onClick(async () => {
                                            if (photoItem.item.additional.gps) {
                                              const geo = await map.convertCoordinate(mapCommon.CoordinateType.WGS84,
                                                mapCommon.CoordinateType.GCJ02, {
                                                  latitude: photoItem.item.additional.gps.latitude,
                                                  longitude: photoItem.item.additional.gps.longitude
                                                })
                                              try {
                                                const res = await site.reverseGeocode({
                                                  location: {
                                                    latitude: geo.latitude,
                                                    longitude: geo.longitude
                                                  },
                                                  language: 'zh-CN'
                                                })
                                                this.photoAddress = res.addressDescription
                                              } catch (err) {
                                                await promptAction.openToast({
                                                  message: '发生错误，错误码：' + err.code +
                                                    (err.message ? '，错误信息：' + err.message : '')
                                                })
                                                this.photoAddress = '地址获取失败，可尝试点此跳转系统地图查看'
                                              }
                                            }
                                            this.previewPhoto = photoItem.item
                                            setTempPreference(this.context, 'back', 'album', true)
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
                                              message: '发生错误，错误码：' + err.code +
                                                (err.message ? '，错误信息：' + err.message : '')
                                            })
                                          })
                                      }
                                    }
                                    .onClick(async () => {
                                      if (photoItem.item.additional.gps) {
                                        const geo = await map.convertCoordinate(mapCommon.CoordinateType.WGS84,
                                          mapCommon.CoordinateType.GCJ02, {
                                            latitude: photoItem.item.additional.gps.latitude,
                                            longitude: photoItem.item.additional.gps.longitude
                                          })
                                        try {
                                          const res = await site.reverseGeocode({
                                            location: {
                                              latitude: geo.latitude,
                                              longitude: geo.longitude
                                            },
                                            language: 'zh-CN'
                                          })
                                          this.photoAddress = res.addressDescription
                                        } catch (err) {
                                          await promptAction.openToast({
                                            message: '发生错误，错误码：' + err.code +
                                              (err.message ? '，错误信息：' + err.message : '')
                                          })
                                          this.photoAddress = '地址获取失败，可尝试点此跳转系统地图查看'
                                        }
                                      }
                                      this.previewPhoto = photoItem.item
                                      setTempPreference(this.context, 'back', 'album', true)
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
                          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                        })
                      })
                      .virtualScroll()
                    ListItem()
                      .margin({
                        bottom: this.preferType === 0 ? 80 : 0
                      })
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
                          .enableAutoSpacing(true)
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
                      .onHover(isHover => {
                        if (!isHover) {
                          this.hoverId = -1
                        }
                        if (isHover) {
                          this.hoverId = albumIndex
                        }
                      })
                      .onClick(async () => {
                        this.previewAlbum = albumItem
                        setTempPreference(this.context, 'back', 'album', true)
                        await this.getAlbumPhoto()
                      })
                      .bindContextMenu(this.AlbumMenuBuilder(albumItem), ResponseType.LongPress, {
                        hapticFeedbackMode: HapticFeedbackMode.AUTO
                      })
                      .bindContextMenu(this.AlbumMenuBuilder(albumItem), ResponseType.RightClick, {
                        hapticFeedbackMode: HapticFeedbackMode.AUTO
                      })
                      .bindSheet(this.isShowRenamealbumSheet!!, this.RenamealbumSheetBuilder(), {
                        height: SheetSize.FIT_CONTENT,
                        preferType: this.preferType,
                        title: {
                          title: '重命名'
                        }
                      })
                    })
                  }
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    bottom: this.preferType === 0 ? 80 : 0
                  })
                  .padding($r('sys.float.ohos_id_corner_radius_mark'))
                }
              }
            }
            .keyboardShortcut('R', [ModifierKey.CTRL], () => {
              this.loading = true
            })
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
                .systemMaterial(new uiMaterial.ImmersiveMaterial({
                  style: uiMaterial.ImmersiveStyle.REGULAR,
                  interactive: true,
                  lightEffect: {
                    color: Color.White
                  }
                }))
                .width(40)
                .onClick(() => {
                  this.previewPhoto = undefined
                  setTempPreference(this.context, 'back', 'album', false)
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
                .systemMaterial(new uiMaterial.ImmersiveMaterial({
                  style: uiMaterial.ImmersiveStyle.REGULAR,
                  interactive: true,
                  lightEffect: {
                    color: Color.White
                  }
                }))
                .width(40)
                .bindMenu(this.MenuBuilder(this.previewPhoto))
              }
              .bindSheet(this.isShowAddphotointoalbumSheet!!, this.AddphotointoalbumSheetBuilder(), {
                preferType: this.preferType,
                title: {
                  title: '加入相册'
                }
              })

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
                            if (photoArray[index - 1].additional.gps) {
                              try {
                                const res = await site.reverseGeocode({
                                  location: {
                                    latitude: photoArray[index - 1].additional.gps.latitude,
                                    longitude: photoArray[index - 1].additional.gps.longitude
                                  },
                                  language: 'zh-CN'
                                })
                                this.photoAddress = res.addressDescription
                              } catch (err) {
                                await promptAction.openToast({
                                  message: '发生错误，错误码：' + err.code +
                                    (err.message ? '，错误信息：' + err.message : '')
                                })
                                this.photoAddress = '地址获取失败，可尝试点此跳转系统地图查看'
                              }
                            }
                            this.previewPhoto = photoArray[index - 1]
                            setTempPreference(this.context, 'back', 'album', true)
                          }
                          if (index === 0) {
                            await promptAction.openToast({
                              message: '已是第一张'
                            })
                          }
                        }
                        if (gestureEvent.offsetX < 0) {
                          if (index !== maxIndex) {
                            if (photoArray[index + 1].additional.gps) {
                              try {
                                const res = await site.reverseGeocode({
                                  location: {
                                    latitude: photoArray[index + 1].additional.gps.latitude,
                                    longitude: photoArray[index + 1].additional.gps.longitude
                                  },
                                  language: 'zh-CN'
                                })
                                this.photoAddress = res.addressDescription
                              } catch (err) {
                                await promptAction.openToast({
                                  message: '发生错误，错误码：' + err.code +
                                    (err.message ? '，错误信息：' + err.message : '')
                                })
                                this.photoAddress = '地址获取失败，可尝试点此跳转系统地图查看'
                              }
                            }
                            this.previewPhoto = photoArray[index + 1]
                            setTempPreference(this.context, 'back', 'album', true)
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
                      message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
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
            .margin({
              bottom: this.preferType === 0 ? 80 : 0
            })
            .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              title: {
                title: '详情'
              }
            })
          }
          if (this.previewAlbum && !this.previewPhoto) {
            Scroll() {
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
                  .systemMaterial(new uiMaterial.ImmersiveMaterial({
                    style: uiMaterial.ImmersiveStyle.REGULAR,
                    interactive: true,
                    lightEffect: {
                      color: Color.White
                    }
                  }))
                  .width(40)
                  .onClick(() => {
                    this.previewAlbum = undefined
                    setTempPreference(this.context, 'back', 'album', false)
                  })

                  Text(this.previewAlbum.name)
                    .enableAutoSpacing(true)
                    .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                    .fontWeight(FontWeight.Bold)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({
                      overflow: TextOverflow.Ellipsis
                    })
                }
                .margin({
                  bottom: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })

                if (this.albumPhotoArray.length === 0) {
                  Text('无数据')
                }
                List() {
                  Repeat<PhotoItem>(this.albumPhotoArray)
                    .each((photoItem: RepeatItem<PhotoItem>) => {
                      ListItem() {
                        Column() {
                          if (photoItem.item.type === 'photo') {
                            Image(photoItem.item.thumbnailUri)
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
                              .onClick(async () => {
                                if (photoItem.item.additional.gps) {
                                  const geo = await map.convertCoordinate(mapCommon.CoordinateType.WGS84,
                                    mapCommon.CoordinateType.GCJ02, {
                                      latitude: photoItem.item.additional.gps.latitude,
                                      longitude: photoItem.item.additional.gps.longitude
                                    })
                                  try {
                                    const res = await site.reverseGeocode({
                                      location: {
                                        latitude: geo.latitude,
                                        longitude: geo.longitude
                                      },
                                      language: 'zh-CN'
                                    })
                                    this.photoAddress = res.addressDescription
                                  } catch (err) {
                                    await promptAction.openToast({
                                      message: '发生错误，错误码：' + err.code +
                                        (err.message ? '，错误信息：' + err.message : '')
                                    })
                                    this.photoAddress = '地址获取失败，可尝试点此跳转系统地图查看'
                                  }
                                }
                                this.previewPhoto = photoItem.item
                                setTempPreference(this.context, 'back', 'album', true)
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
                                  message: '发生错误，错误码：' + err.code +
                                    (err.message ? '，错误信息：' + err.message : '')
                                })
                              })
                          }
                        }
                        .onClick(async () => {
                          if (photoItem.item.additional.gps) {
                            const geo = await map.convertCoordinate(mapCommon.CoordinateType.WGS84,
                              mapCommon.CoordinateType.GCJ02, {
                                latitude: photoItem.item.additional.gps.latitude,
                                longitude: photoItem.item.additional.gps.longitude
                              })
                            try {
                              const res = await site.reverseGeocode({
                                location: {
                                  latitude: geo.latitude,
                                  longitude: geo.longitude
                                },
                                language: 'zh-CN'
                              })
                              this.photoAddress = res.addressDescription
                            } catch (err) {
                              await promptAction.openToast({
                                message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
                              })
                              this.photoAddress = '地址获取失败，可尝试点此跳转系统地图查看'
                            }
                          }
                          this.previewPhoto = photoItem.item
                          setTempPreference(this.context, 'back', 'album', true)
                        })
                      }
                    })
                    .virtualScroll()
                  ListItem()
                    .margin({
                      bottom: this.preferType === 0 ? 80 : 0
                    })
                }
                .lanes(4)
                .layoutWeight(1)
              }
            }
          }
        }
      }
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
          setTempPreference(this.context, 'back', 'album', false)
        }
        if (this.previewPhoto && this.previewAlbum) {
          this.previewPhoto = undefined
          return
        }
        if (this.previewAlbum) {
          this.previewAlbum = undefined
          setTempPreference(this.context, 'back', 'album', false)
        }
      })
      this.context.eventHub.on('refreshAlbum', async (clear = true) => {
        if (clear) {
          this.previewPhoto = undefined
          this.previewAlbum = undefined
          setTempPreference(this.context, 'back', 'album', false)
        }
        await this.get(2, true)
      })
      await this.get()
    })
    .onDisAppear(async () => {
      this.context.eventHub.off('refreshAlbum')
      this.context.eventHub.off('backAlbum')
      const lastWindow = await window.getLastWindow(this.context)
      lastWindow.off('windowSizeChange')
      display.off('change')
    })
  }
}