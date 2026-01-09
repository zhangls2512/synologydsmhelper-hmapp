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
  @Local darkMode: WebDarkMode = WebDarkMode.Auto
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
        controller: this.controller,
        incognitoMode: true
      })
        .darkMode(this.darkMode)
        .enableDataDetector(true)
        .enableNativeEmbedMode(true)
        .geolocationAccess(false)
        .nestedScroll({
          scrollForward: NestedScrollMode.SELF_ONLY,
          scrollBackward: NestedScrollMode.SELF_ONLY
        })
        .optimizeParserBudget(this.optimizeParserBudget)
        .pinchSmooth(true)
        .onControllerAttached(() => {
          this.controller.enableAdsBlock(true)
          this.controller.enableIntelligentTrackingPrevention(true)
          this.controller.enableSafeBrowsing(true)
          this.controller.setErrorPageEnabled(true)
          this.controller.loadUrl(this.url)
        })
        .onErrorReceive(async (event) => {
          await promptAction.openToast({
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
        this.darkMode = WebDarkMode.Auto
      }
      if (colorMode === 1) {
        this.darkMode = WebDarkMode.Off
      }
      if (colorMode === 2) {
        this.darkMode = WebDarkMode.On
      }
      this.optimizeParserBudget = this.debugSettingDataPreferences.getSync('optimizeParserBudget', true) as boolean
      const destroyMode = this.debugSettingDataPreferences.getSync('destroyMode',
        webview.WebDestroyMode.NORMAL_MODE) as webview.WebDestroyMode
      webview.WebviewController.setWebDestroyMode(destroyMode)
    })
  }
}