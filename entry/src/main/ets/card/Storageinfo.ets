import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { getLoginStatus } from '../common/Account'
import { dsmRequest } from '../common/Request'
import { getSizeString } from '../common/Stringformat'

interface StorageInfo {
  volumes: VolumeItem[]
}

interface VolumeItem {
  device_type: string,
  fs_type: string,
  size: VolumeSize,
  num_id: number
}

interface VolumeSize {
  total: number,
  total_device: number,
  used: number
}

@ComponentV2
export default struct Storageinfo {
  @Local storageinfo: StorageInfo | undefined = undefined
  @Local status: string = 'fail'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  async refresh() {
    const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cardSetting'
    })
    const isLogin = await getLoginStatus()
    if ((cardSettingDataPreferences.getSync('cards', []) as string[]).includes('storageinfo') &&
      this.status !== 'fail' && isLogin) {
      const res = await dsmRequest(this.context, '', 'SYNO.Storage.CGI.Storage', new url.URLParams({
        method: 'load_info'
      }).toString())
      if (res !== 'fail') {
        this.storageinfo = res as StorageInfo
        this.status = 'success'
      }
      if (res === 'fail') {
        this.storageinfo = undefined
        this.status = 'fail'
      }
    }
  }

  build() {
    Column() {
      if (this.status === 'pending' && !this.storageinfo) {
        Text('获取数据中')
      }
      if (this.status === 'fail') {
        Text('获取数据失败')
      }
      if (this.storageinfo) {
        Column() {
          Text('存储空间信息')
            .fontWeight(FontWeight.Bold)
          ForEach(this.storageinfo.volumes, (item: VolumeItem) => {
            Text('存储空间' + item.num_id)
              .enableAutoSpacing(true)
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('RAID类型：' + item.device_type)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('文件系统：' + item.fs_type)
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('总容量：' + getSizeString(item.size.total_device))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('已分配容量：' + getSizeString(item.size.total))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('已用容量：' + getSizeString(item.size.used))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
            Text('剩余容量：' + getSizeString(item.size.total - item.size.used))
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
      this.context.eventHub.on('refreshCard', () => {
        this.status = 'pending'
      })
      this.status = 'pending'
      setInterval(async () => {
        await this.refresh()
      }, 5000)
      await this.refresh()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCard')
    })
  }
}