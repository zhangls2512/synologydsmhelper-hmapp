import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { dsmRequest } from '../common/Request'

@ComponentV2
export default struct Newalbum {
  @Consumer() isShowNewalbumSheet: boolean = false
  @Local name: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    List() {
      ListItem() {
        Column() {
          TextInput({
            placeholder: '请输入名称',
            text: this.name!!
          })
            .defaultFocus(true)
            .enableAutoSpacing(true)
          Button('新建')
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .width('100%')
            .onClick(async () => {
              if (!this.name) {
                await promptAction.openToast({
                  message: '请输入名称'
                })
                return
              }
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '新建中...'
                })
              })
              dialogControllerProgress.open()
              const res = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.ConditionAlbum', new url.URLParams({
                method: 'create',
                name: JSON.stringify(this.name),
                condition: JSON.stringify({
                  user_id: 1
                })
              }).toString())
              dialogControllerProgress.close()
              if (res !== 'fail') {
                await promptAction.openToast({
                  message: '新建成功'
                })
                this.context.eventHub.emit('refreshAlbum')
                this.isShowNewalbumSheet = false
              }
            })
        }
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
  }
}