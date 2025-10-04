import { common } from '@kit.AbilityKit'

@ComponentV2
export default struct Cardlist {
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  get() {
  }

  build() {
    List() {
      ListItem() {
      }

      ListItem() {
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
    .onAppear(() => {
      this.context.eventHub.on('refreshCardlist', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCardlist')
    })
  }
}