import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { taskpool } from '@kit.ArkTS'
import { display } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { importAccounts } from '../common/Account'
import { getCurrentNetworkBearerType } from '../common/Network'
import getPreferType from '../common/Prefertype'
import { download } from '../common/Transfertask'
import Cardlist from './Cardlist'
import Filelist from './Filelist'
import Album from './Album'
import Me from './Me'
import Cleardata from './Cleardata'
import Accountlist from './Accountlist'

export interface TransferTaskItem {
  id: string,
  path: string,
  name: string,
  transferredSize: number,
  totalSize: number,
  status: string,
  errCode: number,
  type: string,
  accountPath: string,
  accountSid: string,
  accountDid: string
}

@Entry
@ComponentV2
struct Index {
  @Provider() isShowAccountlistSheet: boolean = false
  @Local backgroundImagePixelMap: PixelMap | undefined = undefined
  @Local preferType: number = 1
  @Local index: number = 0
  @Local title: string = '首页'
  @Local showAlbum: boolean = false
  @Local isShowCleardataSheet: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  backDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'back'
  })
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  onBackPress() {
    if (this.index === 1) {
      const filelist = this.backDataPreferences.getSync('filelist', false)
      if (!filelist) {
        return false
      } else {
        this.context.eventHub.emit('backFilelist')
        return true
      }
    } else {
      if (this.index === 2 && this.showAlbum) {
        const album = this.backDataPreferences.getSync('album', false)
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

  get() {
    this.backgroundImagePixelMap = this.getBackgroundImage()
    const oldShowAlbum = this.showAlbum
    this.showAlbum = this.commonSettingDataPreferences.getSync('showAlbum', true) as boolean
    if (oldShowAlbum !== this.showAlbum) {
      if (!oldShowAlbum) {
        if (this.index === 2) {
          this.index = 3
        }
      }
      if (oldShowAlbum) {
        if (this.index === 2) {
          this.index = 0
        }
        if (this.index === 3) {
          this.index = 2
        }
      }
    }
  }

  isSelected(index: number) {
    if (this.index === 0 || this.index === 1 || this.showAlbum) {
      return this.index === index
    } else {
      return this.index === index - 1
    }
  }

  getBackgroundImage() {
    const backgroundImagePath = this.context.filesDir + '/media/backgroundimage.png'
    const res = fileIo.accessSync(backgroundImagePath)
    if (res) {
      const backgroundImageSource = image.createImageSource(backgroundImagePath)
      return backgroundImageSource.createPixelMapSync()
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
  AccountlistSheetBuilder() {
    Accountlist()
  }

  build() {
    Column() {
      if (this.preferType === 0) {
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_l'),
            left: $r('sys.float.ohos_id_elements_margin_horizontal_l')
          })
      }
      Tabs({
        index: $$this.index
      }) {
        TabContent() {
          Cardlist()
            .height('100%')
        }
        .tabBar(this.tabBuilder(0, $r('app.media.card'), '卡片'))
        .bindSheet(this.isShowAccountlistSheet!!, this.AccountlistSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          showClose: false
        })

        TabContent() {
          Filelist()
        }
        .tabBar(this.tabBuilder(1, $r('app.media.file'), '文件'))

        if (this.showAlbum) {
          TabContent() {
            Album()
          }
          .tabBar(this.tabBuilder(2, $r('app.media.album'), '相册'))
        }
        TabContent() {
          Me()
            .height('100%')
        }
        .tabBar(this.tabBuilder(3, $r('app.media.me'), '我的'))
      }
      .barBackgroundBlurStyle(BlurStyle.Regular)
      .barPosition(this.preferType === 0 ? BarPosition.End : BarPosition.Start)
      .scrollable(false)
      .vertical(this.preferType === 0 ? false : true)
      .onAnimationStart((index, targetIndex) => {
        if (targetIndex === 0) {
          this.title = '卡片'
          this.context.eventHub.emit('refreshCardlist')
        }
        if (targetIndex === 1) {
          this.title = '文件'
          this.context.eventHub.emit('refreshFilelist')
        }
        if (!this.showAlbum) {
          if (targetIndex === 2) {
            this.title = '我的'
            this.context.eventHub.emit('refreshMe')
          }
        }
        if (this.showAlbum) {
          if (targetIndex === 2) {
            this.title = '相册'
            this.context.eventHub.emit('refreshAlbum')
          }
          if (targetIndex === 3) {
            this.title = '我的'
            this.context.eventHub.emit('refreshMe')
          }
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.background_secondary'))
    .backgroundImage(this.backgroundImagePixelMap)
    .backgroundImageSize(ImageSize.FILL)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({
      bottom: this.preferType === 0 ? 36 : 0,
      top: this.preferType === 0 ? 12 : 0
    })
    .onAppear(() => {
      this.context.eventHub.on('clearData', () => {
        if (!this.isShowCleardataSheet) {
          this.isShowCleardataSheet = true
        }
      })
      this.context.eventHub.on('accountList', () => {
        if (!this.isShowAccountlistSheet) {
          this.isShowAccountlistSheet = true
        }
      })
      this.context.eventHub.on('wantUri', async (wantUri: string) => {
        await importAccounts(this.context, this.UIContext, wantUri)
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
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      const currentIndex = this.index
      this.index = -1
      this.index = currentIndex
      this.context.eventHub.on('refreshIndex', () => {
        this.get()
      })
      this.get()
      setInterval(async () => {
        const transferTaskArray: TransferTaskItem[] = []
        const transferTaskDataPreferences = preferences.getPreferencesSync(this.context, {
          name: 'transferTask'
        })
        const transferTaskObject = transferTaskDataPreferences.getAllSync() as object
        const transferTaskIdArray = Object.keys(transferTaskObject)
        for (let i = 0; i < transferTaskIdArray.length; i++) {
          const transferTaskString = transferTaskObject[transferTaskIdArray[i]] as string
          const transferTask = JSON.parse(transferTaskString) as TransferTaskItem
          transferTaskArray.push(transferTask)
        }
        if (!transferTaskArray.find(item => item.status === 'processing')) {
          const pendingTransferTaskArray = transferTaskArray.filter(item => item.status === 'pending')
          for (let i = 0; i < pendingTransferTaskArray.length; i++) {
            const item = pendingTransferTaskArray[i]
            let exec = true
            if (getCurrentNetworkBearerType() === 0) {
              const cellularDataUseRemind = this.commonSettingDataPreferences.getSync('cellularDataUseRemind', 0)
              if (cellularDataUseRemind === 0 ||
                (cellularDataUseRemind === 1 && item.totalSize > 200 * Math.pow(1024, 2))) {
                exec = false
              }
            }
            if (exec) {
              item.status = 'processing'
              transferTaskDataPreferences.putSync(item.id, JSON.stringify(item))
              const task = new taskpool.LongTask(download, this.context, item.id)
              await taskpool.execute(task)
              return
            }
          }
        }
      }, 1000)
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshIndex')
      this.context.eventHub.off('dialog')
      this.context.eventHub.off('wantUri')
      this.context.eventHub.off('accountList')
      this.context.eventHub.off('clearData')
      display.off('change')
    })
    .bindSheet(this.isShowCleardataSheet!!, this.CleardataSheetBuilder(), {
      preferType: this.preferType,
      title: {
        title: '清理数据'
      }
    })
  }
}