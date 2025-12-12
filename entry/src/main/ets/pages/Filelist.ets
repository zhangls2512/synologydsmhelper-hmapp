import { common, wantAgent, wantConstant } from '@kit.AbilityKit'
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
import { getAccountInfo, getLoginStatus } from '../common/Account'
import { getDnsServer } from '../common/Dnsserver'
import { getCurrentNetworkBearerType } from '../common/Network'
import getPreferType from '../common/Prefertype'
import { dsmRequest, getDsmApiMaxVersion } from '../common/Request'
import { getSizeString, getTimeString } from '../common/Stringformat'
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
  @Provider() transferredSize: number = 0
  @Provider() totalSize: number = 0
  @Local preferType: number = 1
  @Local loading: boolean = false
  @Local fileArray: FileItem[] = []
  @Local dirnames: string[] = []
  @Local isLogin: boolean = false
  @Local sortByIndex: number = 2
  @Local sortByValue: string = '类型'
  @Local sortDirectionIndex: number = 0
  @Local sortDirectionValue: string = '正序'
  @Local searchKeyword: string = ''
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: FileItem[] = []
  @Local src: string = ''
  @Local copyMovePath: string = ''
  @Local editPath: string = ''
  @Local editName: string = ''
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  account = ''
  remove = false
  srcName = ''
  backDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'back'
  })
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })
  debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'debugSetting'
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
    if (houzhui === '.') {
      houzhui = '.aaa'
    }
    const fileType = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(houzhui)
    return fileManagerService.getFileIconSync(fileType)
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
    if (!this.isLogin) {
      this.account = ''
    }
    if (this.isLogin) {
      const accountInfo = await getAccountInfo()
      const account = accountInfo.path + '\0' + accountInfo.name
      if (this.account !== account) {
        this.dirnames = []
      }
      this.account = account
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
        const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.List',
          '&method=list_share&additional=["size","time"]&sort_by=' + sortBy + '&sort_direction=' + sortDirection)
        if (res !== 'fail') {
          this.fileArray = res['shares']
        }
      }
      if (path) {
        const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.List',
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
    const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.Search',
      '&method=start&folder_path=' + encodeURIComponent(JSON.stringify([this.getPath()])) + '&pattern=' +
      encodeURIComponent(this.searchKeyword))
    if (res !== 'fail') {
      const taskId = res['taskid'] as string
      await this.searchByTaskId(taskId)
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
    const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.Search',
      '&method=list&additional=["size","time"]&taskid=' + taskId + '&sort_by=' + sortBy + '&sort_direction=' +
        sortDirection)
    if (res !== 'fail') {
      const finished = res['finished'] as boolean
      if (!finished) {
        await this.searchByTaskId(taskId)
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
    Newfolder({
      editPath: this.editPath
    })
  }

  @Builder
  PlayerSheetBuilder() {
    Player({
      src: this.src
    })
  }

  @Builder
  ProgressSheetBuilder() {
    Progress()
  }

  @Builder
  RenamefileSheetBuilder() {
    Renamefile({
      editPath: this.editPath,
      editName: this.editName
    })
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
              this.multipleSelectArray.push(item)
            })
        }
        if (!item.isdir) {
          MenuItem({
            startIcon: $r('app.media.download'),
            content: '下载'
          })
            .onClick(async () => {
              if (getCurrentNetworkBearerType() === 0) {
                const cellularDataUseRemind = this.commonSettingDataPreferences.getSync('cellularDataUseRemind', 0)
                if (cellularDataUseRemind === 0 ||
                  (cellularDataUseRemind === 1 && item.additional.size > 200 * Math.pow(1024, 2))) {
                  const promptAction = this.UIContext.getPromptAction()
                  const data = await promptAction.showDialog({
                    title: '流量使用提醒',
                    message: '当前正在使用流量上网，下载此文件将消耗约 ' + getSizeString(item.additional.size) +
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
                  const lastDotIndex = item.name.lastIndexOf('.')
                  if (lastDotIndex !== -1) {
                    documentSaveOptions.newFileNames = [item.name.substring(0, lastDotIndex)]
                    documentSaveOptions.fileSuffixChoices = ['.' + item.name.substring(lastDotIndex + 1)]
                  }
                  if (lastDotIndex === -1) {
                    documentSaveOptions.newFileNames = [item.name]
                    documentSaveOptions.fileSuffixChoices = ['']
                  }
                }
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                if (uris.length === 1) {
                  let filePath = ''
                  if (!selectFileDownloadPath) {
                    filePath = new fileUri.FileUri(uris[0] + '/' + item.name).path
                  }
                  if (selectFileDownloadPath) {
                    filePath = uris[0]
                  }
                  this.prepareDownloadDialogControllerProgress.open()
                  const version = await getDsmApiMaxVersion(this.context, '', 'SYNO.FileStation.Download')
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
                                      title: '正在下载文件：' + item.name,
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
                                      fileName: item.name,
                                      progressValue: Number((this.transferredSize / this.totalSize).toFixed(2)) * 100
                                    }
                                  }
                                })
                              } catch (err) {
                                if (err.code !== 1600009 && err.code !== 202) {
                                  await promptAction.openToast({
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
                              if (this.transferredSize < item.additional.size - 1) {
                                this.transferredSize = 0
                                this.totalSize = 0
                                await promptAction.openToast({
                                  message: '下载失败'
                                })
                              }
                              if (this.transferredSize >= item.additional.size - 1) {
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
                        referer: accountInfo.path
                      },
                      cookies: {
                        id: accountInfo.sid,
                        did: accountInfo.did
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
                    this.totalSize = item.additional.size
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
                      } catch (err) {
                        if (err.code !== 9800005) {
                          await promptAction.openToast({
                            message: '发生错误，错误码：' + err.code
                          })
                        }
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
            const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.Sharing',
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
              await shareController.show(this.context, {})
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
                      this.loading = true
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
          if (this.multipleSelect) {
            Row() {
              Column() {
                Image($r('app.media.cancel'))
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
                this.multipleSelect = false
                this.multipleSelectArray = []
              })

              Text('已选择 ' + this.multipleSelectArray.length + ' 项')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Column() {
                Image($r('app.media.download'))
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
              .onClick(async () => {
                const transferTaskDataPreferences = preferences.getPreferencesSync(this.context, {
                  name: 'transferTask'
                })
                const array = this.multipleSelectArray.filter(item => !item.isdir)
                for (let i = 0; i < array.length; i++) {
                  const item = array[i]
                  const id = util.generateRandomUUID()
                  const accountInfo = await getAccountInfo()
                  transferTaskDataPreferences.putSync(id, JSON.stringify({
                    id: id,
                    path: item.path,
                    name: item.name,
                    transferredSize: 0,
                    totalSize: item.additional.size,
                    status: 'pending',
                    errCode: 0,
                    type: 'download',
                    accountPath: accountInfo.path,
                    accountSid: accountInfo.sid,
                    accountDid: accountInfo.did
                  }))
                }
                await promptAction.openToast({
                  message: array.length + ' 项传输任务已添加'
                })
                this.multipleSelect = false
                this.multipleSelectArray = []
              })

              Column() {
                Image($r('app.media.copy'))
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
              .onClick(async () => {
                const prepareDialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '复制准备中...'
                  })
                })
                prepareDialogControllerProgress.open()
                const startres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.CopyMove',
                  '&method=start&path=' +
                  encodeURIComponent(JSON.stringify(this.multipleSelectArray.map(item => item.path))) +
                    '&dest_folder_path=' + encodeURIComponent(this.getPath()) + '&remove_src=false')
                prepareDialogControllerProgress.close()
                const length = this.multipleSelectArray.length
                this.multipleSelect = false
                this.multipleSelectArray = []
                if (startres !== 'fail') {
                  const taskId = startres['taskid'] as string
                  await promptAction.openToast({
                    message: '正在复制文件，可在系统通知栏查看进度'
                  })
                  let finished = false
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
                  while (!finished) {
                    const statusres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.CopyMove',
                      '&method=status&taskid=' + taskId)
                    if (statusres !== 'fail') {
                      const transferredSize = statusres['processed_size'] as number
                      const totalSize = statusres['total'] as number
                      try {
                        await notificationManager.publish({
                          content: {
                            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                            systemLiveView: {
                              typeCode: 8,
                              title: '正在复制文件',
                              text: '进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 + '% (' +
                              getSizeString(transferredSize) + '/' + getSizeString(totalSize) + ')'
                            }
                          },
                          id: continuousTaskNotificationInfo.notificationId,
                          notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                          template: {
                            name: 'downloadTemplate',
                            data: {
                              title: '正在复制文件，进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 +
                                '%',
                              fileName: length + ' 个文件',
                              progressValue: Number((transferredSize / totalSize).toFixed(2)) * 100
                            }
                          }
                        })
                      } catch (err) {
                        if (err.code !== 1600009 && err.code !== 202) {
                          await promptAction.openToast({
                            message: '发生错误，错误码：' + err.code
                          })
                        }
                      }
                      if (statusres['finished']) {
                        finished = true
                        await backgroundTaskManager.stopBackgroundRunning(this.context)
                        await promptAction.openToast({
                          message: '复制成功'
                        })
                        this.loading = true
                      }
                    }
                    if (statusres === 'fail') {
                      finished = true
                    }
                  }
                }
              })

              Column() {
                Image($r('app.media.move'))
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
              .onClick(async () => {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '移动中...'
                  })
                })
                dialogControllerProgress.open()
                const startres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.CopyMove',
                  '&method=start&path=' +
                  encodeURIComponent(JSON.stringify(this.multipleSelectArray.map(item => item.path))) +
                    '&dest_folder_path=' + encodeURIComponent(this.getPath()) + '&remove_src=true')
                this.multipleSelect = false
                this.multipleSelectArray = []
                if (startres !== 'fail') {
                  const taskId = startres['taskid'] as string
                  let finished = false
                  while (!finished) {
                    const statusres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.CopyMove',
                      '&method=status&taskid=' + taskId)
                    if (statusres !== 'fail') {
                      if (statusres['finished']) {
                        finished = true
                        await promptAction.openToast({
                          message: '移动成功'
                        })
                        this.loading = true
                      }
                    }
                    if (statusres === 'fail') {
                      finished = true
                    }
                  }
                }
                dialogControllerProgress.close()
              })

              Column() {
                Image($r('app.media.delete'))
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
                    '&method=start&path=' +
                    encodeURIComponent(JSON.stringify(this.multipleSelectArray.map(item => item.path))))
                  this.multipleSelect = false
                  this.multipleSelectArray = []
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
                          this.loading = true
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
                this.dirnames.pop()
                this.backDataPreferences.putSync('filelist', this.dirnames.length === 0 ? false : true)
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
                    this.backDataPreferences.putSync('filelist', false)
                    this.loading = true
                  })
                Span(' / ')
              }
              Span(item + ' ')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                  this.dirnames = this.dirnames.slice(0, index + 1)
                  this.backDataPreferences.putSync('filelist', this.dirnames.length === 0 ? false : true)
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
              .onSubmit(async () => {
                await this.search()
              })
          }
          if (this.dirnames.length > 0) {
            Row() {
              Column() {
                Image($r('app.media.newfolder'))
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
                  this.copyMovePath = ''
                  this.remove = false
                })

                Column() {
                  Image($r('app.media.confirm'))
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
                .onClick(async () => {
                  let text = ''
                  if (!this.remove) {
                    text = '复制'
                  }
                  if (this.remove) {
                    text = '移动'
                  }
                  const prepareDialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: text + '准备中...'
                    })
                  })
                  prepareDialogControllerProgress.open()
                  const startres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.CopyMove',
                    '&method=start&path=' + encodeURIComponent(JSON.stringify([this.copyMovePath])) +
                      '&dest_folder_path=' + encodeURIComponent(this.getPath()) + '&remove_src=' + this.remove)
                  prepareDialogControllerProgress.close()
                  const lastIndex = this.copyMovePath.lastIndexOf('/')
                  const fileName = this.copyMovePath.slice(lastIndex + 1)
                  this.copyMovePath = ''
                  this.remove = false
                  if (startres !== 'fail') {
                    const taskId = startres['taskid'] as string
                    await promptAction.openToast({
                      message: '正在' + text + '文件，可在系统通知栏查看进度'
                    })
                    let finished = false
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
                    while (!finished) {
                      const statusres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.CopyMove',
                        '&method=status&taskid=' + taskId)
                      if (statusres !== 'fail') {
                        const transferredSize = statusres['processed_size'] as number
                        const totalSize = statusres['total'] as number
                        try {
                          await notificationManager.publish({
                            content: {
                              notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                              systemLiveView: {
                                typeCode: 8,
                                title: '正在' + text + '文件',
                                text: '进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 + '% (' +
                                getSizeString(transferredSize) + '/' + getSizeString(totalSize) + ')'
                              }
                            },
                            id: continuousTaskNotificationInfo.notificationId,
                            notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                            template: {
                              name: 'downloadTemplate',
                              data: {
                                title: '正在' + text + '文件，进度：' +
                                  Number((transferredSize / totalSize).toFixed(2)) * 100 + '%',
                                fileName: fileName,
                                progressValue: Number((transferredSize / totalSize).toFixed(2)) * 100
                              }
                            }
                          })
                        } catch (err) {
                          if (err.code !== 1600009 && err.code !== 202) {
                            await promptAction.openToast({
                              message: '发生错误，错误码：' + err.code
                            })
                          }
                        }
                        if (statusres['finished']) {
                          finished = true
                          await backgroundTaskManager.stopBackgroundRunning(this.context)
                          await promptAction.openToast({
                            message: text + '成功'
                          })
                          this.loading = true
                        }
                      }
                      if (statusres === 'fail') {
                        finished = true
                      }
                    }
                  }
                })
              }
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('100%')
          }
          Refresh({
            refreshing: $$this.loading
          }) {
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
                      if (this.multipleSelect && this.dirnames.length > 0) {
                        Toggle({
                          type: ToggleType.Checkbox,
                          isOn: this.multipleSelectArray.some(selectItem => selectItem.path === item.path)
                        })
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                          .onChange((isOn) => {
                            if (!isOn) {
                              this.multipleSelectArray.splice(this.multipleSelectArray.findIndex(selectItem => selectItem.path ===
                              item.path), 1)
                            }
                            if (isOn) {
                              this.multipleSelectArray.push(item)
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
                          Span(getTimeString(item.additional.time.mtime))
                          if (item.additional.size && !item.isdir) {
                            Span(' - ' + getSizeString(item.additional.size))
                          }
                        }
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .margin({
                          top: $r('sys.float.ohos_id_text_margin_vertical')
                        })
                      }
                      .alignItems(HorizontalAlign.Start)
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
                    .padding({
                      bottom: 12,
                      left: 6,
                      right: 5,
                      top: 12
                    })
                    .stateStyles({
                      normal: {
                        .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                          $r('sys.color.background_secondary'))
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
                        this.hoverId = index
                      }
                    })
                    .onClick(async () => {
                      if (!item.isdir) {
                        let houzhui = ''
                        const lastDotIndex = item.name.lastIndexOf('.')
                        if (lastDotIndex !== -1) {
                          houzhui = item.name.slice(lastDotIndex + 1)
                        }
                        const supportedformats = ['mp4', 'mkv', 'm4a', 'aac', 'mp3', 'ogg', 'wav', 'flac', 'amr', 'ape']
                        if (supportedformats.includes(houzhui) &&
                        this.commonSettingDataPreferences.getSync('onlinePreviewMedia', true)) {
                          const dialogControllerProgress = new CustomDialogController({
                            builder: LoadingDialog({
                              content: '播放准备中...'
                            })
                          })
                          dialogControllerProgress.open()
                          const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.API.Auth.Key',
                            '&method=grant&allow_api=SYNO.FileStation.Download&allow_methods=["download"]')
                          dialogControllerProgress.close()
                          if (res !== 'fail') {
                            const tid = res['tid'] as string
                            const accountInfo = await getAccountInfo()
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
                          await promptAction.openToast({
                            message: '大小大于 1GB，请长按将其下载到本地后预览'
                          })
                          return
                        }
                        if (getCurrentNetworkBearerType() === 0) {
                          const cellularDataUseRemind =
                            this.commonSettingDataPreferences.getSync('cellularDataUseRemind', 0)
                          if (cellularDataUseRemind === 0 ||
                            (cellularDataUseRemind === 1 && item.additional.size > 200 * Math.pow(1024, 2))) {
                            const promptAction = this.UIContext.getPromptAction()
                            const data = await promptAction.showDialog({
                              title: '流量使用提醒',
                              message: '当前正在使用流量上网，下载此文件将消耗约 ' +
                              getSizeString(item.additional.size) + ' 流量，确定下载？',
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
                            await fileIo.mkdir(previewDir)
                          }
                          const filePath = previewDir + '/' + item.name
                          this.prepareDownloadDialogControllerProgress.open()
                          const version = await getDsmApiMaxVersion(this.context, '', 'SYNO.FileStation.Download')
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
                                              title: '正在下载文件：' + item.name,
                                              text: '进度：' +
                                                Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 +
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
                                              fileName: item.name,
                                              progressValue: Number((this.transferredSize /
                                              this.totalSize).toFixed(2)) *
                                                100
                                            }
                                          }
                                        })
                                      } catch (err) {
                                        if (err.code !== 1600009 && err.code !== 202) {
                                          await promptAction.openToast({
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
                                      if (this.transferredSize < item.additional.size - 1) {
                                        this.transferredSize = 0
                                        this.totalSize = 0
                                        await promptAction.openToast({
                                          message: '下载失败'
                                        })
                                        await fileIo.unlink(filePath)
                                      }
                                      if (this.transferredSize >= item.additional.size - 1) {
                                        this.transferredSize = 0
                                        this.totalSize = 0
                                        const uri = fileUri.getUriFromPath(filePath)
                                        const filePreviewType =
                                          this.commonSettingDataPreferences.getSync('filePreviewType', 0)
                                        if (filePreviewType === 0) {
                                          const canPreview = await filePreview.canPreview(this.context, uri)
                                          if (!canPreview) {
                                            await promptAction.openToast({
                                              message: '此类型不支持预览'
                                            })
                                          }
                                          if (canPreview) {
                                            await filePreview.openPreview(this.context, {
                                              title: item.name,
                                              uri: uri,
                                              mimeType: ''
                                            })
                                          }
                                        }
                                        if (filePreviewType === 1) {
                                          await this.context.startAbility({
                                            action: 'ohos.want.action.viewData',
                                            uri: uri,
                                            parameters: {
                                              'ohos.ability.params.showDefaultPicker': true
                                            },
                                            flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
                                          })
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
                                referer: accountInfo.path
                              },
                              cookies: {
                                id: accountInfo.sid,
                                did: accountInfo.did
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
                            this.totalSize = item.additional.size
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
                                await fileIo.unlink(filePath)
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
                              await fileIo.unlink(filePath)
                              try {
                                await backgroundTaskManager.stopBackgroundRunning(this.context)
                              } catch (err) {
                                if (err.code !== 9800005) {
                                  await promptAction.openToast({
                                    message: '发生错误，错误码：' + err.code
                                  })
                                }
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
                        } catch (err) {
                          await promptAction.openToast({
                            message: '发生错误，错误码：' + err.code
                          })
                        }
                      }
                      if (item.isdir) {
                        this.dirnames.push(item.name)
                        this.backDataPreferences.putSync('filelist', true)
                        this.loading = true
                      }
                    })
                    .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress, {
                      hapticFeedbackMode: HapticFeedbackMode.AUTO
                    })
                    .bindContextMenu(this.MenuBuilder(item), ResponseType.RightClick)
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
          }
          .layoutWeight(1)
          .onRefreshing(async () => {
            await this.get()
            this.loading = false
          })
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
      this.context.eventHub.on('backFilelist', () => {
        this.dirnames.pop()
        this.backDataPreferences.putSync('filelist', this.dirnames.length === 0 ? false : true)
        this.loading = true
      })
      this.context.eventHub.on('refreshFilelist', async () => {
        await this.get()
      })
      await this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshFilelist')
      this.context.eventHub.off('backFilelist')
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
}