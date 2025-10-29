import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { display } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import Cardlist from './Cardlist'
import Filelist from './Filelist'
import Me from './Me'
import Cleardata from './Cleardata'

@Entry
@ComponentV2
struct Index {
  @Local backgroundImagePixelMap: PixelMap | undefined = undefined
  @Local preferType: number = 1
  @Local index: number = 0
  @Local title: string = '首页'
  @Local isShowCleardataSheet: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  onBackPress() {
    if (this.index === 1) {
      const dirnamesDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'dirnames'
      })
      const dirnames = dirnamesDataPreferences.getSync('dirnames', []) as string[]
      if (dirnames.length === 0) {
        return false
      } else {
        this.context.eventHub.emit('back')
        return true
      }
    } else {
      return false
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
        .fillColor(this.index === index ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_secondary'))
        .height(24)
        .width(24)
      Text(title)
        .fontColor(this.index === index ? $r('sys.color.font_emphasize') : '')
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

        TabContent() {
          Filelist()
            .height('100%')
        }
        .tabBar(this.tabBuilder(1, $r('app.media.file'), '文件'))

        TabContent() {
          Me()
            .height('100%')
        }
        .tabBar(this.tabBuilder(2, $r('app.media.me'), '我的'))
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
        if (targetIndex === 2) {
          this.title = '我的'
          this.context.eventHub.emit('refreshMe')
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
      const currentOrientation = display.getDefaultDisplaySync().orientation
      if (currentOrientation === display.Orientation.PORTRAIT ||
        currentOrientation === display.Orientation.PORTRAIT_INVERTED) {
        this.preferType = 0
        const currentIndex = this.index
        this.index = -1
        this.index = currentIndex
      }
      if (currentOrientation === display.Orientation.LANDSCAPE ||
        currentOrientation === display.Orientation.LANDSCAPE_INVERTED) {
        this.preferType = 1
        const currentIndex = this.index
        this.index = -1
        this.index = currentIndex
      }
      display.on('change', (displayId) => {
        const orientation = display.getDisplayByIdSync(displayId).orientation
        if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
          this.preferType = 0
          const currentIndex = this.index
          this.index = -1
          this.index = currentIndex
        }
        if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
          this.preferType = 1
          const currentIndex = this.index
          this.index = -1
          this.index = currentIndex
        }
      })
      this.context.eventHub.on('clearData', () => {
        if (!this.isShowCleardataSheet) {
          this.isShowCleardataSheet = true
        }
      })
      this.context.eventHub.on('refreshIndex', () => {
        this.backgroundImagePixelMap = this.getBackgroundImage()
      })
      this.backgroundImagePixelMap = this.getBackgroundImage()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshIndex')
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