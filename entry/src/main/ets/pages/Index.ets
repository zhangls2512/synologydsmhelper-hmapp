import { common } from '@kit.AbilityKit'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import Me from './Me'
import Cleardata from './Cleardata'

@Entry
@ComponentV2
struct Index {
  @Local backgroundImagePixelMap: PixelMap | undefined = undefined
  @Local index: number = 0
  @Local title: string = '首页'
  @Local isShowCleardataSheet: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1

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
        .fillColor(this.index !== index ? $r('sys.color.icon_secondary') : $r('sys.color.icon_emphasize'))
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
      if (deviceInfo.deviceType === 'phone') {
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
          Text('首页')
            .height('100%')
        }
        .tabBar(this.tabBuilder(0, $r('app.media.icon'), '首页'))

        TabContent() {
          Me()
            .height('100%')
        }
        .tabBar(this.tabBuilder(1, $r('app.media.me'), '我的'))
      }
      .barOverlap(deviceInfo.deviceType === 'phone' ? true : false)
      .barPosition(deviceInfo.deviceType === 'phone' ? BarPosition.End : BarPosition.Start)
      .scrollable(false)
      .vertical(deviceInfo.deviceType === 'phone' ? false : true)
      .onAnimationStart((index, targetIndex) => {
        if (targetIndex === 0) {
          this.title = '首页'
          this.context.eventHub.emit('refreshIndex')
        }
        if (targetIndex === 1) {
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
      bottom: 36,
      top: 12
    })
    .onAppear(() => {
      this.context.eventHub.on('clearData', () => {
        if (!this.isShowCleardataSheet) {
          this.isShowCleardataSheet = true
        }
      })
      if (deviceInfo.deviceType === 'phone') {
        this.preferType = 0
      }
      this.backgroundImagePixelMap = this.getBackgroundImage()
      this.context.eventHub.on('refreshIndex', () => {
        this.backgroundImagePixelMap = this.getBackgroundImage()
      })
    })
    .bindSheet(this.isShowCleardataSheet!!, this.CleardataSheetBuilder(), {
      preferType: this.preferType,
      title: {
        title: '清理数据'
      }
    })
  }
}