import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { getLoginStatus } from '../common/Account'
import { dsmRequest } from '../common/Request'
import { getSizeString } from '../common/Stringformat'

interface DiskInfo {
  disks: DiskItem[]
}

interface DiskItem {
  diskType: string,
  firm: string,
  isSsd: boolean,
  is4Kn: boolean,
  name: string,
  size_total: string,
  serial: string,
  model: string,
  temp: number
}

@ComponentV2
export default struct Diskinfo {
  @Local diskinfo: DiskInfo | undefined = undefined
  @Local status: string = 'fail'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  intervalId = -1

  async refresh() {
    const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cardSetting'
    })
    const isLogin = await getLoginStatus()
    if ((cardSettingDataPreferences.getSync('cards', []) as string[]).includes('diskinfo') && this.status !== 'fail' &&
      isLogin) {
      const res = await dsmRequest(this.context, '', 'SYNO.Storage.CGI.Storage', new url.URLParams({
        method: 'load_info'
      }).toString())
      if (res !== 'fail') {
        this.diskinfo = res as DiskInfo
        this.status = 'success'
      }
      if (res === 'fail') {
        this.diskinfo = undefined
        this.status = 'fail'
      }
    }
  }

  build() {
    Column() {
      if (this.status === 'pending' && !this.diskinfo) {
        Text('获取数据中')
      }
      if (this.status === 'fail') {
        Text('获取数据失败')
      }
      if (this.diskinfo) {
        Column() {
          Text('硬盘信息')
            .fontWeight(FontWeight.Bold)
          ForEach(this.diskinfo.disks, (item: DiskItem) => {
            Text(item.name)
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('容量：' + getSizeString(Number(item.size_total)))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('类型：' + (item.isSsd ? 'SSD' : 'HDD'))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('协议：' + item.diskType)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('温度：' + item.temp + ' ℃')
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('型号：' + item.model)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('序列号：' + item.serial)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('固件版本：' + item.firm)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('4K原生硬盘：' + (item.is4Kn ? '是' : '否'))
              .enableAutoSpacing(true)
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