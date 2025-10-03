import { privacyManager } from '@kit.AppGalleryKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { netBoost } from '@kit.NetworkBoostKit'
import openLink from '../common/Openlink'
import request from '../common/Request'

@ComponentV2
export default struct Login {
  @Consumer() isShowLoginSheet: boolean = false
  @Local password: string = ''
  @Local agree: boolean = false

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text('密码')
              .fontWeight(FontWeight.Medium)
              .width('20%')
            TextInput({
              text: this.password!!,
              placeholder: '请输入密码'
            })
              .contentType(ContentType.PASSWORD)
              .enableAutoSpacing(true)
              .maxLength(30)
              .type(InputType.Password)
              .width('75%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Button('登录')
            .enabled(this.agree)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .width('100%')
            .onClick(async () => {
              if (!this.password) {
                promptAction.openToast({
                  message: '请输入密码'
                })
                return
              }
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '登录中...'
                })
              })
              dialogControllerProgress.open()
              netBoost.setSceneDesc({
                scene: 'login',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
              })
              const res = await request('/', {
                password: this.password
              })
              netBoost.setSceneDesc({
                scene: 'login',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
              })
              dialogControllerProgress.close()
              if (res !== 'fail') {
                promptAction.openToast({
                  message: '登录成功'
                })
                this.isShowLoginSheet = false
              }
            })
          Row() {
            Column() {
              Toggle({
                type: ToggleType.Checkbox,
                isOn: this.agree!!
              })
            }
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .width('10%')

            Text() {
              Span('已阅读并同意')
              Span('《群晖DSM助手用户服务条款与条件》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                  try {
                    const appPrivacyLink =
                      privacyManager.getAppPrivacyMgmtInfo().privacyInfo.find(item => item.type === 2)
                    openLink(appPrivacyLink?.url as string)
                  } catch (err) {
                    promptAction.openToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                })
              Span('《关于群晖DSM助手与隐私的声明》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                  try {
                    const appPrivacyLink =
                      privacyManager.getAppPrivacyMgmtInfo().privacyInfo.find(item => item.type === 1)
                    openLink(appPrivacyLink?.url as string)
                  } catch (err) {
                    promptAction.openToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                })
              Span('。')
            }
            .enableAutoSpacing(true)
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .width('85%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        }
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
  }
}