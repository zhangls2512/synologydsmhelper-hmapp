import { common } from '@kit.AbilityKit'
import { FunctionComponent, FunctionController } from '@kit.AgentFrameworkKit'
import { updateManager } from '@kit.AppGalleryKit'
import { promptAction } from '@kit.ArkUI'
import { call } from '@kit.TelephonyKit'
import openLink from '../common/Openlink'
import copy from '../common/Pasteboard'

@Builder
export function AboutBuilder() {
  About()
}

@ComponentV2
struct About {
  @Local hasUpdate: number = -1
  @Local updateLoading: boolean = false
  @Local isAgentSupport: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  controller: FunctionController = new FunctionController()

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Image($r('app.media.foreground'))
              .height(80)
              .width(80)
              .gesture(
                TapGesture({
                  count: 2
                })
                  .onAction(async () => {
                    const promptAction = this.getUIContext().getPromptAction()
                    const data = await promptAction.showActionMenu({
                      title: '调试',
                      buttons: [
                        {
                          text: '设置',
                          color: $r('sys.color.font_primary')
                        },
                        {
                          text: '信息',
                          color: $r('sys.color.font_primary')
                        }
                      ]
                    })
                    if (data.index === 0) {
                      this.pageInfos.pushPath({
                        name: 'Debugsetting'
                      })
                    }
                    if (data.index === 1) {
                      promptAction.openToast({
                        message: '暂未上线，敬请期待'
                      })
                    }
                  })
              )
            Text($r('app.string.app_name'))
              .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
              .fontWeight(FontWeight.Bold)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .textAlign(TextAlign.Center)
          }
          .width('100%')
        }

        ListItem() {
          Column() {
            Row() {
              Column() {
                Text('版本信息')
                  .fontWeight(FontWeight.Medium)
                Text($r('app.string.app_version'))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              if (!this.updateLoading) {
                if (this.hasUpdate === -1) {
                  Text('检查更新')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                }
                if (this.hasUpdate === 0) {
                  Text('已是最新版本')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                }
                if (this.hasUpdate === 1) {
                  Text('有新版本')
                    .fontColor($r('sys.color.font_emphasize'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                }
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              if (this.updateLoading) {
                LoadingProgress()
                  .height(20)
                  .width(20)
              }
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(async () => {
              try {
                if (this.hasUpdate !== 1) {
                  this.updateLoading = true
                  const res = await updateManager.checkAppUpdate(this.context)
                  this.updateLoading = false
                  this.hasUpdate = res.updateAvailable
                  if (res.updateAvailable === 1) {
                    updateManager.showUpdateDialog(this.context)
                  }
                }
                if (this.hasUpdate === 1) {
                  updateManager.showUpdateDialog(this.context)
                }
              } catch (err) {
                this.updateLoading = false
                this.hasUpdate = -1
                promptAction.openToast({
                  message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                })
              }
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Column() {
                Text('更新日志')
                  .fontWeight(FontWeight.Medium)
                Text('https://www.zhangls2512.cn/product/updatelog/aipasswordmemohmapp')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Webview',
                param: 'https://www.zhangls2512.cn/product/updatelog/aipasswordmemohmapp'
              })
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Column() {
                Text('使用教程')
                  .fontWeight(FontWeight.Medium)
                Text('https://docs.qq.com/doc/p/ad13731bb5a5562d7e7b11ee738928c6f1974b51')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              openLink('https://docs.qq.com/doc/p/ad13731bb5a5562d7e7b11ee738928c6f1974b51')
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('应用详情')
                .fontWeight(FontWeight.Medium)
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.context.openLink('https://appgallery.huawei.com/app/detail?id=com.zhangxm.aipasswordmemo')
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('评论应用')
                .fontWeight(FontWeight.Medium)
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.context.openLink('https://appgallery.huawei.com/app/detail?id=com.zhangxm.aipasswordmemo&action=write-review')
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('意见反馈')
                .fontWeight(FontWeight.Medium)
              Blank()
              Image($r('app.media.right'))
                .fillColor($r('sys.color.icon_fourth'))
                .height(12)
                .width(12)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Feedback'
              })
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        if (this.isAgentSupport) {
          ListItem() {
            FunctionComponent({
              agentId: 'agentdf468e04a1474579bbf0653f19c929ee',
              options: {
                title: '智能客服'
              },
              controller: this.controller,
              onError: (err) => {
                promptAction.openToast({
                  message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                })
              }
            })
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
          .width('100%')
        }
        ListItem() {
          Column() {
            Text('人工客服')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Column() {
                  Text('电话')
                    .fontWeight(FontWeight.Medium)
                  Text('18846496985')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                call.makeCall('18846496985')
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('邮箱')
                    .fontWeight(FontWeight.Medium)
                  Text('2300990296@qq.com')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.startAbilityByType('mail', {
                  email: ['2300990296@qq.com']
                }, {
                  onError: () => {
                  }
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('微信')
                    .fontWeight(FontWeight.Medium)
                  Text('gerenyinsi_z07x17m')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                copy('gerenyinsi_z07x17m')
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('QQ群')
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                  Text('https://qm.qq.com/q/8Ugei32784')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                openLink('https://qm.qq.com/q/8Ugei32784')
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('MeoW频道')
                    .enableAutoSpacing(true)
                    .fontWeight(FontWeight.Medium)
                  Text('接收官方通知，包括但不限于公告、活动')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.context.openLink('https://www.chuckfang.com/MeoW/appLinking?channelId=e734229e5e9141ba83682e72ecd9df41')
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
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
            Text('媒体')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Column() {
                  Text('官网')
                    .fontWeight(FontWeight.Medium)
                  Text('https://www.zhangls2512.cn/index')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                openLink('https://www.zhangls2512.cn/index')
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('哔哩哔哩')
                    .fontWeight(FontWeight.Medium)
                  Text('https://space.bilibili.com/448824492')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                openLink('https://space.bilibili.com/448824492')
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('Gitcode')
                    .fontWeight(FontWeight.Medium)
                  Text('https://gitcode.com/zhangls2512/aipasswordmemo-hmapp')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                openLink('https://gitcode.com/zhangls2512/aipasswordmemo-hmapp')
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
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
            Text('资质证照')
              .fontColor($r('sys.color.font_emphasize'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'License'
                })
              })
            Text('版权所有 ©️ 2025 张轩铭 保留一切权利')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
              .textAlign(TextAlign.Center)
          }
          .width('100%')
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
    .title('关于')
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      try {
        this.isAgentSupport =
          await this.controller.isAgentSupport(this.context, 'agentdf468e04a1474579bbf0653f19c929ee')
      } catch (err) {
        promptAction.openToast({
          message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
    })
  }
}