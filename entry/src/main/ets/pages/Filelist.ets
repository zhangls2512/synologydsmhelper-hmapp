import { common, wantAgent } from '@kit.AbilityKit'
import { preferences, uniformTypeDescriptor } from '@kit.ArkData'
import { fastbuffer, util } from '@kit.ArkTS'
import { display, LoadingDialog, promptAction } from '@kit.ArkUI'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { fileIo, fileUri, picker } from '@kit.CoreFileKit'
import { fileManagerService } from '@kit.FileManagerServiceKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { notificationManager } from '@kit.NotificationKit'
import { filePreview } from '@kit.PreviewKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { systemShare } from '@kit.ShareKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { get, getLoginStatus } from '../common/Account'
import { getCurrentNetworkBearerType } from '../common/Network'
import { dsmRequest, getDsmApiMaxVersion } from '../common/Request'
import Newfolder from './Newfolder'
import Player from './Player'
import Progress from './Progress'
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
  @Provider() isShowPlayerSheet: boolean = false
  @Provider() isShowProgressSheet: boolean = false
  @Provider() isShowRenamefileSheet: boolean = false
  @Local loading: boolean = false
  @Local fileArray: FileItem[] = []
  @Local dirnames: string[] = []
  @Provider() editPath: string = ''
  @Provider() editName: string = ''
  @Provider() transferredSize: number = -1
  @Provider() totalSize: number = -1
  @Local isLogin: boolean = false
  @Local sortByIndex: number = 2
  @Local sortByValue: string = '类型'
  @Local sortDirectionIndex: number = 0
  @Local sortDirectionValue: string = '正序'
  @Local searchKeyword: string = ''
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: string[] = []
  @Local copyMovePath: string = ''
  @Local remove: boolean = false
  @Provider() src: string = ''
  @Local srcName: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1
  dirnamesDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'dirnames'
  })
  searchDialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '搜索中...'
    })
  })
  prepareDownloadDialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '下载准备中...'
    })
  })
  deleteDialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '删除中...'
    })
  })

  getFileTypeIcon(name: string) {
    let houzhui = ''
    const lastDotIndex = name.lastIndexOf('.')
    if (lastDotIndex !== -1) {
      houzhui = '.' + name.slice(lastDotIndex + 1)
    }
    const fileType = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(houzhui)
    return fileManagerService.getFileIconSync(fileType)
  }

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

  getPath() {
    let path = ''
    for (let i = 0; i < this.dirnames.length; i++) {
      path = path + '/' + this.dirnames[i]
    }
    return path
  }

  async get() {
    this.searchKeyword = ''
    this.isLogin = await getLoginStatus()
    if (this.isLogin) {
      const path = this.getPath()
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
        this.fileArray = []
        if (res !== 'fail') {
          this.fileArray = res['files']
        }
      }
      dialogControllerProgress.close()
    }
  }

  async search() {
    this.searchDialogControllerProgress.open()
    const res = await dsmRequest('', 'SYNO.FileStation.Search',
      '&method=start&folder_path=' + encodeURIComponent(JSON.stringify([this.getPath()])) + '&pattern=' +
      encodeURIComponent(this.searchKeyword))
    if (res !== 'fail') {
      const taskId = res['taskid'] as string
      this.searchByTaskId(taskId)
    }
    if (res === 'fail') {
      this.searchDialogControllerProgress.close()
    }
  }

  async searchByTaskId(taskId: string) {
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
      sortBy = 'mt'
    }
    let sortDirection = ''
    if (this.sortDirectionValue === '正序') {
      sortDirection = 'ASC'
    }
    if (this.sortDirectionValue === '倒序') {
      sortDirection = 'DESC'
    }
    const res = await dsmRequest('', 'SYNO.FileStation.Search',
      '&method=list&additional=["size","time"]&taskid=' + taskId + '&sort_by=' + sortBy + '&sort_direction=' +
        sortDirection)
    if (res !== 'fail') {
      const finished = res['finished'] as boolean
      if (!finished) {
        this.searchByTaskId(taskId)
      }
      if (finished) {
        this.searchDialogControllerProgress.close()
        const files = res['files'] as FileItem[]
        if (!files) {
          this.fileArray = []
        }
        if (files) {
          this.fileArray = files
        }
      }
    }
    if (res === 'fail') {
      this.searchDialogControllerProgress.close()
    }
  }

  @Builder
  NewfolderSheetBuilder() {
    Newfolder()
  }

  @Builder
  PlayerSheetBuilder() {
    Player()
  }

  @Builder
  ProgressSheetBuilder() {
    Progress()
  }

  @Builder
  RenamefileSheetBuilder() {
    Renamefile()
  }

  @Builder
  MenuBuilder(item: FileItem) {
    Menu() {
      if (this.multipleSelect) {
        MenuItem({
          startIcon: $r('app.media.multipleselect'),
          content: '取消多选'
        })
          .onClick(() => {
            this.multipleSelect = false
            this.multipleSelectArray = []
          })
      }
      if (!this.multipleSelect) {
        if (this.dirnames.length > 0) {
          MenuItem({
            startIcon: $r('app.media.multipleselect'),
            content: '多选'
          })
            .onClick(() => {
              this.multipleSelect = true
              this.multipleSelectArray.push(item.path)
            })
        }
        if (!item.isdir) {
          MenuItem({
            startIcon: $r('app.media.download'),
            content: '下载'
          })
            .onClick(async () => {
              if (getCurrentNetworkBearerType() === 0) {
                const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                  name: 'commonSetting'
                })
                const cellularDataUseRemind = commonSettingDataPreferences.getSync('cellularDataUseRemind', 0)
                if (cellularDataUseRemind === 0 ||
                  (cellularDataUseRemind === 1 && item.additional.size > 200 * Math.pow(1024, 2))) {
                  const promptAction = this.getUIContext().getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '流量使用提醒',
                    message: '当前正在使用流量上网，下载此文件将消耗约 ' + this.getSizeString(item.additional.size) +
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
                if (uris.length === 1) {
                  const filePath = uris[0]
                  this.prepareDownloadDialogControllerProgress.open()
                  const version = await getDsmApiMaxVersion('', 'SYNO.FileStation.Download')
                  this.prepareDownloadDialogControllerProgress.close()
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
                    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                    const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
                    netBoost.setSceneDesc({
                      scene: 'download',
                      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                    })
                    const accountInfo = await get()
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
                              fileStream.writeSync(incomingData)
                              this.transferredSize = this.transferredSize + incomingData.byteLength
                              try {
                                await notificationManager.publish({
                                  content: {
                                    notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                                    systemLiveView: {
                                      typeCode: 8,
                                      title: '正在下载文件：' + item.name,
                                      text: '进度：' + Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 +
                                        '% (' + this.getSizeString(this.transferredSize) + '/' +
                                      this.getSizeString(this.totalSize) + ')'
                                    }
                                  },
                                  id: continuousTaskNotificationInfo.notificationId,
                                  notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                                  template: {
                                    name: 'downloadTemplate',
                                    data: {
                                      title: '正在下载文件，进度：' +
                                        Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 + '%',
                                      fileName: item.name,
                                      progressValue: Number((this.transferredSize / this.totalSize).toFixed(2)) * 100
                                    }
                                  }
                                })
                              } catch (err) {
                                if (err.code !== 1600009 && err.code !== 202) {
                                  promptAction.openToast({
                                    message: '发生错误，错误码：' + err.code
                                  })
                                }
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
                              if (this.transferredSize < item.additional.size * 0.99 &&
                                this.transferredSize < item.additional.size - 1) {
                                this.transferredSize = -1
                                this.totalSize = -1
                                promptAction.openToast({
                                  message: '下载失败'
                                })
                              }
                              if (this.transferredSize >= item.additional.size * 0.99 ||
                                this.transferredSize >= item.additional.size - 1) {
                                this.transferredSize = -1
                                this.totalSize = -1
                                promptAction.openToast({
                                  message: '下载成功'
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
                    backgroundTaskManager.on('continuousTaskCancel', () => {
                      session.cancel()
                      promptAction.openToast({
                        message: '下载失败'
                      })
                    })
                    this.context.eventHub.on('cancelDownload', () => {
                      session.cancel()
                    })
                    this.totalSize = item.additional.size
                    this.isShowProgressSheet = true
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
                        fileStream.closeSync()
                        await backgroundTaskManager.stopBackgroundRunning(this.context)
                        this.isShowProgressSheet = false
                        this.transferredSize = -1
                        this.totalSize = -1
                        this.context.eventHub.off('cancelDownload')
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
                      fileStream.closeSync()
                      try {
                        await backgroundTaskManager.stopBackgroundRunning(this.context)
                      } catch (err) {
                        if (err.code !== 9800005) {
                          promptAction.openToast({
                            message: '发生错误，错误码：' + err.code
                          })
                        }
                      }
                      this.isShowProgressSheet = false
                      this.transferredSize = -1
                      this.totalSize = -1
                      this.context.eventHub.off('cancelDownload')
                      if (err.code !== 1007900992) {
                        promptAction.openToast({
                          message: '下载失败，错误码：' + err.code
                        })
                      }
                    }
                  }
                }
              } catch (err) {
                promptAction.openToast({
                  message: '发生错误，错误码：' + err.code
                })
              }
            })
        }
        MenuItem({
          startIcon: $r('app.media.share'),
          content: '分享'
        })
          .onClick(async () => {
            const dialogControllerProgress = new CustomDialogController({
              builder: LoadingDialog({
                content: '获取分享链接...'
              })
            })
            dialogControllerProgress.open()
            const res = await dsmRequest('', 'SYNO.FileStation.Sharing',
              '&method=create&path=' + encodeURIComponent(JSON.stringify([item.path])))
            dialogControllerProgress.close()
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
        if (this.dirnames.length > 0) {
          MenuItem({
            startIcon: $r('app.media.copy'),
            content: '复制'
          })
            .onClick(() => {
              this.copyMovePath = item.path
              this.remove = false
            })
          MenuItem({
            startIcon: $r('app.media.move'),
            content: '移动'
          })
            .onClick(() => {
              this.copyMovePath = item.path
              this.remove = true
            })
        }
        if (this.dirnames.length > 0) {
          MenuItem({
            startIcon: $r('app.media.rename'),
            content: '重命名'
          })
            .onClick(() => {
              this.editPath = item.path
              this.editName = item.name
              this.isShowRenamefileSheet = true
            })
        }
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
              this.deleteDialogControllerProgress.open()
              const startres =
                await dsmRequest('', 'SYNO.FileStation.Delete', '&method=start&path=' + encodeURIComponent(item.path))
              if (startres !== 'fail') {
                const taskId = startres['taskid'] as string
                const statusres = await dsmRequest('', 'SYNO.FileStation.Delete', '&method=status&taskid=' + taskId)
                if (statusres !== 'fail') {
                  this.deleteDialogControllerProgress.close()
                  promptAction.openToast({
                    message: '删除成功'
                  })
                  this.loading = true
                  return
                }
                promptAction.openToast({
                  message: '删除任务提交成功但尚未完成，请稍等'
                })
                this.loading = true
              }
              this.deleteDialogControllerProgress.close()
            }
          })
      }
    }
  }

  build() {
    Refresh({
      refreshing: $$this.loading
    }) {
      Scroll() {
        Column() {
          if (!this.isLogin) {
            Text('未登录账号')
              .height('100%')
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          if (this.isLogin) {
            if (this.multipleSelect) {
              Row() {
                Column() {
                  Image($r('app.media.cancel'))
                }
                .backgroundColor($r('sys.color.interactive_hover'))
                .borderRadius(20)
                .height(40)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .padding(11)
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .onClick(() => {
                  this.multipleSelect = false
                  this.multipleSelectArray = []
                })

                Text('已选择 ' + this.multipleSelectArray.length + ' 项')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                Blank()
                Column() {
                  Image($r('app.media.copy'))
                }
                .backgroundColor($r('sys.color.interactive_hover'))
                .borderRadius(20)
                .height(40)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .padding(11)
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .onClick(async () => {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '复制中...'
                    })
                  })
                  dialogControllerProgress.open()
                  const startres = await dsmRequest('', 'SYNO.FileStation.CopyMove',
                    '&method=start&path=' + encodeURIComponent(JSON.stringify(this.multipleSelectArray)) +
                      '&dest_folder_path=' + encodeURIComponent(this.getPath()) + '&remove_src=false')
                  if (startres !== 'fail') {
                    const taskId = startres['taskid'] as string
                    const statusres =
                      await dsmRequest('', 'SYNO.FileStation.CopyMove', '&method=status&taskid=' + taskId)
                    if (statusres !== 'fail') {
                      dialogControllerProgress.close()
                      promptAction.openToast({
                        message: '复制成功'
                      })
                      this.multipleSelect = false
                      this.multipleSelectArray = []
                      this.loading = true
                      return
                    }
                    promptAction.openToast({
                      message: '复制任务提交成功但尚未完成，请稍等'
                    })
                    this.multipleSelect = false
                    this.multipleSelectArray = []
                    this.loading = true
                  }
                  dialogControllerProgress.close()
                  this.multipleSelect = false
                  this.multipleSelectArray = []
                  this.loading = true
                })

                Column() {
                  Image($r('app.media.move'))
                }
                .backgroundColor($r('sys.color.interactive_hover'))
                .borderRadius(20)
                .height(40)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .padding(11)
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .onClick(async () => {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '移动中...'
                    })
                  })
                  dialogControllerProgress.open()
                  const startres = await dsmRequest('', 'SYNO.FileStation.CopyMove',
                    '&method=start&path=' + encodeURIComponent(JSON.stringify(this.multipleSelectArray)) +
                      '&dest_folder_path=' + encodeURIComponent(this.getPath()) + '&remove_src=true')
                  if (startres !== 'fail') {
                    const taskId = startres['taskid'] as string
                    const statusres =
                      await dsmRequest('', 'SYNO.FileStation.CopyMove', '&method=status&taskid=' + taskId)
                    if (statusres !== 'fail') {
                      dialogControllerProgress.close()
                      promptAction.openToast({
                        message: '移动成功'
                      })
                      this.multipleSelect = false
                      this.multipleSelectArray = []
                      this.loading = true
                      return
                    }
                    promptAction.openToast({
                      message: '移动任务提交成功但尚未完成，请稍等'
                    })
                    this.multipleSelect = false
                    this.multipleSelectArray = []
                    this.loading = true
                  }
                  dialogControllerProgress.close()
                  this.multipleSelect = false
                  this.multipleSelectArray = []
                  this.loading = true
                })

                Column() {
                  Image($r('app.media.delete'))
                }
                .backgroundColor($r('sys.color.interactive_hover'))
                .borderRadius(20)
                .height(40)
                .padding(11)
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
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
                    this.deleteDialogControllerProgress.open()
                    const startres = await dsmRequest('', 'SYNO.FileStation.Delete',
                      '&method=start&path=' + encodeURIComponent(JSON.stringify(this.multipleSelectArray)))
                    if (startres !== 'fail') {
                      const taskId = startres['taskid'] as string
                      const statusres =
                        await dsmRequest('', 'SYNO.FileStation.Delete', '&method=status&taskid=' + taskId)
                      if (statusres !== 'fail') {
                        this.deleteDialogControllerProgress.close()
                        promptAction.openToast({
                          message: '删除成功'
                        })
                        this.multipleSelect = false
                        this.multipleSelectArray = []
                        this.loading = true
                        return
                      }
                      promptAction.openToast({
                        message: '删除任务提交成功但尚未完成，请稍等'
                      })
                      this.loading = true
                    }
                    this.deleteDialogControllerProgress.close()
                    this.multipleSelect = false
                    this.multipleSelectArray = []
                    this.loading = true
                  }
                })
              }
              .margin({
                bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            Row() {
              if (this.dirnames.length > 0) {
                Column() {
                  Image($r('app.media.back'))
                }
                .backgroundColor($r('sys.color.interactive_hover'))
                .borderRadius(20)
                .height(40)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .padding(11)
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .onClick(() => {
                  this.dirnames.pop()
                  this.dirnamesDataPreferences.putSync('dirnames', this.dirnames)
                  this.loading = true
                })
              }
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
                    this.loading = true
                  })
                Select([
                  { value: '正序' },
                  { value: '倒序' }
                ])
                  .selected(this.sortDirectionIndex!!)
                  .value(this.sortDirectionValue!!)
                  .onSelect(() => {
                    this.loading = true
                  })
              }
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .width('100%')

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
                      this.dirnamesDataPreferences.putSync('dirnames', this.dirnames)
                      this.loading = true
                    })
                  Span(' / ')
                }
                Span(item + ' ')
                  .fontColor($r('sys.color.font_emphasize'))
                  .onClick(() => {
                    this.dirnames = this.dirnames.slice(0, index + 1)
                    this.dirnamesDataPreferences.putSync('dirnames', this.dirnames)
                    this.loading = true
                  })
              })
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .bindSheet(this.isShowPlayerSheet!!, this.PlayerSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: this.srcName
              },
              onDisappear: () => {
                this.src = ''
                this.srcName = ''
              }
            })

            if (this.dirnames.length > 0) {
              Search({
                placeholder: '请输入搜索关键词',
                value: this.searchKeyword!!
              })
                .searchButton('搜索')
                .onSubmit(() => {
                  this.search()
                })
            }
            if (this.dirnames.length > 0) {
              Row() {
                Column() {
                  Image($r('app.media.newfolder'))
                }
                .backgroundColor($r('sys.color.interactive_hover'))
                .borderRadius(20)
                .height(40)
                .padding(11)
                .visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType: hdsEffect.PointLightSourceType.SOFT,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                  })
                  .buildEffect())
                .width(40)
                .onClick(() => {
                  this.editPath = this.getPath()
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
                  }
                })

                if (this.copyMovePath) {
                  Blank()
                  Column() {
                    Image($r('app.media.close'))
                  }
                  .backgroundColor($r('sys.color.interactive_hover'))
                  .borderRadius(20)
                  .height(40)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .padding(11)
                  .visualEffect(new hdsEffect.HdsEffectBuilder()
                    .pointLight({
                      sourceType: hdsEffect.PointLightSourceType.SOFT,
                      illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                    })
                    .buildEffect())
                  .width(40)
                  .onClick(() => {
                    this.copyMovePath = ''
                    this.remove = false
                  })

                  Column() {
                    Image($r('app.media.confirm'))
                  }
                  .backgroundColor($r('sys.color.interactive_hover'))
                  .borderRadius(20)
                  .height(40)
                  .padding(11)
                  .visualEffect(new hdsEffect.HdsEffectBuilder()
                    .pointLight({
                      sourceType: hdsEffect.PointLightSourceType.SOFT,
                      illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                    })
                    .buildEffect())
                  .width(40)
                  .onClick(async () => {
                    let text = ''
                    if (!this.remove) {
                      text = '复制'
                    }
                    if (this.remove) {
                      text = '移动'
                    }
                    const dialogControllerProgress = new CustomDialogController({
                      builder: LoadingDialog({
                        content: text + '中...'
                      })
                    })
                    dialogControllerProgress.open()
                    const startres = await dsmRequest('', 'SYNO.FileStation.CopyMove',
                      '&method=start&path=' + encodeURIComponent(JSON.stringify([this.copyMovePath])) +
                        '&dest_folder_path=' + encodeURIComponent(this.getPath()) + '&remove_src' + this.remove)
                    if (startres !== 'fail') {
                      const taskId = startres['taskid'] as string
                      const statusres =
                        await dsmRequest('', 'SYNO.FileStation.CopyMove', '&method=status&taskid=' + taskId)
                      if (statusres !== 'fail') {
                        dialogControllerProgress.close()
                        promptAction.openToast({
                          message: text + '成功'
                        })
                        this.copyMovePath = ''
                        this.remove = false
                        this.loading = true
                        return
                      }
                      promptAction.openToast({
                        message: text + '任务提交成功但尚未完成，请稍等'
                      })
                      this.copyMovePath = ''
                      this.remove = false
                      this.loading = true
                    }
                    dialogControllerProgress.close()
                  })
                }
              }
              .margin({
                bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            List() {
              ForEach(this.fileArray, (item: FileItem, index) => {
                ListItem() {
                  Column() {
                    if (index !== 0) {
                      Divider()
                        .padding({
                          left: 6,
                          right: 6
                        })
                    }
                    Row() {
                      Row() {
                        if (this.multipleSelect && this.dirnames.length > 0) {
                          Toggle({
                            type: ToggleType.Checkbox,
                            isOn: this.multipleSelectArray.some(selectItem => selectItem === item.path)
                          })
                            .margin({
                              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                            })
                            .onChange((isOn) => {
                              if (!isOn) {
                                this.multipleSelectArray.splice(this.multipleSelectArray.findIndex(selectItem => selectItem ===
                                item.path), 1)
                              }
                              if (isOn) {
                                this.multipleSelectArray.push(item.path)
                              }
                            })
                        }
                        if (!item.isdir) {
                          Image(this.getFileTypeIcon(item.name))
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
                      }
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })

                      Image($r('app.media.right'))
                        .fillColor($r('sys.color.icon_fourth'))
                        .height(12)
                        .width(12)
                    }
                    .borderRadius(12)
                    .justifyContent(FlexAlign.SpaceBetween)
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
                        let houzhui = ''
                        const lastDotIndex = item.name.lastIndexOf('.')
                        if (lastDotIndex !== -1) {
                          houzhui = item.name.slice(lastDotIndex + 1)
                        }
                        const supportedformats = ['mp4', 'mkv', 'm4a', 'aac', 'mp3', 'ogg', 'wav', 'flac', 'amr', 'ape']
                        if (supportedformats.includes(houzhui)) {
                          const dialogControllerProgress = new CustomDialogController({
                            builder: LoadingDialog({
                              content: '播放准备中...'
                            })
                          })
                          dialogControllerProgress.open()
                          const res = await dsmRequest('', 'SYNO.API.Auth.Key',
                            '&method=grant&allow_api=SYNO.FileStation.Download&allow_methods=["download"]')
                          dialogControllerProgress.close()
                          if (res !== 'fail') {
                            const tid = res['tid'] as string
                            const accountInfo = await get()
                            const textEncoder = new util.TextEncoder()
                            const bytes = textEncoder.encodeInto(item.path)
                            const dlink = Array.from(bytes).map(byte => byte.toString(16).padStart(2, '0')).join('')
                            this.src =
                              accountInfo.path + '/fbdownload/' +
                              item.name.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') +
                                '?tid=' + tid + '&mode=open&dlink=' + dlink
                            this.srcName = item.name
                            this.isShowPlayerSheet = true
                          }
                          return
                        }
                        if (item.additional.size > Math.pow(1024, 3)) {
                          promptAction.openToast({
                            message: '大小大于 1GB，请长按将其下载到本地后预览'
                          })
                          return
                        }
                        if (getCurrentNetworkBearerType() === 0) {
                          const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                            name: 'commonSetting'
                          })
                          const cellularDataUseRemind =
                            commonSettingDataPreferences.getSync('cellularDataUseRemind', 0)
                          if (cellularDataUseRemind === 0 ||
                            (cellularDataUseRemind === 1 && item.additional.size > 200 * Math.pow(1024, 2))) {
                            const promptAction = this.getUIContext().getPromptAction()
                            const data = await promptAction.showDialog({
                              title: '流量使用提醒',
                              message: '当前正在使用流量上网，下载此文件将消耗约 ' +
                              this.getSizeString(item.additional.size) +
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
                          const previewDir = this.context.tempDir + '/preview'
                          if (!fileIo.accessSync(previewDir)) {
                            fileIo.mkdirSync(previewDir)
                          }
                          const filePath = previewDir + '/' + item.name
                          this.prepareDownloadDialogControllerProgress.open()
                          const version = await getDsmApiMaxVersion('', 'SYNO.FileStation.Download')
                          this.prepareDownloadDialogControllerProgress.close()
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
                              await backgroundTaskManager.startBackgroundRunning(this.context, ['dataTransfer'],
                                wandAgent)
                            const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                            const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
                            netBoost.setSceneDesc({
                              scene: 'download',
                              sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                            })
                            const accountInfo = await get()
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
                                      fileStream.writeSync(incomingData)
                                      this.transferredSize = this.transferredSize + incomingData.byteLength
                                      try {
                                        await notificationManager.publish({
                                          content: {
                                            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                                            systemLiveView: {
                                              typeCode: 8,
                                              title: '正在下载文件：' + item.name,
                                              text: '进度：' +
                                                Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 +
                                                '% (' + this.getSizeString(this.transferredSize) + '/' +
                                              this.getSizeString(this.totalSize) + ')'
                                            }
                                          },
                                          id: continuousTaskNotificationInfo.notificationId,
                                          notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                                          template: {
                                            name: 'downloadTemplate',
                                            data: {
                                              title: '正在下载文件，进度：' +
                                                Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 + '%',
                                              fileName: item.name,
                                              progressValue: Number((this.transferredSize /
                                              this.totalSize).toFixed(2)) *
                                                100
                                            }
                                          }
                                        })
                                      } catch (err) {
                                        if (err.code !== 1600009 && err.code !== 202) {
                                          promptAction.openToast({
                                            message: '发生错误，错误码：' + err.code
                                          })
                                        }
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
                                      if (this.transferredSize < item.additional.size * 0.99 &&
                                        this.transferredSize < item.additional.size - 1) {
                                        this.transferredSize = -1
                                        this.totalSize = -1
                                        promptAction.openToast({
                                          message: '下载失败'
                                        })
                                      }
                                      if (this.transferredSize >= item.additional.size * 0.99 ||
                                        this.transferredSize >= item.additional.size - 1) {
                                        this.transferredSize = -1
                                        this.totalSize = -1
                                        const uri = fileUri.getUriFromPath(filePath)
                                        const canPreview = await filePreview.canPreview(this.context, uri)
                                        if (!canPreview) {
                                          promptAction.openToast({
                                            message: '此类型不支持预览'
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
                                }
                              },
                              cookies: {
                                id: accountInfo.sid,
                                did: accountInfo.did
                              }
                            })
                            backgroundTaskManager.on('continuousTaskCancel', () => {
                              session.cancel()
                              promptAction.openToast({
                                message: '下载失败'
                              })
                            })
                            this.context.eventHub.on('cancelDownload', () => {
                              session.cancel()
                            })
                            this.totalSize = item.additional.size
                            this.isShowProgressSheet = true
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
                                fileStream.closeSync()
                                await backgroundTaskManager.stopBackgroundRunning(this.context)
                                this.isShowProgressSheet = false
                                this.transferredSize = -1
                                this.totalSize = -1
                                this.context.eventHub.off('cancelDownload')
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
                              fileStream.closeSync()
                              try {
                                await backgroundTaskManager.stopBackgroundRunning(this.context)
                              } catch (err) {
                                if (err.code !== 9800005) {
                                  promptAction.openToast({
                                    message: '发生错误，错误码：' + err.code
                                  })
                                }
                              }
                              this.isShowProgressSheet = false
                              this.transferredSize = -1
                              this.totalSize = -1
                              this.context.eventHub.off('cancelDownload')
                              if (err.code !== 1007900992) {
                                promptAction.openToast({
                                  message: '下载失败，错误码：' + err.code
                                })
                              }
                            }
                          }
                        } catch (err) {
                          promptAction.openToast({
                            message: '发生错误，错误码：' + err.code
                          })
                        }
                      }
                      if (item.isdir) {
                        this.dirnames.push(item.name)
                        this.dirnamesDataPreferences.putSync('dirnames', this.dirnames)
                        this.loading = true
                      }
                    })
                    .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress | ResponseType.RightClick, {
                      hapticFeedbackMode: HapticFeedbackMode.AUTO
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
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                }
              })
            }
            .layoutWeight(1)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .height('100%')
      }
      .padding({
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
      .onAppear(() => {
        const currentOrientation = display.getDefaultDisplaySync().orientation
        if (currentOrientation === display.Orientation.PORTRAIT ||
          currentOrientation === display.Orientation.PORTRAIT_INVERTED) {
          this.preferType = 0
        }
        if (currentOrientation === display.Orientation.LANDSCAPE ||
          currentOrientation === display.Orientation.LANDSCAPE_INVERTED) {
          this.preferType = 1
        }
        display.on('change', (displayId) => {
          const orientation = display.getDisplayByIdSync(displayId).orientation
          if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
            this.preferType = 0
          }
          if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
            this.preferType = 1
          }
        })
        this.context.eventHub.on('refreshFilelist', () => {
          this.loading = true
        })
        this.context.eventHub.on('back', () => {
          this.dirnames.pop()
          this.dirnamesDataPreferences.putSync('dirnames', this.dirnames)
          this.loading = true
        })
        this.loading = true
      })
      .onDisAppear(() => {
        this.context.eventHub.off('refreshFilelist')
        this.context.eventHub.off('back')
        display.off('change')
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
        }
      })
    }
    .onRefreshing(async () => {
      await this.get()
      this.loading = false
    })
  }
}