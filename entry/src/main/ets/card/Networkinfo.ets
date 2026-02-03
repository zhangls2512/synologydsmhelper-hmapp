import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { getLoginStatus } from '../common/Account'
import { dsmRequest } from '../common/Request'

interface NetworkInfo {
  dns: string,
  hostname: string,
  gateway: string,
  nif: NifItem[]
}

interface NifItem {
  addr: string,
  duplex: boolean,
  mac: string,
  mask: string,
  mtu: number,
  speed: number,
  status: string,
  use_dhcp: boolean
}

@ComponentV2
export default struct Networkinfo {
  @Local networkinfo: NetworkInfo | undefined = undefined
  @Local status: string = 'fail'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  intervalId = -1

  async refresh() {
    const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cardSetting'
    })
    const isLogin = await getLoginStatus()
    if ((cardSettingDataPreferences.getSync('cards', []) as string[]).includes('networkinfo') &&
      this.status !== 'fail' && isLogin) {
      const res = await dsmRequest(this.context, '', 'SYNO.Core.System', new url.URLParams({
        method: 'info',
        type: 'network'
      }).toString())
      if (res !== 'fail') {
        this.networkinfo = res as NetworkInfo
        this.status = 'success'
      }
      if (res === 'fail') {
        this.networkinfo = undefined
        this.status = 'fail'
      }
    }
  }

  build() {
    Column() {
      if (this.status === 'pending' && !this.networkinfo) {
        Text('获取数据中')
      }
      if (this.status === 'fail') {
        Text('获取数据失败')
      }
      if (this.networkinfo) {
        Column() {
          Text('网络信息')
            .fontWeight(FontWeight.Bold)
          Text('系统名称：' + this.networkinfo.hostname)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('DNS服务器：' + this.networkinfo.dns)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('默认网关：' + this.networkinfo.gateway)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          ForEach(this.networkinfo.nif, (item: NifItem, index) => {
            Text('局域网' + (index + 1))
              .enableAutoSpacing(true)
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text() {
              Span('连接状态：')
              if (item.status === 'connected') {
                Span('已连接')
                  .fontColor(Color.Green)
              }
              if (item.status === 'disconnected') {
                Span('未连接')
                  .fontColor(Color.Red)
              }
            }
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })

            Text('MAC地址：' + item.mac)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('IP地址：' + item.addr)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('子网掩码：' + item.mask)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('DHCP：' + (item.use_dhcp ? '是' : '否'))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            if (item.speed !== -1) {
              Text('最大传输速度：' + item.speed + ' MB/s')
                .margin({
                  top: $r('sys.float.ohos_id_text_margin_vertical')
                })
            }
            Text('最大传输单元：' + item.mtu)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('全双工：' + (item.duplex ? '是' : '否'))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .padding(12)
    .width('100%')
    .onAppear(async () => {
      this.context.eventHub.on('refreshCard', async () => {
        this.status = 'pending'
        await this.refresh()
      })
      this.status = 'pending'
      this.intervalId = setInterval(async () => {
        await this.refresh()
      }, 5000)
      await this.refresh()
    })
    .onDisAppear(() => {
      if (this.intervalId !== -1) {
        clearInterval(this.intervalId)
      }
      this.context.eventHub.off('refreshCard')
    })
  }
}