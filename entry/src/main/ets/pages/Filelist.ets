import { common } from '@kit.AbilityKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { fastbuffer } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo, fileUri, picker } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { filePreview } from '@kit.PreviewKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { systemShare } from '@kit.ShareKit'
import { get, getLoginStatus } from '../common/Account'
import { dsmRequest, getDsmApiMaxVersion } from '../common/Request'
import Download from './Download'
import Newfolder from './Newfolder'
import Renamefile from './Renamefile'

interface Time {
  atime: number,
  crtime: number,
  ctime: number,
  mtime: number
}

interface Additional {
  size: number,
  time: Time
}

interface FileItem {
  path: string,
  name: string,
  isdir: boolean,
  additional: Additional
}

interface ShareLinkItem {
  qrcode: string,
  url: string
}

@ComponentV2
export default struct Filelist {
  @Provider() isShowNewfolderSheet: boolean = false
  @Provider() isShowDownloadSheet: boolean = false
  @Provider() isShowRenamefileSheet: boolean = false
  @Local isLogin: boolean = false
  @Local sortByIndex: number = 2
  @Local sortByValue: string = '类型'
  @Local sortDirectionIndex: number = 0
  @Local sortDirectionValue: string = '正序'
  @Local dirnames: string[] = []
  @Local fileArray: FileItem[] = []
  @Provider() editPath: string = ''
  @Provider() editName: string = ''
  @Provider() transferredSize: number = -1
  @Provider() totalSize: number = -1
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1

  getSizeString(size: number) {
    if (size < Math.pow(1024, 1)) {
      return size + ' B'
    }
    if (size >= Math.pow(1024, 1) && size < Math.pow(1024, 2)) {
      return (size / Math.pow(1024, 1)).toFixed(2) + ' KB'
    }
    if (size >= Math.pow(1024, 2) && size < Math.pow(1024, 3)) {
      return (size / Math.pow(1024, 2)).toFixed(2) + ' MB'
    }
    if (size >= Math.pow(1024, 3) && size < Math.pow(1024, 4)) {
      return (size / Math.pow(1024, 3)).toFixed(2) + ' GB'
    }
    if (size >= Math.pow(1024, 4)) {
      return (size / Math.pow(1024, 4)).toFixed(2) + ' TB'
    }
    return ''
  }

  getTimeString(timestamp: number) {
    const date = new Date(timestamp * 1000)
    return date.getFullYear() + '/' + String(date.getMonth() + 1).padStart(2, '0') + '/' +
    String(date.getDate()).padStart(2, '0') + ' ' + String(date.getHours()).padStart(2, '0') + ':' +
    String(date.getMinutes()).padStart(2, '0') + ':' + String(date.getSeconds()).padStart(2, '0')
  }

  async get() {
    this.isLogin = await getLoginStatus()
    if (this.isLogin) {
      let path = ''
      for (let i = 0; i < this.dirnames.length; i++) {
        path = path + '/' + this.dirnames[i]
      }
      let sortBy = ''
      if (this.sortByValue === '名称') {
        sortBy = 'name'
      }
      if (this.sortByValue === '大小') {
        sortBy = 'size'
      }
      if (this.sortByValue === '类型') {
        sortBy = 'type'
      }
      if (this.sortByValue === '修改日期') {
        sortBy = 'mtime'
      }
      let sortDirection = ''
      if (this.sortDirectionValue === '正序') {
        sortDirection = 'ASC'
      }
      if (this.sortDirectionValue === '倒序') {
        sortDirection = 'DESC'
      }
      const dialogControllerProgress = new CustomDialogController({
        builder: LoadingDialog({
          content: '加载中...'
        })
      })
      dialogControllerProgress.open()
      if (!path) {
        const res = await dsmRequest('', 'SYNO.FileStation.List',
          '&method=list_share&additional=["size","time"]&sort_by=' + sortBy + '&sort_direction=' + sortDirection)
        if (res !== 'fail') {
          this.fileArray = res['shares']
        }
      }
      if (path) {
        const res = await dsmRequest('', 'SYNO.FileStation.List',
          '&method=list&additional=["size","time"]&folder_path=' + encodeURIComponent(path) + '&sort_by=' + sortBy +
            '&sort_direction=' +
            sortDirection)
        if (res !== 'fail') {
          this.fileArray = res['files']
        }
        if (res === 'fail') {
          this.dirnames.pop()
        }
      }
      dialogControllerProgress.close()
    }
  }

  @Builder
  NewfolderSheetBuilder() {
    Newfolder()
  }

  @Builder
  DownloadSheetBuilder() {
    Download()
  }

  @Builder
  RenamefileSheetBuilder() {
    Renamefile()
  }

  @Builder
  MenuBuilder(item: FileItem) {
    Menu() {
      if (!item.isdir) {
        MenuItem({
          startIcon: $r('app.media.download'),
          content: '下载'
        })
          .onClick(async () => {
            try {
              const documentSaveOptions = new picker.DocumentSaveOptions()
              const lastDotIndex = item.name.lastIndexOf('.')
              if (lastDotIndex !== -1) {
                documentSaveOptions.newFileNames = [item.name.substring(0, lastDotIndex)]
                documentSaveOptions.fileSuffixChoices = ['.' + item.name.substring(lastDotIndex + 1)]
              }
              if (lastDotIndex === -1) {
                documentSaveOptions.newFileNames = [item.name]
                documentSaveOptions.fileSuffixChoices = ['']
              }
              const documentViewPicker = new picker.DocumentViewPicker(this.context)
              const uris = await documentViewPicker.save(documentSaveOptions)
              const filePath = uris[0]
              const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
              const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
              const accountInfo = await get()
              const prepareDialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '准备开始下载...'
                })
              })
              prepareDialogControllerProgress.open()
              const version = await getDsmApiMaxVersion('', 'SYNO.FileStation.Download')
              prepareDialogControllerProgress.close()
              if (version !== 'fail') {
                netBoost.setSceneDesc({
                  scene: 'download',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                })
                this.totalSize = item.additional.size
                const session = rcp.createSession({
                  requestConfiguration: {
                    transfer: {
                      timeout: {
                        transferMs: 0
                      }
                    },
                    tracing: {
                      httpEventsHandler: {
                        onDataReceive: (incomingData) => {
                          fileStream.writeSync(incomingData)
                          this.transferredSize = this.transferredSize + incomingData.byteLength
                        },
                        onDataEnd: () => {
                          session.close()
                          netBoost.setSceneDesc({
                            scene: 'download',
                            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                          })
                          fileStream.closeSync()
                          fileIo.closeSync(file)
                          this.transferredSize = -1
                          this.totalSize = -1
                          this.isShowDownloadSheet = false
                          promptAction.openToast({
                            message: '下载成功'
                          })
                        }
                      }
                    }
                  },
                  cookies: {
                    id: accountInfo.sid,
                    did: accountInfo.did
                  }
                })
                this.context.eventHub.on('cancelDownload', () => {
                  session.cancel()
                })
                this.isShowDownloadSheet = true
                try {
                  const response =
                    await session.get(accountInfo.path + '/webapi/entry.cgi?api=SYNO.FileStation.Download&version=' +
                      version + '&method=download&mode=download&path=' + encodeURIComponent(item.path))
                  if (response.statusCode !== 200) {
                    session.close()
                    netBoost.setSceneDesc({
                      scene: 'download',
                      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                    })
                    this.context.eventHub.off('cancelDownload')
                    fileStream.closeSync()
                    fileIo.closeSync(file)
                    this.transferredSize = -1
                    this.totalSize = -1
                    this.isShowDownloadSheet = false
                    promptAction.openToast({
                      message: '下载失败，错误码：' + response.statusCode
                    })
                  }
                } catch (err) {
                  session.close()
                  netBoost.setSceneDesc({
                    scene: 'download',
                    sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                  })
                  this.context.eventHub.off('cancelDownload')
                  fileStream.closeSync()
                  fileIo.closeSync(file)
                  this.transferredSize = -1
                  this.totalSize = -1
                  this.isShowDownloadSheet = false
                  promptAction.openToast({
                    message: '下载失败，错误码：' + err.code
                  })
                }
              } else {
                fileStream.closeSync()
                fileIo.closeSync(file)
              }
            } catch (err) {
              if (err.code !== 13900020 && err.code !== 1007900992) {
                promptAction.openToast({
                  message: '发生错误，错误码：' + err.code
                })
              }
            }
          })
      }
      MenuItem({
        startIcon: $r('app.media.share'),
        content: '分享'
      })
        .onClick(async () => {
          const res = await dsmRequest('', 'SYNO.FileStation.Sharing',
            '&method=create&path=' + encodeURIComponent(JSON.stringify([item.path])))
          if (res !== 'fail') {
            const links = res['links'] as ShareLinkItem[]
            const qrcodebase64 = links[0].qrcode.slice(22)
            const qrcodebuffer = fastbuffer.from(qrcodebase64, 'base64')
            const shareData = new systemShare.SharedData({
              utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
              title: item.name,
              thumbnail: new Uint8Array(qrcodebuffer.buffer),
              content: links[0].url
            })
            const shareController = new systemShare.ShareController(shareData)
            shareController.show(this.context, {})
          }
        })
      MenuItem({
        startIcon: $r('app.media.rename'),
        content: '重命名'
      })
        .onClick(() => {
          this.editPath = item.path
          this.editName = item.name
          this.isShowRenamefileSheet = true
        })
      MenuItem({
        startIcon: $r('app.media.delete'),
        content: '删除'
      })
        .onClick(async () => {
          const promptAction = this.getUIContext().getPromptAction()
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
            const res =
              await dsmRequest('', 'SYNO.FileStation.Delete', '&method=start&path=' + encodeURIComponent(item.path))
            if (res !== 'fail') {
              promptAction.openToast({
                message: '删除成功'
              })
              this.get()
            }
          }
        })
    }
  }

  build() {
    List() {
      if (!this.isLogin) {
        ListItem() {
          Text('未登录账号')
        }
        .height('100%')
        .width('100%')
      }
      if (this.isLogin) {
        ListItem() {
          Row() {
            Select([
              { value: '名称' },
              { value: '大小' },
              { value: '类型' },
              { value: '修改日期' }
            ])
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .selected(this.sortByIndex!!)
              .value(this.sortByValue!!)
              .onSelect(() => {
                this.get()
              })
            Select([
              { value: '正序' },
              { value: '倒序' }
            ])
              .selected(this.sortDirectionIndex!!)
              .value(this.sortDirectionValue!!)
              .onSelect(() => {
                this.get()
              })
          }
          .justifyContent(FlexAlign.End)
          .width('100%')
        }

        ListItem() {
          Text() {
            ForEach(this.dirnames, (item: string, index) => {
              if (index !== 0) {
                Span('/ ')
              }
              if (index === 0) {
                Span('根目录')
                  .fontColor($r('sys.color.font_emphasize'))
                  .onClick(() => {
                    this.dirnames = []
                    this.get()
                  })
                Span(' / ')
              }
              Span(item + ' ')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                  this.dirnames = this.dirnames.slice(0, index + 1)
                  this.get()
                })
            })
          }
          .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.dirnames.length > 0) {
          ListItem() {
            Button('新建文件夹')
              .onClick(() => {
                let path = ''
                for (let i = 0; i < this.dirnames.length; i++) {
                  path = path + '/' + this.dirnames[i]
                }
                this.editPath = path
                this.isShowNewfolderSheet = true
              })
              .bindSheet(this.isShowNewfolderSheet!!, this.NewfolderSheetBuilder(), {
                height: SheetSize.FIT_CONTENT,
                preferType: this.preferType,
                title: {
                  title: '新建文件夹'
                },
                onDisappear: () => {
                  this.editPath = ''
                  this.get()
                }
              })
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        ForEach(this.fileArray, (item: FileItem, index) => {
          ListItem() {
            Column() {
              if (index !== 0) {
                Divider()
                  .padding({
                    left: 38,
                    right: 6
                  })
              }
              Row() {
                if (!item.isdir) {
                  Image($r('app.media.fileicon'))
                    .fillColor($r('sys.color.icon_secondary'))
                    .height(24)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width(24)
                }
                if (item.isdir) {
                  Image($r('app.media.foldericon'))
                    .height(24)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                    .width(24)
                }
                Column() {
                  Text(item.name)
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                    .width('85%')
                  Text() {
                    Span(this.getTimeString(item.additional.time.mtime))
                    if (item.additional.size && !item.isdir) {
                      Span(' - ' + this.getSizeString(item.additional.size))
                    }
                  }
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding({
                bottom: 12,
                left: 6,
                right: 5,
                top: 12
              })
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.background_secondary'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.comp_background_secondary'))
                }
              })
              .width('100%')
              .onClick(async () => {
                if (!item.isdir) {
                  if (item.additional.size > 256 * 1024 * 1024) {
                    promptAction.openToast({
                      message: '文件过大，请长按将其下载到本地后预览'
                    })
                    return
                  }
                  try {
                    const previewDir = this.context.tempDir + '/preview'
                    if (!fileIo.accessSync(previewDir)) {
                      fileIo.mkdirSync(previewDir)
                    }
                    const filePath = previewDir + item.name
                    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                    const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
                    const accountInfo = await get()
                    const prepareDialogControllerProgress = new CustomDialogController({
                      builder: LoadingDialog({
                        content: '准备开始下载...'
                      })
                    })
                    prepareDialogControllerProgress.open()
                    const version = await getDsmApiMaxVersion('', 'SYNO.FileStation.Download')
                    prepareDialogControllerProgress.close()
                    if (version !== 'fail') {
                      netBoost.setSceneDesc({
                        scene: 'download',
                        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                      })
                      this.totalSize = item.additional.size
                      const session = rcp.createSession({
                        requestConfiguration: {
                          transfer: {
                            timeout: {
                              transferMs: 0
                            }
                          },
                          tracing: {
                            httpEventsHandler: {
                              onDataReceive: (incomingData) => {
                                fileStream.writeSync(incomingData)
                                this.transferredSize = this.transferredSize + incomingData.byteLength
                              },
                              onDataEnd: async () => {
                                session.close()
                                netBoost.setSceneDesc({
                                  scene: 'download',
                                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                                })
                                fileStream.closeSync()
                                this.transferredSize = -1
                                this.totalSize = -1
                                this.isShowDownloadSheet = false
                                const uri = fileUri.getUriFromPath(filePath)
                                const canPreview = await filePreview.canPreview(this.context, uri)
                                if (!canPreview) {
                                  promptAction.openToast({
                                    message: '文件类型不支持预览'
                                  })
                                }
                                if (canPreview) {
                                  filePreview.openPreview(this.context, {
                                    title: item.name,
                                    uri: uri,
                                    mimeType: ''
                                  })
                                }
                              }
                            }
                          }
                        },
                        cookies: {
                          id: accountInfo.sid,
                          did: accountInfo.did
                        }
                      })
                      this.context.eventHub.on('cancelDownload', () => {
                        session.cancel()
                      })
                      this.isShowDownloadSheet = true
                      try {
                        const response =
                          await session.get(accountInfo.path +
                            '/webapi/entry.cgi?api=SYNO.FileStation.Download&version=' +
                            version + '&method=download&mode=download&path=' + encodeURIComponent(item.path))
                        if (response.statusCode !== 200) {
                          session.close()
                          netBoost.setSceneDesc({
                            scene: 'download',
                            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                          })
                          this.context.eventHub.off('cancelDownload')
                          fileStream.closeSync()
                          fileIo.closeSync(file)
                          this.transferredSize = -1
                          this.totalSize = -1
                          this.isShowDownloadSheet = false
                          promptAction.openToast({
                            message: '下载失败，错误码：' + response.statusCode
                          })
                        }
                      } catch (err) {
                        session.close()
                        netBoost.setSceneDesc({
                          scene: 'download',
                          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                        })
                        this.context.eventHub.off('cancelDownload')
                        fileStream.closeSync()
                        fileIo.closeSync(file)
                        this.transferredSize = -1
                        this.totalSize = -1
                        this.isShowDownloadSheet = false
                        promptAction.openToast({
                          message: '下载失败，错误码：' + err.code
                        })
                      }
                    } else {
                      fileStream.closeSync()
                      fileIo.closeSync(file)
                    }
                  } catch (err) {
                    if (err.code !== 1007900992) {
                      promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
                }
                if (item.isdir) {
                  this.dirnames.push(item.name)
                  this.get()
                }
              })
              .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress | ResponseType.RightClick, {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
              .bindSheet(this.isShowDownloadSheet!!, this.DownloadSheetBuilder(), {
                height: SheetSize.FIT_CONTENT,
                preferType: this.preferType,
                showClose: false,
                title: {
                  title: '下载'
                },
                onWillDismiss: () => {
                },
                onDisappear: () => {
                  this.context.eventHub.emit('cancelDownload')
                }
              })
            }
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          }
        })
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      if (deviceInfo.deviceType === 'phone') {
        this.preferType = 0
      }
      this.context.eventHub.on('refreshFilelist', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshFilelist')
    })
    .bindSheet(this.isShowRenamefileSheet!!, this.RenamefileSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '重命名'
      },
      onDisappear: () => {
        this.editPath = ''
        this.editName = ''
        this.get()
      }
    })
  }
}