import { common } from '@kit.AbilityKit'
import { privacyManager } from '@kit.AppGalleryKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'

@Builder
export function ServicemodeBuilder() {
  Servicemode()
}

@ComponentV2
struct Servicemode {
  @Local allService: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('全量模式')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.allService!!
                })
                  .enabled(!this.allService)
                  .onChange((isOn) => {
                    this.allService = isOn
                    this.commonSettingDataPreferences.putSync('allService', isOn)
                    this.commonSettingDataPreferences.flushSync()
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text() {
              Span('全量模式下，本应用需联网，除可使用记录密码等离线功能外，还可使用账号登录、云备份、自动上传故障日志等在线功能。我们仅在您使用具体业务功能时，才会触发上述行为收集使用相关的个人信息。详情请参阅')
                .fontColor($r('sys.color.font_secondary'))
              Span('关于轩铭密码智能备忘录与隐私的声明')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  try {
                    const appPrivacyLink =
                      privacyManager.getAppPrivacyMgmtInfo().privacyInfo.find(item => item.type === 1)
                    this.pageInfos.pushPath({
                      name: 'Webview',
                      param: appPrivacyLink?.url
                    })
                  } catch (err) {
                    promptAction.openToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                })
              Span('。开启开关，即表示您知悉并同意我们向您提供本应用服务。')
                .fontColor($r('sys.color.font_secondary'))
            }
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .margin({
              top: 6,
              left: 12,
              right: 12
            })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('基本模式')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: !this.allService
                })
                  .enabled(this.allService)
                  .onChange((isOn) => {
                    this.allService = !isOn
                    this.commonSettingDataPreferences.putSync('allService', !isOn)
                    this.commonSettingDataPreferences.flushSync()
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('基本模式下，本应用无需联网，可使用记录密码等离线功能。此模式下无法使用账号登录、云备份、自动上传故障日志等在线功能。')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: 6,
                left: 12,
                right: 12
              })
          }
          .alignItems(HorizontalAlign.Start)
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
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('应用服务模式')
    .onReady((context) => {
      this.pageInfos = context.pathStack
      this.allService = this.commonSettingDataPreferences.getSync('allService', true) as boolean
    })
    .onDisAppear(() => {
      this.context.eventHub.emit('refreshSetting')
    })
  }
}