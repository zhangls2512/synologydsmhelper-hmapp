import { preferences } from '@kit.ArkData'

@Builder
export function DnsserverBuilder() {
  Dnsserver()
}

@ComponentV2
struct Dnsserver {
  @Local ip: string = ''
  @Local port: string = ''
  context = this.getUIContext().getHostContext()
  debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'debugSetting'
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Row() {
            Text('IP地址')
              .enableAutoSpacing(true)
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入IP地址',
              text: this.ip!!
            })
              .enableAutoSpacing(true)
              .layoutWeight(1)
              .maxLength(39)
              .onChange((value) => {
                this.debugSettingDataPreferences.putSync('dnsserverip', value)
                this.debugSettingDataPreferences.flushSync()
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Row() {
            Text('端口')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入端口 (可选)',
              text: this.port!!
            })
              .type(InputType.Number)
              .layoutWeight(1)
              .maxLength(5)
              .onChange((value) => {
                if (!value) {
                  this.debugSettingDataPreferences.deleteSync('dnsserverport')
                }
                const port = Number(value)
                if (port >= 0 && port <= 65535 && value) {
                  this.debugSettingDataPreferences.putSync('dnsserverport', port)
                  this.debugSettingDataPreferences.flushSync()
                }
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('自定义 DNS 服务器')
    .onAppear(() => {
      this.ip = this.debugSettingDataPreferences.getSync('dnsserverip', '') as string
      this.port = String(this.debugSettingDataPreferences.getSync('dnsserverport', 53))
    })
  }
}