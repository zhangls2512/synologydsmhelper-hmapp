import { common } from '@kit.AbilityKit'
import { getLoginStatus } from '../common/Account'

@ComponentV2
export default struct Filelist {
  @Local isLogin: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  async get() {
    this.isLogin = await getLoginStatus()
  }

  build() {
    List() {
      if (!this.isLogin) {
        ListItem() {
          Text('未登录账号')
        }
        .height('100%')
        .width('100%')
      }
      if (this.isLogin) {
        ListItem() {
          Text('待开发')
        }
        .height('100%')
        .width('100%')
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      this.context.eventHub.on('refreshFilelist', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshFilelist')
    })
  }
}