import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { dsmRequest } from '../common/Request'

@ComponentV2
export default struct Newfolder {
  @Consumer() isShowNewfolderSheet: boolean = false
  @Consumer() editPath: string = ''
  @Local name: string = ''

  build() {
    List() {
      ListItem() {
        TextInput({
          placeholder: '请输入名称',
          text: this.name!!
        })
          .enableAutoSpacing(true)
      }
      .width('95%')

      ListItem() {
        Button('新建')
          .onClick(async () => {
            if (!this.name) {
              promptAction.openToast({
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
            const res = await dsmRequest('', 'SYNO.FileStation.CreateFolder',
              '&method=create&folder_path=' + encodeURIComponent(this.editPath) + '&name=' +
              encodeURIComponent(this.name))
            dialogControllerProgress.close()
            if (res !== 'fail') {
              promptAction.openToast({
                message: '新建文件夹成功'
              })
              this.isShowNewfolderSheet = false
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