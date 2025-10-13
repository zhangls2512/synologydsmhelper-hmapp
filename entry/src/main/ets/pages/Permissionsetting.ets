import { preferences } from '@kit.ArkData'

@Builder
export function PermissionsettingBuilder() {
  Permissionsetting()
}

@ComponentV2
struct Permissionsetting {
  @Local writePasteBoard: boolean = false
  context = this.getUIContext().getHostContext()
  permissionSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'permissionSetting'
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('系统授权')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: true
                })
                  .enabled(false)
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('系统自动开启此权限，无法手动管理。本应用使用此权限获取并根据网络、Wi-Fi等信息，使用互联网、在后台持续运行、隐私窗口、振动、窗口置顶等能力优化使用体验。通过此权限获取的信息不上传到本应用开发者服务器。')
              .enableAutoSpacing(true)
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Column() {
              Row() {
                Text('写入剪贴板')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.writePasteBoard!!
                })
                  .onChange((isOn) => {
                    this.permissionSettingDataPreferences.putSync('writePasteBoard', isOn)
                    this.permissionSettingDataPreferences.flushSync()
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text($r('app.string.WRITE_PASTEBOARD_reason'))
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
    .title('权限管理')
    .onAppear(() => {
      this.writePasteBoard = this.permissionSettingDataPreferences.getSync('writePasteBoard', false) as boolean
    })
  }
}