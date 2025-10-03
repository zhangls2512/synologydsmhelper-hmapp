import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import Login from './Login'
import Setting from './Setting'

@ComponentV2
export default struct Me {
  @Provider() isShowLoginSheet: boolean = false
  @Local isShowSettingSheet: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1

  @Builder
  LoginSheetBuilder() {
    Login()
  }

  @Builder
  SettingSheetBuilder() {
    Setting()
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.foreground'))
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(40)
            Text('登录')
              .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
              .fontWeight(FontWeight.Bold)
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onClick(() => {
            this.isShowLoginSheet = true
          })
          .bindSheet(this.isShowLoginSheet!!, this.LoginSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '登录'
            },
            onAppear: (async () => {
              const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                name: 'commonSetting'
              })
              const disallowScreenshot = commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
              if (disallowScreenshot) {
                const lastWindow = await window.getLastWindow(this.context)
                await lastWindow.setWindowPrivacyMode(true)
              }
            }),
            onDisappear: (async () => {
              const lastWindow = await window.getLastWindow(this.context)
              await lastWindow.setWindowPrivacyMode(false)
            })
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }

      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.setting'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('设置')
              .fontWeight(FontWeight.Medium)
            Blank()
            Image($r('app.media.right'))
              .fillColor($r('sys.color.icon_fourth'))
              .height(12)
              .width(12)
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onClick(() => {
            this.isShowSettingSheet = true
          })
          .bindSheet(this.isShowSettingSheet!!, this.SettingSheetBuilder(), {
            preferType: this.preferType
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      if (deviceInfo.deviceType === 'phone') {
        this.preferType = 0
      }
      this.context.eventHub.on('refreshMe', () => {
      })
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshMe')
    })
  }
}