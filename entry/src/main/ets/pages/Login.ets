import { privacyManager } from '@kit.AppGalleryKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
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
  @Local quickConnectId: string = ''
  @Local name: string = ''
  @Local password: string = ''
  @Local mfa: string = ''
  @Local agree: boolean = false

  build() {
    List() {
      ListItem() {
        Column() {
          if (!this.quickConnectId) {
            Row() {
              Text('协议')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Row() {
                Radio({
                  value: 'http',
                  group: 'scheme'
                })
                  .checked(this.scheme === 'http' ? true : false)
                  .onChange((isChecked) => {
                    if (isChecked) {
                      this.scheme = 'http'
                    }
                  })
                Text('http')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Radio({
                  value: 'https',
                  group: 'scheme'
                })
                  .checked(this.scheme === 'https' ? true : false)
                  .onChange((isChecked) => {
                    if (isChecked) {
                      this.scheme = 'https'
                    }
                  })
                Text('https')
              }
              .layoutWeight(1)
            }

            Row() {
              Text('主机')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入主机',
                text: this.host!!
              })
                .enableAutoSpacing(true)
                .layoutWeight(1)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Row() {
              Text('端口')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入端口 (可选)',
                text: this.port!!
              })
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(5)
                .type(InputType.Number)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          TextInput({
            placeholder: '请输入QuickConnect ID',
            text: this.quickConnectId!!
          })
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          Row() {
            Text('账号')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入账号',
              text: this.name!!
            })
              .contentType(ContentType.USER_NAME)
              .enableAutoSpacing(true)
              .layoutWeight(1)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('密码')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入密码',
              text: this.password!!
            })
              .contentType(ContentType.PASSWORD)
              .enableAutoSpacing(true)
              .layoutWeight(1)
              .maxLength(30)
              .type(InputType.Password)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('MFA')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入MFA (可选)',
              text: this.mfa!!
            })
              .enableAutoSpacing(true)
              .layoutWeight(1)
              .maxLength(6)
              .type(InputType.Number)
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
              if (!this.quickConnectId) {
                if (!this.host) {
                  promptAction.openToast({
                    message: '请输入主机'
                  })
                  return
                }
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
              let path = ''
              let res: string | object = ''
              if (!this.quickConnectId) {
                path = this.scheme + '://' + this.host + ':' + port
                netBoost.setSceneDesc({
                  scene: 'login',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                })
                res = await dsmRequest(path, 'SYNO.API.Auth',
                  '&method=login&account=' + encodeURIComponent(this.name) + '&passwd=' +
                  encodeURIComponent(this.password) + '&otp_code=' + this.mfa)
              }
              if (this.quickConnectId) {
                const session = rcp.createSession()
                try {
                  const response = await session.post('https://global.quickconnect.cn/Serv.php', JSON.stringify([
                    {
                      command: 'get_server_info',
                      id: 'dsm',
                      serverID: this.quickConnectId
                    }
                  ]))
                  session.close()
                  if (response.statusCode === 200) {
                    let body = ''
                    if (response.toString()) {
                      body = response.toString() as string
                    }
                    const bodyObject = JSON.parse(body) as object
                    if (bodyObject[0]['errno'] === 0) {
                      path =
                        'https://' + this.quickConnectId + '.' + bodyObject[0]['env']['relay_region'] +
                          '.quickconnect.cn'
                      netBoost.setSceneDesc({
                        scene: 'login',
                        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                      })
                      res = await dsmRequest(path, 'SYNO.API.Auth',
                        '&method=login&account=' + encodeURIComponent(this.name) + '&passwd=' +
                        encodeURIComponent(this.password) + '&otp_code=' + this.mfa)
                    } else {
                      dialogControllerProgress.close()
                      promptAction.openToast({
                        message: 'QuickConnect 连接失败，错误码：' + bodyObject[0]['errno']
                      })
                      return
                    }
                  } else {
                    dialogControllerProgress.close()
                    promptAction.openToast({
                      message: 'QuickConnect 请求失败，错误码：' + response.statusCode
                    })
                    return
                  }
                } catch (err) {
                  session.close()
                  dialogControllerProgress.close()
                  promptAction.openToast({
                    message: 'QuickConnect 请求失败，错误码：' + err.code
                  })
                  return
                }
              }
              netBoost.setSceneDesc({
                scene: 'login',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
              })
              dialogControllerProgress.close()
              if (res !== 'fail') {
                const data = res as ResponseData
                await set({
                  path: path,
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
            Toggle({
              type: ToggleType.Checkbox,
              isOn: this.agree!!
            })
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
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
            .layoutWeight(1)
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