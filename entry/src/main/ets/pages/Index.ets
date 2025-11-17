import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { display } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { importAccounts } from '../common/Account'
import { getPreferType, getPreferTypeByDisplayId } from '../common/Prefertype'
import Cardlist from './Cardlist'
import Filelist from './Filelist'
import Album from './Album'
import Me from './Me'
import Cleardata from './Cleardata'
import Accountlist from './Accountlist'

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
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })
  backDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'back'
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
    this.showAlbum = this.commonSettingDataPreferences.getSync('showAlbum', false) as boolean
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
            left: $r('sys.float.ohos_id_default_padding_start')
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
          title: {
            title: '切换账号'
          }
        })

        TabContent() {
          Filelist()
            .height('100%')
        }
        .tabBar(this.tabBuilder(1, $r('app.media.file'), '文件'))

        if (this.showAlbum) {
          TabContent() {
            Album()
              .height('100%')
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
      this.context.eventHub.on('wantUri', (wantUri: string) => {
        importAccounts(this.context, this.UIContext, wantUri)
      })
      this.preferType = getPreferType()
      display.on('change', (displayId) => {
        this.preferType = getPreferTypeByDisplayId(displayId)
      })
      const currentIndex = this.index
      this.index = -1
      this.index = currentIndex
      this.context.eventHub.on('refreshIndex', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshIndex')
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