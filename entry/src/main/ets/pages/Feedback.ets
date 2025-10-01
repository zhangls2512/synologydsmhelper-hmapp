import { LoadingDialog, promptAction } from '@kit.ArkUI'
import request from '../common/Request'

@Builder
export function FeedbackBuilder() {
  Feedback()
}

@ComponentV2
struct Feedback {
  @Local content: string = ''
  @Local contactType: string = '邮箱'
  @Local contactTypeIndex: number = 0
  @Local contactValue: string = ''
  pageInfos = new NavPathStack()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            TextArea({
              placeholder: '请输入内容',
              text: this.content!!
            })
              .defaultFocus(true)
              .enableAutoSpacing(true)
              .maxLength(200)
              .showCounter(true)
            Text('联系方式 (可选)')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            Row() {
              Select([
                { value: '邮箱' },
                { value: '微信' },
                { value: 'QQ' }
              ])
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .selected(this.contactTypeIndex!!)
                .value(this.contactType!!)
                .width('30%')
                .onSelect((index) => {
                  if (index === 0) {
                    this.contactType = '邮箱'
                  }
                  if (index === 1) {
                    this.contactType = '微信'
                  }
                  if (index === 2) {
                    this.contactType = 'QQ'
                  }
                })
              if (this.contactType === '邮箱') {
                TextInput({
                  placeholder: '请输入邮箱',
                  text: this.contactValue!!
                })
                  .contentType(ContentType.EMAIL_ADDRESS)
                  .enableAutoSpacing(true)
                  .type(InputType.Email)
                  .width('65%')
              }
              if (this.contactType === '微信') {
                TextInput({
                  placeholder: '请输入微信号',
                  text: this.contactValue!!
                })
                  .enableAutoSpacing(true)
                  .maxLength(30)
                  .width('65%')
              }
              if (this.contactType === 'QQ') {
                TextInput({
                  placeholder: '请输入 QQ 号',
                  text: this.contactValue!!
                })
                  .enableAutoSpacing(true)
                  .maxLength(20)
                  .type(InputType.Number)
                  .width('65%')
              }
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Button('提交')
              .enabled(this.content !== '')
              .onClick(async () => {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '提交中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await request('/debug/sendFeedbackEmail', {
                  key: 'RaGvhiCmYP8aPZ-QmmDgBQvwkfkp9TXEVCWEn8fPjshs9GyUCooG_kq7N8bHBRcT',
                  product: '密码智能备忘录',
                  content: this.content,
                  contactType: this.contactType,
                  contactValue: this.contactValue
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  promptAction.openToast({
                    message: '提交成功'
                  })
                  this.pageInfos.pop()
                }
              })
          }
          .width('100%')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('建议填写联系方式，以便开发人员在需要时联系您。')
              .fontWeight(FontWeight.Medium)
          }
          .alignItems(HorizontalAlign.Start)
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
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('意见反馈')
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}