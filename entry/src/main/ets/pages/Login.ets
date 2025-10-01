import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit'
import { privacyManager } from '@kit.AppGalleryKit'
import { util } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { netBoost } from '@kit.NetworkBoostKit'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import { set } from '../common/Accesstoken'
import openLink from '../common/Openlink'
import request from '../common/Request'

@ComponentV2
export default struct Login {
  @Consumer() isShowLoginSheet: boolean = false
  @Local type: string = 'password'
  @Local email: string = ''
  @Local password: string = ''
  @Local mfa: string = ''
  @Local emailcode: string = ''
  @Local agree: boolean = false
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  context = this.getUIContext().getHostContext()
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton(async (err, response) => {
        if (response) {
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
          const res = await request('/account/getAccessToken', {
            verifyType: 'huaweiaipasswordmemoapp',
            verifyCode: response.authorizationCode
          })
          netBoost.setSceneDesc({
            scene: 'login',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
          })
          dialogControllerProgress.close()
          if (res !== 'fail') {
            const accessToken = JSON.parse(res).accessToken as string
            const uid = JSON.parse(res).uid as string
            const email = JSON.parse(res).email as string
            const endDate = JSON.parse(res).endDate as number
            await set(accessToken, {
              uid: uid,
              email: email,
              endDate: endDate
            })
            promptAction.openToast({
              message: '登录成功'
            })
            this.isShowLoginSheet = false
          }
        }
        if (err) {
          promptAction.openToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      })

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text('方式')
              .fontWeight(FontWeight.Medium)
              .width('15%')
            Row() {
              Radio({
                value: 'password',
                group: 'type'
              })
                .checked(this.type === 'password' ? true : false)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onChange((isChecked) => {
                  if (isChecked) {
                    this.type = 'password'
                  }
                })
              Text('密码')
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Radio({
                value: 'mfa',
                group: 'type'
              })
                .checked(this.type === 'mfa' ? true : false)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onChange((isChecked) => {
                  if (isChecked) {
                    this.type = 'mfa'
                  }
                })
              Text('MFA')
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Radio({
                value: 'emailcode',
                group: 'type'
              })
                .checked(this.type === 'emailcode' ? true : false)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onChange((isChecked) => {
                  if (isChecked) {
                    this.type = 'emailcode'
                  }
                })
              Text('邮箱验证码')
            }
            .width('80%')
          }

          Row() {
            Text('邮箱')
              .fontWeight(FontWeight.Medium)
              .width('20%')
            TextInput({
              text: this.email!!,
              placeholder: '请输入邮箱'
            })
              .contentType(ContentType.EMAIL_ADDRESS)
              .enableAutoSpacing(true)
              .type(InputType.Email)
              .width('75%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          if (this.type === 'password') {
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
          }
          if (this.type === 'mfa') {
            Row() {
              Text('MFA')
                .fontWeight(FontWeight.Medium)
                .width('20%')
              TextInput({
                text: this.mfa!!,
                placeholder: '请输入 MFA'
              })
                .enableAutoSpacing(true)
                .maxLength(6)
                .type(InputType.ONE_TIME_CODE)
                .width('75%')
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          if (this.type === 'emailcode') {
            Row() {
              Text('验证码')
                .fontWeight(FontWeight.Medium)
                .width('20%')
              TextInput({
                text: this.emailcode!!,
                placeholder: '请输入邮箱验证码'
              })
                .enableAutoSpacing(true)
                .maxLength(8)
                .type(InputType.ONE_TIME_CODE)
                .width('75%')
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Button(this.buttonText)
              .buttonStyle(ButtonStyleMode.NORMAL)
              .enabled(this.buttonEnabled)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                if (!this.email) {
                  promptAction.openToast({
                    message: '请输入邮箱'
                  })
                  return
                }
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '发送中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await request('/account/sendEmailCode', {
                  email: this.email
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  promptAction.openToast({
                    message: '验证码已成功发送到邮箱：' + this.email
                  })
                  this.buttonEnabled = false
                  let countdown = 60
                  const interval = setInterval(() => {
                    countdown--
                    if (countdown > 0) {
                      this.buttonText = '重新发送 (' + countdown + ')'
                    } else {
                      clearInterval(interval)
                      this.buttonEnabled = true
                      this.buttonText = '获取验证码'
                    }
                  }, 1000)
                }
              })
          }
          Button('登录')
            .enabled(this.agree)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .width('100%')
            .onClick(async () => {
              if (!this.email) {
                promptAction.openToast({
                  message: '请输入邮箱'
                })
                return
              }
              if (this.type === 'password' && this.password.length < 8) {
                promptAction.openToast({
                  message: '请输入正确的密码'
                })
                return
              }
              if (this.type === 'mfa' && this.mfa.length !== 6) {
                promptAction.openToast({
                  message: '请输入正确的 MFA'
                })
                return
              }
              if (this.type === 'emailcode' && this.emailcode.length !== 8) {
                promptAction.openToast({
                  message: '请输入正确的邮箱验证码'
                })
                return
              }
              let code = ''
              if (this.type === 'password') {
                code = this.password
              }
              if (this.type === 'mfa') {
                code = this.mfa
              }
              if (this.type === 'emailcode') {
                code = this.emailcode
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
              const res = await request('/account/getAccessToken', {
                verifyType: this.type,
                verifyCode: code,
                email: this.email
              })
              netBoost.setSceneDesc({
                scene: 'login',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
              })
              dialogControllerProgress.close()
              if (res !== 'fail') {
                const accessToken = JSON.parse(res).accessToken as string
                const uid = JSON.parse(res).uid as string
                const email = JSON.parse(res).email as string
                const endDate = JSON.parse(res).endDate as number
                await set(accessToken, {
                  uid: uid,
                  email: email,
                  endDate: endDate
                })
                promptAction.openToast({
                  message: '登录成功'
                })
                this.isShowLoginSheet = false
              }
            })
          LoginWithHuaweiIDButton({
            params: {
              style: loginComponentManager.Style.BUTTON_RED,
              extraStyle: {
                buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                  show: true
                })
              }
            },
            controller: this.controller
          })
            .enabled(this.agree)
            .height(40)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          Button('通行密钥登录')
          //.enabled(this.agree)
            .enabled(false)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('100%')
            .onClick(async () => {
              try {
                const resa = await fido2.authenticate(this.context, {
                  publicKey: {
                    challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000')
                  }
                })
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
                const resb = await request('/account/getAccessToken', {
                  verifyType: 'passkey',
                  rawId: new util.Base64Helper().encodeToStringSync(resa.rawId, util.Type.BASIC_URL_SAFE),
                  authenticatorData: new util.Base64Helper().encodeToStringSync(resa.response.authenticatorData,
                    util.Type.BASIC_URL_SAFE),
                  clientDataJSON: new util.Base64Helper().encodeToStringSync(resa.response.clientDataJson,
                    util.Type.BASIC_URL_SAFE),
                  signature: new util.Base64Helper().encodeToStringSync(resa.response.signature,
                    util.Type.BASIC_URL_SAFE)
                })
                netBoost.setSceneDesc({
                  scene: 'login',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                })
                dialogControllerProgress.close()
                if (resb !== 'fail') {
                  const accessToken = JSON.parse(resb).accessToken as string
                  const uid = JSON.parse(resb).uid as string
                  const email = JSON.parse(resb).email as string
                  const endDate = JSON.parse(resb).endDate as number
                  await set(accessToken, {
                    uid: uid,
                    email: email,
                    endDate: endDate
                  })
                  promptAction.openToast({
                    message: '登录成功'
                  })
                  this.isShowLoginSheet = false
                }
              } catch (err) {
                promptAction.openToast({
                  message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                })
              }
            })
          Text('注册账号')
            .fontColor($r('sys.color.font_emphasize'))
            .fontWeight(FontWeight.Medium)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .onClick(() => {
              openLink('https://www.zhangls2512.cn/product/account/register')
            })
          Row() {
            Column() {
              Toggle({
                type: ToggleType.Checkbox,
                isOn: this.agree!!
              })
                .onChange((isOn) => {
                  this.controller.setEnabled(isOn)
                })
            }
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .width('10%')

            Text() {
              Span('已阅读并同意')
              Span('《轩铭密码智能备忘录用户服务条款与条件》')
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
              Span('《关于轩铭密码智能备忘录与隐私的声明》')
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
              Span('。如果使用华为账号登录，已阅读并同意')
              Span('《华为账号用户认证协议》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                  openLink('https://privacy.consumer.huawei.com/legal/id/authentication-terms.htm?code=CN&language=zh-CN')
                })
              Span('《关于华为账号与隐私的声明》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                  openLink('https://legal.cloud.huawei.com/terms/scope/huawei/id-hmos/privacy-statement.htm?code=CN&language=zh-CN')
                })
              Span('。')
            }
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
    .onAppear(() => {
      this.controller.setEnabled(false)
    })
  }
}