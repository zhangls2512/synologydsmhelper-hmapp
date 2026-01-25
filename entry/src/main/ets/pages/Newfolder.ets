import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { dsmRequest } from '../common/Request'

@ComponentV2
export default struct Newfolder {
  @Consumer() isShowNewfolderSheet: boolean = false
  @Param editPath: string = ''
  @Local name: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

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
        Button('新建')
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
                content: '新建文件夹中...'
              })
            })
            dialogControllerProgress.open()
            const res = await dsmRequest(this.context, '', 'SYNO.FileStation.CreateFolder', new url.URLParams({
              method: 'create',
              folder_path: this.editPath,
              name: JSON.stringify(this.name)
            }).toString())
            dialogControllerProgress.close()
            if (res !== 'fail') {
              await promptAction.openToast({
                message: '新建文件夹成功'
              })
              this.context.eventHub.emit('refreshFilelist')
              this.isShowNewfolderSheet = false
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
  }
}