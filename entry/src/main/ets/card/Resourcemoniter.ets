import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { getLoginStatus } from '../common/Account'
import { getFlushPreference } from '../common/Preference'
import { dsmRequest } from '../common/Request'
import { getSizeString } from '../common/Stringformat'

interface ResourceMoniter {
  cpu: Cpu,
  memory: Memory,
  disk: Disk,
  network: NetworkItem[]
}

interface Cpu {
  user_load: number
}

interface Memory {
  real_usage: number
}

interface Disk {
  total: DiskTotal
}

interface DiskTotal {
  read_byte: number,
  write_byte: number
}

interface NetworkItem {
  device: string,
  rx: number,
  tx: number
}

@ComponentV2
export default struct Resourcemoniter {
  @Local resourcemoniter: ResourceMoniter | undefined = undefined
  @Local status: string = 'fail'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  intervalId = -1

  async refresh() {
    const isLogin = await getLoginStatus(this.context)
    if ((getFlushPreference(this.context, 'cardSetting', 'cards', []) as string[]).includes('resourcemoniter') &&
      this.status !== 'fail' && isLogin) {
      const res = await dsmRequest(this.context, '', 'SYNO.Core.System.Utilization', new url.URLParams({
        method: 'get'
      }).toString())
      if (res !== 'fail') {
        this.resourcemoniter = res as ResourceMoniter
        this.status = 'success'
      }
      if (res === 'fail') {
        this.resourcemoniter = undefined
        this.status = 'fail'
      }
    }
  }

  async refreshCard() {
    this.status = 'pending'
    await this.refresh()
  }

  build() {
    Column() {
      if (this.status === 'pending' && !this.resourcemoniter) {
        Text('获取数据中')
      }
      if (this.status === 'fail') {
        Text('获取数据失败')
      }
      if (this.resourcemoniter) {
        Column() {
          Text('资源监控')
            .fontWeight(FontWeight.Bold)
          Text('CPU利用率：' + this.resourcemoniter.cpu.user_load + '%')
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('内存利用率：' + this.resourcemoniter.memory.real_usage + '%')
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('硬盘读取速度：' + getSizeString(this.resourcemoniter.disk.total.read_byte) + '/s')
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('硬盘写入速度：' + getSizeString(this.resourcemoniter.disk.total.write_byte) + '/s')
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('网络下行速度：' + getSizeString(this.resourcemoniter.network.find(item => item.device === 'total')?.rx) +
            '/s')
            .margin({
              top: $r('sys.float.ohos_id_text_margin_vertical')
            })
          Text('网络上行速度：' + getSizeString(this.resourcemoniter.network.find(item => item.device === 'total')?.tx) +
            '/s')
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
    .onAppear(async () => {
      this.context.eventHub.on('refreshCard', this.refreshCard)
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
      this.context.eventHub.off('refreshCard', this.refreshCard)
    })
  }
}