import { common } from '@kit.AbilityKit'
import { sendablePreferences } from '@kit.ArkData'
import { taskpool } from '@kit.ArkTS'
import { display } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import {
  hdsMaterial,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsSideMenu,
  HdsSideMenuMainItem,
  HdsTabs,
  HdsTabsController
} from '@kit.UIDesignKit'
import { AccountInfo, importAccounts } from '../common/Account'
import { getCurrentNetworkBearerType } from '../common/Network'
import { getFlushPreference, getTempPreference } from '../common/Preference'
import { getPreferType } from '../common/Prefertype'
import { download, upload } from '../common/Transfertask'
import Accountlist from './Accountlist'
import Album from './Album'
import Cardlist from './Cardlist'
import Cleardata from './Cleardata'
import Filelist from './Filelist'
import Me from './Me'
import Notice from './Notice'
import Uploaderrorlog from './Uploaderrorlog'

export interface TransferTaskItem {
  id: string,
  path: string,
  name: string,
  transferredSize: number,
  totalSize: number,
  status: string,
  errCode: number,
  type: string,
  accountInfo: AccountInfo,
  srcFileUri: string,
  backupTaskId: string
}

@Entry
@ComponentV2
struct Index {
  @Provider() isShowAccountlistSheet: boolean = false
  @Provider() isShowUploaderrorlogSheet: boolean = false
  @Local errorType: string = ''
  @Local errorObject: string = ''
  @Local backgroundImagePixelMap: PixelMap | undefined = undefined
  @Local preferType: number = 1
  @Local index: number = 0
  @Local showAlbum: boolean = false
  @Local isShowCleardataSheet: boolean = false
  @Local isShowNoticeSheet: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  controller = new HdsTabsController()
  intervalId = -1

  onBackPress() {
    if (this.index === 1) {
      const filelist = getTempPreference(this.context, 'back', 'filelist', false)
      if (!filelist) {
        return false
      } else {
        this.context.eventHub.emit('backFilelist')
        return true
      }
    } else {
      if (this.index === 2 && this.showAlbum) {
        const album = getTempPreference(this.context, 'back', 'album', false)
        if (!album) {
          return false
        } else {
          this.context.eventHub.emit('backAlbum')
          return true
        }
      }
      return false
    }
  }

  async get() {
    this.backgroundImagePixelMap = await this.getBackgroundImage()
    const oldShowAlbum = this.showAlbum
    this.showAlbum = getFlushPreference(this.context, 'commonSetting', 'showAlbum', true) as boolean
    setTimeout(() => {
      if (oldShowAlbum !== this.showAlbum) {
        if (!oldShowAlbum) {
          this.controller.changeIndex(3)
        }
        if (oldShowAlbum) {
          this.controller.changeIndex(2)
        }
      }
    }, 100)
  }

  isSelected(index: number) {
    if (this.index === 0 || this.index === 1 || this.showAlbum) {
      return this.index === index
    } else {
      return this.index === index - 1
    }
  }

  async getBackgroundImage() {
    const backgroundImagePath = this.context.filesDir + '/media/backgroundimage.png'
    const res = fileIo.accessSync(backgroundImagePath)
    if (res) {
      const backgroundImageSource = image.createImageSource(backgroundImagePath)
      const backgroundImagePixelMap = await backgroundImageSource.createPixelMap()
      return backgroundImagePixelMap
    }
    return
  }

  @Builder
  tabBuilder(index: number, image: Resource, title: string) {
    Column() {
      Image(image)
        .fillColor(this.isSelected(index) ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_secondary'))
        .height(24)
        .width(24)
      Text(title)
        .fontColor(this.isSelected(index) ? $r('sys.color.font_emphasize') : '')
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .margin({
          top: 4
        })
    }
  }

  @Builder
  CleardataSheetBuilder() {
    Cleardata()
  }

  @Builder
  NoticeSheetBuilder() {
    Notice()
  }

  @Builder
  AccountlistSheetBuilder() {
    Accountlist()
  }

  @Builder
  UploaderrorlogSheetBuilder() {
    Uploaderrorlog({
      errorType: this.errorType,
      errorObject: this.errorObject
    })
  }

  build() {
    Column() {
      if (deviceInfo.deviceType !== '2in1') {
        HdsTabs({
          controller: this.controller
        }) {
          TabContent() {
            HdsNavigation() {
              Cardlist()
                .padding({
                  top: 56
                })
            }
            .hideBackButton(true)
            .mode(NavigationMode.Stack)
            .padding({
              top: 36
            })
            .recoverable(true)
            .titleBar({
              content: {
                title: {
                  mainTitle: '卡片'
                }
              }
            })
            .titleMode(HdsNavigationTitleMode.MINI)
          }
          .tabBar(this.tabBuilder(0, $r('app.media.card'), '卡片'))
          .bindSheet(this.isShowAccountlistSheet!!, this.AccountlistSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            showClose: false
          })

          TabContent() {
            HdsNavigation() {
              Filelist()
                .padding({
                  top: 56
                })
            }
            .hideBackButton(true)
            .mode(NavigationMode.Stack)
            .padding({
              top: 36
            })
            .recoverable(true)
            .titleBar({
              content: {
                title: {
                  mainTitle: '文件'
                }
              }
            })
            .titleMode(HdsNavigationTitleMode.MINI)
          }
          .tabBar(this.tabBuilder(1, $r('app.media.file'), '文件'))
          .bindSheet(this.isShowNoticeSheet!!, this.NoticeSheetBuilder(), {
            preferType: this.preferType,
            title: {
              title: '消息通知'
            }
          })

          if (this.showAlbum) {
            TabContent() {
              HdsNavigation() {
                Album()
                  .padding({
                    top: 56
                  })
              }
              .hideBackButton(true)
              .mode(NavigationMode.Stack)
              .padding({
                top: 36
              })
              .recoverable(true)
              .titleBar({
                content: {
                  title: {
                    mainTitle: '相册'
                  }
                }
              })
              .titleMode(HdsNavigationTitleMode.MINI)
            }
            .tabBar(this.tabBuilder(2, $r('app.media.album'), '相册'))
          }
          TabContent() {
            HdsNavigation() {
              Me()
            }
            .hideBackButton(true)
            .mode(NavigationMode.Stack)
            .padding({
              top: 36
            })
            .recoverable(true)
            .titleBar({
              content: {
                title: {
                  mainTitle: '我的'
                }
              }
            })
            .titleMode(HdsNavigationTitleMode.MINI)
          }
          .tabBar(this.tabBuilder(3, $r('app.media.me'), '我的'))
        }
        .barBackgroundBlurStyle(BlurStyle.Regular)
        .barFloatingStyle({
          barBottomMargin: 24,
          adaptToHandedness: true,
          thermoCtrl: true,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .barOverlap(true)
        .barPosition(BarPosition.End)
        .barWidth(this.showAlbum ? 320 : 240)
        .scrollable(false)
        .vertical(this.preferType === 0 ? false : true)
        .onChange(index => {
          this.index = index
        })
        .onAnimationStart((index, targetIndex) => {
          if (targetIndex === 0) {
            this.context.eventHub.emit('refreshCardlist')
          }
          if (targetIndex === 1) {
            this.context.eventHub.emit('refreshFilelist')
          }
          if (!this.showAlbum) {
            if (targetIndex === 2) {
              this.context.eventHub.emit('refreshMe')
            }
          }
          if (this.showAlbum) {
            if (targetIndex === 2) {
              this.context.eventHub.emit('refreshAlbum')
            }
            if (targetIndex === 3) {
              this.context.eventHub.emit('refreshMe')
            }
          }
        })
        .bindSheet(this.isShowUploaderrorlogSheet!!, this.UploaderrorlogSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '上传故障日志'
          }
        })
      }
      if (deviceInfo.deviceType === '2in1') {
        Row() {
          if (!this.showAlbum) {
            HdsSideMenu({
              items: [
                new HdsSideMenuMainItem({
                  icon: $r('app.media.card_tab'),
                  label: '卡片'
                }),
                new HdsSideMenuMainItem({
                  icon: $r('app.media.file_tab'),
                  label: '文件'
                }),
                new HdsSideMenuMainItem({
                  icon: $r('app.media.me_tab'),
                  label: '我的'
                })
              ],
              selectedIndex: 0,
              $selectedIndex: (index) => {
                this.index = index
                if (index === 0) {
                  this.context.eventHub.emit('refreshCardlist')
                }
                if (index === 1) {
                  this.context.eventHub.emit('refreshFilelist')
                }
                if (index === 2) {
                  this.context.eventHub.emit('refreshMe')
                }
              }
            })
              .padding({
                top: $r('sys.float.ohos_id_default_padding_top')
              })
              .width(240)
              .bindSheet(this.isShowNoticeSheet!!, this.NoticeSheetBuilder(), {
                preferType: this.preferType,
                title: {
                  title: '消息通知'
                }
              })
          }
          if (this.showAlbum) {
            HdsSideMenu({
              items: [
                new HdsSideMenuMainItem({
                  icon: $r('app.media.card_tab'),
                  label: '卡片'
                }),
                new HdsSideMenuMainItem({
                  icon: $r('app.media.file_tab'),
                  label: '文件'
                }),
                new HdsSideMenuMainItem({
                  icon: $r('app.media.album_tab'),
                  label: '相册'
                }),
                new HdsSideMenuMainItem({
                  icon: $r('app.media.me_tab'),
                  label: '我的'
                })
              ],
              selectedIndex: 0,
              $selectedIndex: (index) => {
                this.index = index
                if (index === 0) {
                  this.context.eventHub.emit('refreshCardlist')
                }
                if (index === 1) {
                  this.context.eventHub.emit('refreshFilelist')
                }
                if (index === 2) {
                  this.context.eventHub.emit('refreshAlbum')
                }
                if (index === 3) {
                  this.context.eventHub.emit('refreshMe')
                }
              }
            })
              .padding({
                top: $r('sys.float.ohos_id_default_padding_top')
              })
              .width(240)
              .bindSheet(this.isShowNoticeSheet!!, this.NoticeSheetBuilder(), {
                preferType: this.preferType,
                title: {
                  title: '消息通知'
                }
              })
          }
          Divider()
            .vertical(true)
            .bindSheet(this.isShowAccountlistSheet!!, this.AccountlistSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              showClose: false
            })
          if (this.index === 0) {
            Cardlist()
              .layoutWeight(1)
          }
          if (this.index === 1) {
            Filelist()
              .layoutWeight(1)
          }
          if (this.index === 2) {
            if (!this.showAlbum) {
              Me()
                .layoutWeight(1)
            }
            if (this.showAlbum) {
              Album()
                .layoutWeight(1)
            }
          }
          if (this.index === 3) {
            Me()
              .layoutWeight(1)
          }
        }
        .alignItems(VerticalAlign.Top)
        .bindSheet(this.isShowUploaderrorlogSheet!!, this.UploaderrorlogSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '上传故障日志'
          }
        })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.background_secondary'))
    .backgroundImage(this.backgroundImagePixelMap)
    .backgroundImageSize(ImageSize.FILL)
    .onAppear(async () => {
      this.intervalId = setInterval(async () => {
        const transferTaskArray: TransferTaskItem[] = []
        const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(this.context, {
          name: 'transferTask'
        })
        const transferTaskObject = transferTaskDataPreferences.getAllSync() as object
        const transferTaskIdArray = Object.keys(transferTaskObject)
        transferTaskIdArray.forEach(item => {
          const transferTaskString = transferTaskObject[item] as string
          const transferTask = JSON.parse(transferTaskString) as TransferTaskItem
          transferTaskArray.push(transferTask)
        })
        if (!transferTaskArray.find(item => item.status === 'processing')) {
          const pendingTransferTaskArray = transferTaskArray.filter(item => item.status === 'pending')
          for (let i = 0; i < pendingTransferTaskArray.length; i++) {
            const item = pendingTransferTaskArray[i]
            let exec = true
            if (getCurrentNetworkBearerType() === 0) {
              const cellularDataUseRemind =
                getFlushPreference(this.context, 'commonSetting', 'cellularDataUseRemind', 0)
              if (cellularDataUseRemind === 0 ||
                (cellularDataUseRemind === 1 && item.totalSize > 200 * Math.pow(1024, 2))) {
                exec = false
              }
            }
            if (exec) {
              item.status = 'processing'
              transferTaskDataPreferences.putSync(item.id, JSON.stringify(item))
              if (item.type === 'download') {
                const task = new taskpool.LongTask(download, this.context, item.id)
                await taskpool.execute(task)
              }
              if (item.type === 'upload') {
                const task = new taskpool.LongTask(upload, this.context, item.id)
                await taskpool.execute(task)
              }
            }
          }
        }
      }, 1000)
      this.context.eventHub.on('clearData', () => {
        if (!this.isShowCleardataSheet) {
          this.isShowCleardataSheet = true
        }
      })
      this.context.eventHub.on('notice', () => {
        if (!this.isShowNoticeSheet) {
          this.isShowNoticeSheet = true
        }
      })
      this.context.eventHub.on('accountList', () => {
        if (!this.isShowAccountlistSheet) {
          this.isShowAccountlistSheet = true
        }
      })
      this.context.eventHub.on('card', async () => {
        if (deviceInfo.deviceType !== '2in1') {
          this.controller.changeIndex(0)
          this.context.eventHub.emit('refreshCardlist')
        }
        if (deviceInfo.deviceType === '2in1') {
          await promptAction.showDialog({
            title: '提示',
            message: '暂不支持',
            buttons: [
              {
                text: '确定',
                color: $r('sys.color.font_emphasize')
              }
            ]
          })
        }
      })
      this.context.eventHub.on('file', async () => {
        if (deviceInfo.deviceType !== '2in1') {
          this.controller.changeIndex(1)
          this.context.eventHub.emit('refreshFilelist')
        }
        if (deviceInfo.deviceType === '2in1') {
          await promptAction.showDialog({
            title: '提示',
            message: '暂不支持',
            buttons: [
              {
                text: '确定',
                color: $r('sys.color.font_emphasize')
              }
            ]
          })
        }
      })
      this.context.eventHub.on('album', async () => {
        if (deviceInfo.deviceType !== '2in1' && this.showAlbum) {
          this.controller.changeIndex(2)
          this.context.eventHub.emit('refreshAlbum')
        }
        if (deviceInfo.deviceType === '2in1') {
          await promptAction.showDialog({
            title: '提示',
            message: '暂不支持',
            buttons: [
              {
                text: '确定',
                color: $r('sys.color.font_emphasize')
              }
            ]
          })
        }
      })
      this.context.eventHub.on('me', async () => {
        if (deviceInfo.deviceType !== '2in1') {
          if (!this.showAlbum) {
            this.controller.changeIndex(2)
            this.context.eventHub.emit('refreshMe')
          }
          if (this.showAlbum) {
            this.controller.changeIndex(3)
            this.context.eventHub.emit('refreshMe')
          }
        }
        if (deviceInfo.deviceType === '2in1') {
          await promptAction.showDialog({
            title: '提示',
            message: '暂不支持',
            buttons: [
              {
                text: '确定',
                color: $r('sys.color.font_emphasize')
              }
            ]
          })
        }
      })
      this.context.eventHub.on('wantUri', async (wantUri: string) => {
        await importAccounts(this.context, wantUri)
      })
      const promptAction = this.UIContext.getPromptAction()
      this.context.eventHub.on('dialog', async (title: string, message: string) => {
        await promptAction.showDialog({
          title: title,
          message: message,
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      })
      this.context.eventHub.on('uploadErrorLog', (errorType: string, errorObject: string) => {
        this.errorType = errorType
        this.errorObject = errorObject
        this.isShowUploaderrorlogSheet = true
      })
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      this.context.eventHub.on('refreshIndex', async () => {
        await this.get()
      })
      this.showAlbum = getFlushPreference(this.context, 'commonSetting', 'showAlbum', true) as boolean
      await this.get()
    })
    .onDisAppear(() => {
      if (this.intervalId !== -1) {
        clearInterval(this.intervalId)
      }
      this.context.eventHub.off('refreshIndex')
      this.context.eventHub.off('uploadErrorLog')
      this.context.eventHub.off('dialog')
      this.context.eventHub.off('wantUri')
      this.context.eventHub.off('me')
      this.context.eventHub.off('album')
      this.context.eventHub.off('file')
      this.context.eventHub.off('card')
      this.context.eventHub.off('accountList')
      this.context.eventHub.off('notice')
      this.context.eventHub.off('clearData')
      display.off('change')
    })
    .bindSheet(this.isShowCleardataSheet!!, this.CleardataSheetBuilder(), {
      preferType: this.preferType
    })
  }
}