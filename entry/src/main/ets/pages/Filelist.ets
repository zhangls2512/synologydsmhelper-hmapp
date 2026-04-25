import { common, wantAgent, wantConstant } from '@kit.AbilityKit'
import { sendablePreferences, uniformTypeDescriptor } from '@kit.ArkData'
import { fastbuffer, url, util } from '@kit.ArkTS'
import { display, LoadingDialog, promptAction } from '@kit.ArkUI'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { fileIo, fileUri, picker } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { notificationManager } from '@kit.NotificationKit'
import { filePreview } from '@kit.PreviewKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { systemShare } from '@kit.ShareKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { getAccountHash, getAccountInfo, getLoginStatus } from '../common/Account'
import { getDnsServer } from '../common/Dnsserver'
import { getFileTypeIcon } from '../common/File'
import { sha256hash } from '../common/Hash'
import { getCurrentNetworkBearerType } from '../common/Network'
import { getFlushPreference, setTempPreference } from '../common/Preference'
import { getPreferType } from '../common/Prefertype'
import { dsmRequest, getDsmApiMaxVersion } from '../common/Request'
import { getSizeString, getTimeStringFromSecond } from '../common/Stringformat'
import Newfolder from './Newfolder'
import Player from './Player'
import Progress from './Progress'
import Reader from './Reader'
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
  @Provider() isShowProgressSheet: boolean = false
  @Provider() isShowRenamefileSheet: boolean = false
  @Provider() transferredSize: number = 0
  @Provider() totalSize: number = 0
  @Local isShowPlayerSheet: boolean = false
  @Local isShowReaderSheet: boolean = false
  @Local preferType: number = 1
  @Local loading: boolean = false
  @Local fileArray: FileItem[] = []
  @Local dirnames: string[] = []
  @Local isLogin: boolean = false
  @Local sortByIndex: number = 2
  @Local sortByValue: string = '类型'
  @Local sortDirectionIndex: number = 0
  @Local sortDirectionValue: string = '升序'
  @Local searchKeyword: string = ''
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: FileItem[] = []
  @Local copyMovePath: string = ''
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  account = ''
  remove = false
  src = ''
  srcName = ''
  editPath = ''
  editName = ''
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  getPath() {
    let path = ''
    this.dirnames.forEach(item => {
      path += '/' + item
    })
    return path
  }

  async get() {
    this.searchKeyword = ''
    if (!this.isLogin) {
      this.account = ''
    }
    if (this.isLogin) {
      const accountInfo = await getAccountInfo(this.context)
      const account = getAccountHash(accountInfo)
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
      if (this.sortByValue === '修改时间') {
        sortBy = 'mtime'
      }
      let sortDirection = ''
      if (this.sortDirectionValue === '升序') {
        sortDirection = 'ASC'
      }
      if (this.sortDirectionValue === '降序') {
        sortDirection = 'DESC'
      }
      if (!path) {
        const res = await dsmRequest(this.context, '', 'SYNO.FileStation.List', new url.URLParams({
          method: 'list_share',
          additional: JSON.stringify(['size', 'time']),
          sort_by: sortBy,
          sort_direction: sortDirection
        }).toString())
        if (res !== 'fail') {
          this.fileArray = res['shares']
        }
      }
      if (path) {
        const res = await dsmRequest(this.context, '', 'SYNO.FileStation.List', new url.URLParams({
          method: 'list',
          additional: JSON.stringify(['size', 'time']),
          folder_path: path,
          sort_by: sortBy,
          sort_direction: sortDirection
        }).toString())
        this.fileArray = []
        if (res !== 'fail') {
          this.fileArray = res['files']
        }
      }
    }
  }

  async search() {
    this.dialogControllerProgress.open()
    const res = await dsmRequest(this.context, '', 'SYNO.FileStation.Search', new url.URLParams({
      method: 'start',
      folder_path: JSON.stringify([this.getPath()]),
      pattern: this.searchKeyword
    }).toString())
    if (res !== 'fail') {
      const taskId = res['taskid'] as string
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
      if (this.sortByValue === '修改时间') {
        sortBy = 'mt'
      }
      let sortDirection = ''
      if (this.sortDirectionValue === '升序') {
        sortDirection = 'ASC'
      }
      if (this.sortDirectionValue === '降序') {
        sortDirection = 'DESC'
      }
      const resb = await dsmRequest(this.context, '', 'SYNO.FileStation.Search', new url.URLParams({
        method: 'list',
        additional: JSON.stringify(['size', 'time']),
        taskid: taskId,
        sort_by: sortBy,
        sort_direction: sortDirection
      }).toString())
      if (resb !== 'fail') {
        const files = resb['files'] as FileItem[]
        if (!files) {
          await promptAction.openToast({
            message: '系统繁忙，请稍后再试'
          })
        }
        if (files) {
          this.fileArray = files
        }
      }
    }
    this.dialogControllerProgress.close()
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
  ReaderSheetBuilder() {
    Reader({
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
        MenuItem({
          startIcon: $r('app.media.multipleselect'),
          content: '多选'
        })
          .onClick(() => {
            this.multipleSelect = true
            this.multipleSelectArray.push(item)
          })
        if (!item.isdir) {
          MenuItem({
            startIcon: $r('app.media.download'),
            content: '下载'
          })
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              if (getCurrentNetworkBearerType() === 0) {
                const cellularDataUseRemind =
                  getFlushPreference(this.context, 'commonSetting', 'cellularDataUseRemind', 0)
                if (cellularDataUseRemind === 0 ||
                  (cellularDataUseRemind === 1 && item.additional.size > 200 * Math.pow(1024, 2))) {
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
              const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(this.context, {
                name: 'transferTask'
              })
              try {
                const documentSaveOptions = new picker.DocumentSaveOptions()
                const selectFileDownloadPath =
                  getFlushPreference(this.context, 'commonSetting', 'selectFileDownloadPath', false)
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
                  this.dialogControllerProgress.open()
                  const version = await getDsmApiMaxVersion(this.context, '', 'SYNO.FileStation.Download')
                  this.dialogControllerProgress.close()
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
                    const accountInfo = await getAccountInfo(this.context)
                    let lastUpdateTime = 0
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
                            onDownloadProgress: async (totalSize, transferredSize) => {
                              const currentTime = Date.now()
                              if (currentTime - lastUpdateTime >= 50) {
                                this.transferredSize = transferredSize
                                try {
                                  await notificationManager.publish({
                                    content: {
                                      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                                      systemLiveView: {
                                        typeCode: 8,
                                        title: '正在下载文件：' + item.name,
                                        text: '进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 + '% (' +
                                          getSizeString(transferredSize) + '/' + getSizeString(totalSize) + ')'
                                      }
                                    },
                                    id: continuousTaskNotificationInfo.notificationId,
                                    notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                                    template: {
                                      name: 'downloadTemplate',
                                      data: {
                                        title: '正在下载文件，进度：' +
                                          Number((transferredSize / totalSize).toFixed(2)) * 100 + '%',
                                        fileName: item.name,
                                        progressValue: Number((transferredSize / totalSize).toFixed(2)) * 100
                                      }
                                    }
                                  })
                                } catch {
                                }
                              }
                              lastUpdateTime = currentTime
                            },
                            onDataEnd: async () => {
                              this.isShowProgressSheet = false
                              session.close()
                              netBoost.setSceneDesc({
                                scene: 'download',
                                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                              })
                              fileStream.closeSync()
                              await backgroundTaskManager.stopBackgroundRunning(this.context,
                                continuousTaskNotificationInfo.continuousTaskId)
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
                            'closeRemoteValidationWhenLinkDsm',
                            'system') as 'system' | 'skip',
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
                    backgroundTaskManager.on('continuousTaskCancel', async () => {
                      session.cancel()
                    })
                    this.totalSize = item.additional.size
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
                        transferTaskDataPreferences.putSync(util.generateRandomUUID(), JSON.stringify({
                          name: item.name,
                          status: 'success',
                          type: 'download'
                        }))
                      } else {
                        await promptAction.openToast({
                          message: 'HTTP 请求失败，状态码：' + response.statusCode
                        })
                        transferTaskDataPreferences.putSync(util.generateRandomUUID(), JSON.stringify({
                          name: item.name,
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
                      await backgroundTaskManager.stopBackgroundRunning(this.context,
                        continuousTaskNotificationInfo.continuousTaskId)
                      this.context.eventHub.off('cancelDownload')
                      this.transferredSize = 0
                      this.totalSize = 0
                      if (err.code !== 1007900992) {
                        await promptAction.openToast({
                          message: '下载失败，错误码：' + err.code
                        })
                        transferTaskDataPreferences.putSync(util.generateRandomUUID(), JSON.stringify({
                          name: item.name,
                          status: 'fail',
                          errCode: err.code,
                          type: 'download'
                        }))
                      }
                      if (err.code === 1007900992) {
                        transferTaskDataPreferences.putSync(util.generateRandomUUID(), JSON.stringify({
                          name: item.name,
                          status: 'cancel',
                          type: 'download'
                        }))
                      }
                    }
                  }
                }
              } catch (err) {
                await promptAction.openToast({
                  message: '发生错误，错误码：' + err.code
                })
                transferTaskDataPreferences.putSync(util.generateRandomUUID(), JSON.stringify({
                  name: item.name,
                  status: 'fail',
                  errCode: err.code,
                  type: 'download'
                }))
              }
            })
          if (item.name.endsWith('.zip')) {
            MenuItem({
              startIcon: $r('app.media.compress'),
              content: '解压缩'
            })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                const startres = await dsmRequest(this.context, '', 'SYNO.FileStation.Extract', new url.URLParams({
                  method: 'start',
                  file_path: item.path,
                  dest_folder_path: this.getPath() + '/' + item.name.slice(0, -4),
                  create_subfolder: 'true'
                }).toString())
                if (startres !== 'fail') {
                  const taskId = startres['taskid'] as string
                  let finished = false
                  while (!finished) {
                    const statusres = await dsmRequest(this.context, '', 'SYNO.FileStation.Extract', new url.URLParams({
                      method: 'status',
                      taskid: taskId
                    }).toString())
                    if (statusres !== 'fail') {
                      if (statusres['finished']) {
                        finished = true
                        await promptAction.openToast({
                          message: '解压缩成功'
                        })
                        this.loading = true
                      }
                    }
                    if (statusres === 'fail') {
                      finished = true
                    }
                  }
                }
                this.dialogControllerProgress.close()
              })
          }
        }
        MenuItem({
          startIcon: $r('app.media.share'),
          content: '分享'
        })
          .onClick(async () => {
            this.dialogControllerProgress.open()
            const res = await dsmRequest(this.context, '', 'SYNO.FileStation.Sharing', new url.URLParams({
              method: 'create',
              path: JSON.stringify([item.path])
            }).toString())
            this.dialogControllerProgress.close()
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
                      this.loading = true
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
      }
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
                if (this.multipleSelectArray.length === 0) {
                  await promptAction.openToast({
                    message: '未选择'
                  })
                  return
                }
                const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(this.context, {
                  name: 'transferTask'
                })
                const array = this.multipleSelectArray.filter(item => !item.isdir)
                const accountInfo = await getAccountInfo(this.context)
                array.forEach(item => {
                  const id = util.generateRandomUUID()
                  transferTaskDataPreferences.putSync(id, JSON.stringify({
                    id: id,
                    path: item.path,
                    name: item.name,
                    transferredSize: 0,
                    totalSize: item.additional.size,
                    status: 'pending',
                    errCode: 0,
                    type: 'download',
                    accountInfo: accountInfo
                  }))
                })
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
                if (this.multipleSelectArray.length === 0) {
                  await promptAction.openToast({
                    message: '未选择'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const startres = await dsmRequest(this.context, '', 'SYNO.FileStation.CopyMove', new url.URLParams({
                  method: 'start',
                  path: JSON.stringify(this.multipleSelectArray.map(item => item.path)),
                  dest_folder_path: this.getPath(),
                  remove_src: 'false'
                }).toString())
                this.dialogControllerProgress.close()
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
                    const statusres =
                      await dsmRequest(this.context, '', 'SYNO.FileStation.CopyMove', new url.URLParams({
                        method: 'status',
                        taskid: taskId
                      }).toString())
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
                      } catch {
                      }
                      if (statusres['finished']) {
                        finished = true
                        await backgroundTaskManager.stopBackgroundRunning(this.context,
                          continuousTaskNotificationInfo.continuousTaskId)
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
                if (this.multipleSelectArray.length === 0) {
                  await promptAction.openToast({
                    message: '未选择'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const startres = await dsmRequest(this.context, '', 'SYNO.FileStation.CopyMove', new url.URLParams({
                  method: 'start',
                  path: JSON.stringify(this.multipleSelectArray.map(item => item.path)),
                  dest_folder_path: this.getPath(),
                  remove_src: 'true'
                }).toString())
                this.multipleSelect = false
                this.multipleSelectArray = []
                if (startres !== 'fail') {
                  const taskId = startres['taskid'] as string
                  let finished = false
                  while (!finished) {
                    const statusres =
                      await dsmRequest(this.context, '', 'SYNO.FileStation.CopyMove', new url.URLParams({
                        method: 'status',
                        taskid: taskId
                      }).toString())
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
                this.dialogControllerProgress.close()
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
                if (this.multipleSelectArray.length === 0) {
                  await promptAction.openToast({
                    message: '未选择'
                  })
                  return
                }
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
                    path: JSON.stringify(this.multipleSelectArray.map(item => item.path))
                  }).toString())
                  this.multipleSelect = false
                  this.multipleSelectArray = []
                  if (startres !== 'fail') {
                    const taskId = startres['taskid'] as string
                    let finished = false
                    while (!finished) {
                      const statusres =
                        await dsmRequest(this.context, '', 'SYNO.FileStation.Delete', new url.URLParams({
                          method: 'status',
                          taskid: taskId
                        }).toString())
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
                  this.dialogControllerProgress.close()
                }
              })
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
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
                setTempPreference(this.context, 'back', 'filelist', this.dirnames.length === 0 ? false : true)
                this.loading = true
              })
            }
            Row() {
              Select([
                { value: '名称' },
                { value: '大小' },
                { value: '类型' },
                { value: '修改时间' }
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
                { value: '升序' },
                { value: '降序' }
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
          .bindSheet(this.isShowReaderSheet!!, this.ReaderSheetBuilder(), {
            preferType: this.preferType,
            title: {
              title: this.srcName
            },
            onDisappear: () => {
              this.src = ''
              this.srcName = ''
            }
          })

          Text() {
            Span(' / ')
              .fontColor($r('sys.color.font_emphasize'))
              .onClick(() => {
                this.dirnames = []
                setTempPreference(this.context, 'back', 'filelist', false)
                this.loading = true
              })
            ForEach(this.dirnames, (item: string, index) => {
              if (index !== 0) {
                Span('/ ')
              }
              Span(item + ' ')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                  this.dirnames = this.dirnames.slice(0, index + 1)
                  setTempPreference(this.context, 'back', 'filelist', this.dirnames.length === 0 ? false : true)
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

          Search({
            placeholder: '请输入搜索关键词',
            value: this.searchKeyword!!
          })
            .searchButton('搜索')
            .onSubmit(async () => {
              await this.search()
            })
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

            if (!this.copyMovePath && !this.multipleSelect) {
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
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
              .onClick(async () => {
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select()
                if (uris.length > 0) {
                  const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(this.context, {
                    name: 'transferTask'
                  })
                  const accountInfo = await getAccountInfo(this.context)
                  uris.forEach(item => {
                    const id = util.generateRandomUUID()
                    transferTaskDataPreferences.putSync(id, JSON.stringify({
                      id: id,
                      path: this.getPath(),
                      name: new fileUri.FileUri(item).name,
                      transferredSize: 0,
                      totalSize: fileIo.statSync(item).size,
                      status: 'pending',
                      errCode: 0,
                      type: 'upload',
                      accountInfo: accountInfo,
                      srcFileUri: item
                    }))
                  })
                  await promptAction.openToast({
                    message: uris.length + ' 项传输任务已添加'
                  })
                }
              })
            }
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
                this.dialogControllerProgress.open()
                const startres = await dsmRequest(this.context, '', 'SYNO.FileStation.CopyMove', new url.URLParams({
                  method: 'start',
                  path: JSON.stringify([this.copyMovePath]),
                  dest_folder_path: this.getPath(),
                  remove_src: String(this.remove)
                }).toString())
                this.dialogControllerProgress.close()
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
                    const statusres =
                      await dsmRequest(this.context, '', 'SYNO.FileStation.CopyMove', new url.URLParams({
                        method: 'status',
                        taskid: taskId
                      }).toString())
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
                      } catch {
                      }
                      if (statusres['finished']) {
                        finished = true
                        await backgroundTaskManager.stopBackgroundRunning(this.context,
                          continuousTaskNotificationInfo.continuousTaskId)
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
            if (this.multipleSelect) {
              Blank()
              Column() {
                Image($r('app.media.compress'))
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
                await promptAction.openToast({
                  message: '敬请期待'
                })
                /*this.dialogControllerProgress.open()
                const startres = await dsmRequest(this.context, '', 'SYNO.FileStation.Compress', new url.URLParams({
                  method: 'start',
                  path: JSON.stringify(this.multipleSelectArray.map(item => item.path)),
                  dest_file_path: this.getPath() + '/' + this.dirnames[this.dirnames.length - 1] + '.zip'
                }).toString())
                this.multipleSelect = false
                this.multipleSelectArray = []
                if (startres !== 'fail') {
                  const taskId = startres['taskid'] as string
                  let finished = false
                  while (!finished) {
                    const statusres =
                      await dsmRequest(this.context, '', 'SYNO.FileStation.status', new url.URLParams({
                        method: 'status',
                        taskid: taskId
                      }).toString())
                    if (statusres !== 'fail') {
                      if (statusres['finished']) {
                        finished = true
                        await promptAction.openToast({
                          message: '压缩成功'
                        })
                        this.loading = true
                      }
                    }
                    if (statusres === 'fail') {
                      finished = true
                    }
                  }
                }
                this.dialogControllerProgress.close()*/
              })

              if (!this.fileArray.every(item => this.multipleSelectArray.find(selectItem => selectItem.path ===
                item.path))) {
                Column() {
                  Image($r('app.media.selectall'))
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
                  this.fileArray.forEach(item => {
                    if (!this.multipleSelectArray.find(selectItem => selectItem.path === item.path)) {
                      this.multipleSelectArray.push(item)
                    }
                  })
                })
              }
              if (this.fileArray.every(item => this.multipleSelectArray.find(selectItem => selectItem.path ===
                item.path))) {
                Column() {
                  Image($r('app.media.cancelselectall'))
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
                  this.fileArray.forEach(item => {
                    const index = this.multipleSelectArray.findIndex(selectItem => selectItem.path === item.path)
                    if (index !== -1) {
                      this.multipleSelectArray.splice(index, 1)
                    }
                  })
                })
              }
            }
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')

          Refresh({
            refreshing: $$this.loading
          }) {
            List() {
              if (this.fileArray.length === 0) {
                ListItem() {
                  Text('无数据')
                }
                .width('100%')
              }
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
                      if (this.multipleSelect) {
                        Toggle({
                          type: ToggleType.Checkbox,
                          isOn: this.multipleSelectArray.some(selectItem => selectItem.path === item.path)
                        })
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                          .onChange(isOn => {
                            const exist = this.multipleSelectArray.find(selectItem => selectItem.path === item.path)
                            if (!isOn && exist) {
                              this.multipleSelectArray.splice(this.multipleSelectArray.findIndex(selectItem => selectItem.path ===
                                item.path), 1)
                            }
                            if (isOn && !exist) {
                              this.multipleSelectArray.push(item)
                            }
                          })
                      }
                      if (!item.isdir) {
                        Image(getFileTypeIcon(item.name))
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
                          Span(getTimeStringFromSecond(item.additional.time.mtime))
                          if (item.additional.size >= 0) {
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
                    .onHover(isHover => {
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
                          getFlushPreference(this.context, 'commonSetting', 'onlinePreviewMedia', true)) {
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
                            const bytes = new util.TextEncoder().encodeInto(item.path)
                            const dlink = Array.from(bytes).map(byte => byte.toString(16).padStart(2, '0')).join('')
                            this.src = accountInfo.path + '/fbdownload/' +
                              item.name.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') + '?tid=' + tid +
                              '&mode=open&dlink=' + dlink
                            this.srcName = item.name
                            this.isShowPlayerSheet = true
                          }
                          return
                        }
                        const promptAction = this.UIContext.getPromptAction()
                        if (item.additional.size > Math.pow(1024, 3)) {
                          await promptAction.openToast({
                            message: '大小大于 1GB，请长按将其下载到本地后预览'
                          })
                          return
                        }
                        if (getCurrentNetworkBearerType() === 0) {
                          const cellularDataUseRemind =
                            getFlushPreference(this.context, 'commonSetting', 'cellularDataUseRemind', 0)
                          if (cellularDataUseRemind === 0 ||
                            (cellularDataUseRemind === 1 && item.additional.size > 200 * Math.pow(1024, 2))) {
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
                          const previewDir =
                            this.context.tempDir + '/preview/' + this.account + '/' + sha256hash(item.path)
                          if (!fileIo.accessSync(previewDir)) {
                            await fileIo.mkdir(previewDir, true)
                          }
                          const filePath = previewDir + '/' + item.name
                          this.dialogControllerProgress.open()
                          const version = await getDsmApiMaxVersion(this.context, '', 'SYNO.FileStation.Download')
                          this.dialogControllerProgress.close()
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
                            const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                            const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
                            netBoost.setSceneDesc({
                              scene: 'download',
                              sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                            })
                            const accountInfo = await getAccountInfo(this.context)
                            let lastUpdateTime = 0
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
                                    onDownloadProgress: async (totalSize, transferredSize) => {
                                      const currentTime = Date.now()
                                      if (currentTime - lastUpdateTime >= 50) {
                                        this.transferredSize = transferredSize
                                        try {
                                          await notificationManager.publish({
                                            content: {
                                              notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                                              systemLiveView: {
                                                typeCode: 8,
                                                title: '正在下载文件：' + item.name,
                                                text: '进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 +
                                                  '% (' + getSizeString(transferredSize) + '/' +
                                                  getSizeString(totalSize) + ')'
                                              }
                                            },
                                            id: continuousTaskNotificationInfo.notificationId,
                                            notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                                            template: {
                                              name: 'downloadTemplate',
                                              data: {
                                                title: '正在下载文件，进度：' +
                                                  Number((transferredSize / totalSize).toFixed(2)) * 100 + '%',
                                                fileName: item.name,
                                                progressValue: Number((transferredSize / totalSize).toFixed(2)) * 100
                                              }
                                            }
                                          })
                                        } catch {
                                        }
                                      }
                                      lastUpdateTime = currentTime
                                    },
                                    onDataEnd: async () => {
                                      this.isShowProgressSheet = false
                                      session.close()
                                      netBoost.setSceneDesc({
                                        scene: 'download',
                                        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                                      })
                                      fileStream.closeSync()
                                      await backgroundTaskManager.stopBackgroundRunning(this.context,
                                        continuousTaskNotificationInfo.continuousTaskId)
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
                                    'closeRemoteValidationWhenLinkDsm',
                                    'system') as 'system' | 'skip',
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
                            backgroundTaskManager.on('continuousTaskCancel', async () => {
                              session.cancel()
                            })
                            this.totalSize = item.additional.size
                            this.context.eventHub.on('cancelDownload', () => {
                              session.cancel()
                            })
                            this.isShowProgressSheet = true
                            try {
                              const response =
                                await session.get(accountInfo.path + '/webapi/entry.cgi?' + new url.URLParams({
                                  api: 'SYNO.FileStation.Download',
                                  version: String(version),
                                  method: 'download',
                                  path: item.path,
                                  mode: 'download'
                                }).toString())
                              if (response.statusCode >= 200 && response.statusCode < 300) {
                                const uri = fileUri.getUriFromPath(filePath)
                                const filePreviewType =
                                  getFlushPreference(this.context, 'commonSetting', 'filePreviewType', 0)
                                if (filePreviewType === 0) {
                                  const supportedReaderFormats = ['.epub', '.mobi', '.azw', '.azw3']
                                  if (!supportedReaderFormats.some(formatItem => item.name.endsWith(formatItem))) {
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
                                  if (supportedReaderFormats.some(formatItem => item.name.endsWith(formatItem))) {
                                    const dir = this.context.tempDir + '/preview/reader/' + this.account + '/' +
                                      sha256hash(item.name)
                                    if (!fileIo.accessSync(dir)) {
                                      await fileIo.mkdir(dir, true)
                                    }
                                    const newFilePath = dir + '/' + item.name
                                    await fileIo.moveFile(filePath, newFilePath)
                                    this.src = newFilePath
                                    this.srcName = item.name
                                    this.isShowReaderSheet = true
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
                              } else {
                                await fileIo.unlink(filePath)
                                await promptAction.openToast({
                                  message: 'HTTP 请求失败，状态码：' + response.statusCode
                                })
                              }
                            } catch (err) {
                              this.isShowProgressSheet = false
                              session.close()
                              netBoost.setSceneDesc({
                                scene: 'download',
                                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                              })
                              fileStream.closeSync()
                              await backgroundTaskManager.stopBackgroundRunning(this.context,
                                continuousTaskNotificationInfo.continuousTaskId)
                              this.context.eventHub.off('cancelDownload')
                              this.transferredSize = 0
                              this.totalSize = 0
                              await fileIo.unlink(filePath)
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
                        setTempPreference(this.context, 'back', 'filelist', true)
                        this.loading = true
                      }
                    })
                    .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress, {
                      hapticFeedbackMode: HapticFeedbackMode.AUTO
                    })
                    .bindContextMenu(this.MenuBuilder(item), ResponseType.RightClick, {
                      hapticFeedbackMode: HapticFeedbackMode.AUTO
                    })
                  }
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                }
              })
              ListItem()
                .margin({
                  bottom: this.preferType === 0 ? 80 : 0
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
        setTempPreference(this.context, 'back', 'filelist', this.dirnames.length === 0 ? false : true)
        this.loading = true
      })
      this.context.eventHub.on('refreshFilelist', async () => {
        this.multipleSelect = false
        this.multipleSelectArray = []
        this.copyMovePath = ''
        this.remove = false
        this.isLogin = await getLoginStatus(this.context)
        this.loading = true
      })
      this.isLogin = await getLoginStatus(this.context)
      this.loading = true
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