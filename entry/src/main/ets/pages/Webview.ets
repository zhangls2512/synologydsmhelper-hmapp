import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'

@Builder
export function WebviewBuilder() {
  Webview()
}

@ComponentV2
struct Webview {
  @Local url: string = ''
  @Local darkMode: number = 0
  @Local optimizeParserBudget: boolean = false
  @Local title: string = ''
  context = this.getUIContext().getHostContext()
  controller = new webview.WebviewController()
  debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'debugSetting'
  })

  build() {
    NavDestination() {
      Web({
        src: this.url,
        controller: this.controller
      })
        .darkMode(this.darkMode)
        .enableDataDetector(true)
        .enableFollowSystemFontWeight(true)
        .enableNativeEmbedMode(true)
        .geolocationAccess(false)
        .mixedMode(MixedMode.None)
        .optimizeParserBudget(this.optimizeParserBudget)
        .pinchSmooth(true)
        .onControllerAttached(() => {
          this.controller.enableAdsBlock(true)
          this.controller.enableIntelligentTrackingPrevention(true)
          this.controller.setErrorPageEnabled(true)
          this.controller.loadUrl(this.url)
        })
        .onErrorReceive((event) => {
          promptAction.openToast({
            message: '发生错误，错误码：' + event.error.getErrorCode() + '，错误信息：' + event.error.getErrorInfo()
          })
        })
        .onTitleReceive((event) => {
          this.title = event.title
        })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title(this.title)
    .onReady((context) => {
      this.url = context.pathInfo.param as string
      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
        name: 'commonSetting'
      })
      const colorMode = commonSettingDataPreferences.getSync('colorMode', 0)
      if (colorMode === 0) {
        this.darkMode = 2
      }
      if (colorMode === 1) {
        this.darkMode = 0
      }
      if (colorMode === 2) {
        this.darkMode = 1
      }
      this.optimizeParserBudget = this.debugSettingDataPreferences.getSync('optimizeParserBudget', true) as boolean
      const destroyMode = this.debugSettingDataPreferences.getSync('destroyMode', 0) as number
      webview.WebviewController.setWebDestroyMode(destroyMode)
    })
  }
}