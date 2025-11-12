import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { getLoginStatus } from '../common/Account'
import { dsmRequest } from '../common/Request'

interface SystemInfo {
  cpu_clock_speed: number,
  cpu_cores: string,
  cpu_family: string,
  cpu_series: string,
  cpu_vendor: string,
  enabled_ntp: boolean,
  firmware_date: string,
  firmware_ver: string,
  model: string,
  ntp_server: string,
  ram_size: number,
  serial: string,
  sys_temp: number,
  sys_tempwarn: boolean,
  time: string,
  time_zone: string,
  time_zone_desc: string,
  up_time: string
}

@ComponentV2
export default struct Systeminfo {
  @Local systeminfo: SystemInfo | undefined = undefined
  @Local status: string = 'fail'
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  build() {
    Column() {
      if (this.status === 'pending' && !this.systeminfo) {
        Text('获取数据中')
      }
      if (this.status === 'fail') {
        Text('获取数据失败')
      }
      if (this.systeminfo) {
        Column() {
          Text('系统信息')
            .fontWeight(FontWeight.Bold)
          Text('DSM版本：' + this.systeminfo.firmware_ver)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('DSM发布日期：' + this.systeminfo.firmware_date)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('产品序列号：' + this.systeminfo.serial)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('产品型号：' + this.systeminfo.model)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('CPU：' + this.systeminfo.cpu_vendor + ' ' + this.systeminfo.cpu_series + ' ' +
          this.systeminfo.cpu_family)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('CPU时钟频率：' + this.systeminfo.cpu_clock_speed + ' MHz')
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('CPU内核数：' + this.systeminfo.cpu_cores)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('物理内存大小：' + this.systeminfo.ram_size + ' MB')
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('温度：' + this.systeminfo.sys_temp + ' ℃')
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('温度警告：' + this.systeminfo.sys_tempwarn)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('时间与NTP服务器同步：' + this.systeminfo.enabled_ntp)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('NTP服务器：' + this.systeminfo.ntp_server)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('时区：' + this.systeminfo.time_zone)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('时区描述：' + this.systeminfo.time_zone_desc)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('系统时间：' + this.systeminfo.time)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('运行时间：' + this.systeminfo.up_time)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
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
    .onAppear(() => {
      this.context.eventHub.on('refreshCard', () => {
        this.status = 'pending'
      })
      this.status = 'pending'
      setInterval(async () => {
        const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
          name: 'cardSetting'
        })
        const isLogin = await getLoginStatus()
        if ((cardSettingDataPreferences.getSync('cards', []) as string[]).includes('systeminfo') &&
          this.status !== 'fail' && isLogin) {
          const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Core.System', '&method=info')
          if (res !== 'fail') {
            this.systeminfo = res as SystemInfo
            this.status = 'success'
          }
          if (res === 'fail') {
            this.systeminfo = undefined
            this.status = 'fail'
          }
        }
      }, 5000)
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCard')
    })
  }
}