import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { display, LoadingDialog } from '@kit.ArkUI'
import { exitAccount, getAccountInfo } from '../common/Account'
import { getPreferType } from '../common/Prefertype'
import { dsmRequest } from '../common/Request'
import Accountlist from './Accountlist'
import Login from './Login'
import Setting from './Setting'
import Transfertask from './Transfertask'

@ComponentV2
export default struct Me {
  @Provider() isShowLoginSheet: boolean = false
  @Provider() isShowAccountlistSheet: boolean = false
  @Local isShowTransfertaskSheet: boolean = false
  @Local isShowSettingSheet: boolean = false
  @Local preferType: number = 1
  @Local name: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  async get() {
    const accountInfo = await getAccountInfo(this.context)
    this.name = accountInfo.name
  }

  @Builder
  LoginSheetBuilder() {
    Login()
  }

  @Builder
  AccountlistSheetBuilder() {
    Accountlist()
  }

  @Builder
  TransfertaskSheetBuilder() {
    Transfertask()
  }

  @Builder
  SettingSheetBuilder() {
    Setting()
  }

  build() {
    List() {
      ListItem()
        .margin({
          top: this.preferType === 0 ? 56 : 0
        })
      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.foreground'))
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(40)
            if (!this.name) {
              Text('登录')
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
            }
            if (this.name) {
              Text(this.name)
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
            }
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            hovered: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .onClick(() => {
            if (!this.name) {
              this.isShowLoginSheet = true
            }
          })
          .bindSheet(this.isShowLoginSheet!!, this.LoginSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '登录'
            }
          })

          Divider()
            .padding({
              left: 12,
              right: 12
            })
          Row() {
            Image($r('app.media.users'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('切换账号')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Image($r('app.media.right'))
              .fillColor($r('sys.color.icon_fourth'))
              .height(12)
              .width(12)
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            hovered: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .onClick(() => {
            this.isShowAccountlistSheet = true
          })
          .bindSheet(this.isShowAccountlistSheet!!, this.AccountlistSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            showClose: false
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }

      if (this.name) {
        ListItem() {
          Column() {
            Text('系统')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Image($r('app.media.reboot'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width(24)
                Text('重启')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.comp_background_primary'))
                },
                hovered: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '确定重启？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '确定',
                      color: $r('sys.color.font_emphasize')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.dialogControllerProgress.open()
                  const res = await dsmRequest(this.context, '', 'SYNO.Core.System', new url.URLParams({
                    method: 'reboot'
                  }).toString(), 2)
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '重启命令发送成功'
                    })
                  }
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Image($r('app.media.shutdown'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .width(24)
                Text('关机')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.comp_background_primary'))
                },
                hovered: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '确定关机？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '确定',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.dialogControllerProgress.open()
                  const res = await dsmRequest(this.context, '', 'SYNO.Core.System', new url.URLParams({
                    method: 'shutdown'
                  }).toString(), 2)
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '关机命令发送成功'
                    })
                  }
                }
              })
            }
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Row() {
              Image($r('app.media.transfer'))
                .fillColor($r('sys.color.icon_primary'))
                .height(24)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .width(24)
              Text('传输任务')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.comp_background_primary'))
              },
              hovered: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .onClick(() => {
              this.isShowTransfertaskSheet = true
            })
            .bindSheet(this.isShowTransfertaskSheet!!, this.TransfertaskSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '传输任务'
              }
            })
          }
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.setting'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('设置')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Image($r('app.media.right'))
              .fillColor($r('sys.color.icon_fourth'))
              .height(12)
              .width(12)
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            hovered: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .onClick(() => {
            this.isShowSettingSheet = true
          })
          .bindSheet(this.isShowSettingSheet!!, this.SettingSheetBuilder(), {
            preferType: this.preferType
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      if (this.name) {
        ListItem() {
          Button('退出登录')
            .role(ButtonRole.ERROR)
            .width('100%')
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              const data = await promptAction.showActionMenu({
                title: '是否注销会话？',
                buttons: [
                  {
                    text: '是',
                    color: $r('sys.color.warning')
                  },
                  {
                    text: '否',
                    color: $r('sys.color.font_primary')
                  }
                ]
              })
              if (data.index === 0) {
                this.dialogControllerProgress.open()
                await exitAccount(this.context, true)
                this.dialogControllerProgress.close()
              }
              if (data.index === 1) {
                await exitAccount(this.context, false)
              }
              await promptAction.openToast({
                message: '退出成功'
              })
              this.name = ''
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      ListItem()
        .margin({
          bottom: this.preferType === 0 ? 80 : 0
        })
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      this.context.eventHub.on('login', () => {
        this.isShowLoginSheet = true
      })
      this.context.eventHub.on('refreshMe', async () => {
        await this.get()
      })
      await this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshMe')
      this.context.eventHub.off('login')
      display.off('change')
    })
  }
}