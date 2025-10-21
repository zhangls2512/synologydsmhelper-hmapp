import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { dsmRequest } from '../common/Request'

@ComponentV2
export default struct Renamefile {
  @Consumer() isShowRenamefileSheet: boolean = false
  @Consumer() editPath: string = ''
  @Consumer() editName: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入名称',
          text: this.editName!!
        })
          .defaultFocus(true)
          .enableAutoSpacing(true)
      }

      ListItem() {
        Button('重命名')
          .onClick(async () => {
            if (!this.editName) {
              promptAction.openToast({
                message: '请输入名称'
              })
              return
            }
            const dialogControllerProgress = new CustomDialogController({
              builder: LoadingDialog({
                content: '重命名中...'
              })
            })
            dialogControllerProgress.open()
            const res = await dsmRequest('', 'SYNO.FileStation.Rename',
              '&method=rename&path=' + encodeURIComponent(JSON.stringify([this.editPath])) + '&name=' +
              encodeURIComponent(this.editName))
            dialogControllerProgress.close()
            if (res !== 'fail') {
              promptAction.openToast({
                message: '重命名成功'
              })
              this.context.eventHub.emit('refreshFilelist')
              this.isShowRenamefileSheet = false
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
      .width('100%')
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
  }
}