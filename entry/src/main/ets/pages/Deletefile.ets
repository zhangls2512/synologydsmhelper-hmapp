import { LengthMetrics } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { HdsNavDestination } from '@kit.UIDesignKit'

@Builder
export function DeletefileBuilder() {
  Deletefile()
}

@ComponentV2
struct Deletefile {
  @Local fileUri: string = ''

  build() {
    HdsNavDestination() {
      List() {
        ListItem() {
          TextInput({
            placeholder: '请输入文件Uri',
            text: this.fileUri!!
          })
            .defaultFocus(true)
            .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Button('删除')
            .enabled(this.fileUri !== '')
            .role(ButtonRole.ERROR)
            .width('100%')
            .onClick(async () => {
              const promptAction = this.getUIContext().getPromptAction()
              const data = await promptAction.showDialog({
                title: '提示',
                message: '删除成功后无法恢复，确定删除？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '删除',
                    color: $r('sys.color.warning')
                  }
                ]
              })
              if (data.index === 1) {
                try {
                  await fileIo.unlink(this.fileUri.replace('file://com.songjy.synologydsmhelper', ''))
                  await promptAction.openToast({
                    message: '删除成功'
                  })
                  this.fileUri = ''
                } catch (err) {
                  await promptAction.openToast({
                    message: '发生错误，错误码：' + err.code
                  })
                }
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
    .backgroundColor($r('app.color.sheet_background'))
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      content: {
        title: {
          mainTitle: '沙箱文件删除工具'
        }
      },
      enableComponentSafeArea: true
    })
  }
}