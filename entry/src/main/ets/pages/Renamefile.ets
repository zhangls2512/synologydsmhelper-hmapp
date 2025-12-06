import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { dsmRequest } from '../common/Request'

@ComponentV2
export default struct Renamefile {
  @Consumer() isShowRenamefileSheet: boolean = false
  @Param editPath: string = ''
  @Param editName: string = ''
  @Local name: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入名称',
          text: this.name!!
        })
          .defaultFocus(true)
          .enableAutoSpacing(true)
      }

      ListItem() {
        Button('重命名')
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
                content: '重命名中...'
              })
            })
            dialogControllerProgress.open()
            const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.FileStation.Rename',
              '&method=rename&path=' + encodeURIComponent(JSON.stringify([this.editPath])) + '&name=' +
              encodeURIComponent(this.name))
            dialogControllerProgress.close()
            if (res !== 'fail') {
              await promptAction.openToast({
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
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(() => {
      this.name = this.editName
    })
  }
}