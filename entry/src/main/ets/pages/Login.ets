import { privacyManager } from '@kit.AppGalleryKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { netBoost } from '@kit.NetworkBoostKit'
import { set } from '../common/Account'
import openLink from '../common/Openlink'
import { dsmRequest } from '../common/Request'

export interface ResponseData {
  account: string,
  sid: string,
  device_id: string
}

@ComponentV2
export default struct Login {
  @Consumer() isShowLoginSheet: boolean = false
  @Local scheme: string = 'http'
  @Local host: string = ''
  @Local port: string = ''
  @Local name: string = ''
  @Local password: string = ''
  @Local mfa: string = ''
  @Local agree: boolean = false

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text('协议')
              .fontWeight(FontWeight.Medium)
              .width('15%')
            Row() {
              Radio({
                value: 'http',
                group: 'scheme'
              })
                .checked(this.scheme === 'http' ? true : false)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onChange((isChecked) => {
                  if (isChecked) {
                    this.scheme = 'http'
                  }
                })
              Text('http')
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Row() {
                Radio({
                  value: 'https',
                  group: 'scheme'
                })
                  .checked(this.scheme === 'https' ? true : false)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onChange((isChecked) => {
                    if (isChecked) {
                      this.scheme = 'https'
                    }
                  })
                Text('https')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
              }
            }
            .width('80%')
          }

          Row() {
            Text('主机')
              .fontWeight(FontWeight.Medium)
              .width('15%')
            TextInput({
              placeholder: '请输入主机',
              text: this.host!!
            })
              .enableAutoSpacing(true)
              .width('80%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('端口')
              .fontWeight(FontWeight.Medium)
              .width('15%')
            TextInput({
              placeholder: '请输入端口 (可选)',
              text: this.port!!
            })
              .enableAutoSpacing(true)
              .type(InputType.Number)
              .maxLength(5)
              .width('80%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('账号')
              .fontWeight(FontWeight.Medium)
              .width('15%')
            TextInput({
              placeholder: '请输入账号',
              text: this.name!!
            })
              .contentType(ContentType.USER_NAME)
              .enableAutoSpacing(true)
              .width('80%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('密码')
              .fontWeight(FontWeight.Medium)
              .width('15%')
            TextInput({
              placeholder: '请输入密码',
              text: this.password!!
            })
              .contentType(ContentType.PASSWORD)
              .enableAutoSpacing(true)
              .maxLength(30)
              .type(InputType.Password)
              .width('80%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('MFA')
              .fontWeight(FontWeight.Medium)
              .width('15%')
            TextInput({
              placeholder: '请输入MFA (可选)',
              text: this.mfa!!
            })
              .enableAutoSpacing(true)
              .type(InputType.Number)
              .maxLength(6)
              .width('80%')
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
              if (!this.host) {
                promptAction.openToast({
                  message: '请输入主机'
                })
                return
              }
              let port = '0'
              if (!this.port) {
                if (this.scheme === 'http') {
                  port = '5000'
                }
                if (this.scheme === 'https') {
                  port = '5001'
                }
              }
              if (this.port) {
                port = this.port
              }
              if (!this.name) {
                promptAction.openToast({
                  message: '请输入账号'
                })
                return
              }
              if (!this.password) {
                promptAction.openToast({
                  message: '请输入密码'
                })
                return
              }
              if (this.mfa && this.mfa.length !== 6) {
                promptAction.openToast({
                  message: '请输入正确的 MFA'
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
              const res = await dsmRequest(this.scheme + '://' + this.host + ':' + port, 'SYNO.API.Auth',
                '&method=login&account=' + this.name + '&passwd=' + this.password + '&otp_code=' + this.mfa)
              netBoost.setSceneDesc({
                scene: 'login',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
              })
              dialogControllerProgress.close()
              if (res !== 'fail') {
                const data = res as ResponseData
                await set({
                  path: this.scheme + '://' + this.host + ':' + port,
                  name: data.account,
                  password: this.password,
                  sid: data.sid,
                  did: data.device_id
                })
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