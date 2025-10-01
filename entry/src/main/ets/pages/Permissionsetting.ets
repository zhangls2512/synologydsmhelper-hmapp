import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { getPermission } from '../common/Permission'

@Builder
export function PermissionsettingBuilder() {
  Permissionsetting()
}

@ComponentV2
struct Permissionsetting {
  @Local writePasteBoard: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  dataSync = getPermission('ohos.permission.DISTRIBUTED_DATASYNC')
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
                Text('设备发现和连接')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.dataSync
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

            Text() {
              Span($r('app.string.DISTRIBUTED_DATASYNC_reason'))
                .fontColor($r('sys.color.font_secondary'))
              Span('请前往')
                .fontColor($r('sys.color.font_secondary'))
              Span('系统设置')
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  this.context.startAbility({
                    bundleName: 'com.huawei.hmos.settings',
                    abilityName: 'com.huawei.hmos.settings.MainAbility',
                    uri: 'application_info_entry',
                    parameters: {
                      pushParams: 'com.zhangxm.aipasswordmemo'
                    }
                  })
                })
              Span('管理此权限。')
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