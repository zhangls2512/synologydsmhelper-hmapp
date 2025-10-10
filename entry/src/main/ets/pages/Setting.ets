import { common } from '@kit.AbilityKit'
import { privacyManager } from '@kit.AppGalleryKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { fileIo, picker } from '@kit.CoreFileKit'
import { AccountInfo, getList, set } from '../common/Account'
import { read } from '../common/File'
import openLink from '../common/Openlink'

@ComponentV2
export default struct Setting {
  @Local allService: boolean = false
  @Local agreedPrivacyAgreement: number | undefined = undefined
  @Local accountCount: number = -1
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  async getSetting() {
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    this.allService = commonSettingDataPreferences.getSync('allService', true) as boolean
    try {
      const appPrivacyResults: privacyManager.AppPrivacyResult[] = privacyManager.getAppPrivacyResult()
      this.agreedPrivacyAgreement = appPrivacyResults.find(item => item.type === 1)?.result
    } catch (err) {
      promptAction.openToast({
        message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
      })
    }
    const accounts = await getList()
    this.accountCount = accounts.length
  }

  build() {
    Navigation(this.pageInfos) {
      List() {
        ListItem() {
          Column() {
            Text('账号')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              if (this.accountCount === 0) {
                Row() {
                  Text('导入')
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
                .onClick(async () => {
                  const documentSelectOptions = new picker.DocumentSelectOptions()
                  documentSelectOptions.maxSelectNumber = 1
                  documentSelectOptions.fileSuffixFilters = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.select(documentSelectOptions)
                  if (uris.length === 1) {
                    const filePath = uris[0]
                    const filestring = read(filePath)
                    const accounts = JSON.parse(filestring) as AccountInfo[]
                    const promises = accounts.map(async (item) => {
                      await set({
                        path: item.path,
                        name: item.name,
                        password: item.password,
                        sid: item.sid,
                        did: item.did
                      })
                    })
                    await Promise.all(promises)
                    promptAction.openToast({
                      message: '导入成功'
                    })
                    this.getSetting()
                  }
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
              }

              Row() {
                Text('导出')
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
              .onClick(async () => {
                try {
                  const documentSaveOptions = new picker.DocumentSaveOptions()
                  documentSaveOptions.newFileNames = ['synologydsmhelperaccounts']
                  documentSaveOptions.fileSuffixChoices = ['.txt']
                  const documentViewPicker = new picker.DocumentViewPicker(this.context)
                  const uris = await documentViewPicker.save(documentSaveOptions)
                  const filePath = uris[0]
                  const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE)
                  const array = await getList()
                  fileIo.writeSync(file.fd, JSON.stringify(array))
                  fileIo.closeSync(file)
                  promptAction.openToast({
                    message: '导出成功'
                  })
                } catch (err) {
                  if (err.code !== 13900020) {
                    promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  }
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Row() {
              Text('通用')
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
                name: 'Commonsetting'
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

        ListItem() {
          Column() {
            Row() {
              Text('消息通知')
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
                name: 'Notice'
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

        ListItem() {
          Column() {
            Text('数据与隐私')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('权限管理')
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
                  name: 'Permissionsetting'
                })
              })

              if (typeof (this.agreedPrivacyAgreement) === 'number') {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
              }
              if (this.agreedPrivacyAgreement === 0 || this.agreedPrivacyAgreement === 2) {
                Row() {
                  if (this.agreedPrivacyAgreement === 0 || this.agreedPrivacyAgreement === 2) {
                    Text('阅读并签署隐私协议')
                      .fontColor($r('sys.color.font_emphasize'))
                      .fontWeight(FontWeight.Medium)
                  }
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
                .onClick(async () => {
                  await privacyManager.requestAppPrivacyConsent(this.context)
                  this.getSetting()
                })
              }
              if (this.agreedPrivacyAgreement === 1) {
                Row() {
                  Text('撤回同意隐私协议')
                    .fontColor($r('sys.color.warning'))
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
                  privacyManager.disableService()
                  this.context.terminateSelf()
                })
              }
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
            Text('了解我们如何使用您的数据')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('业务与隐私的声明')
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
                try {
                  const appPrivacyLink =
                    privacyManager.getAppPrivacyMgmtInfo().privacyInfo.find(item => item.type === 1)
                  this.pageInfos.pushPath({
                    name: 'Webview',
                    param: appPrivacyLink?.url
                  })
                } catch (err) {
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
                Text('第三方SDK列表')
                  .enableAutoSpacing(true)
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
                openLink('https://docs.qq.com/doc/p/142d00b55db803faf04f75a8486617bd4e51b07c')
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('已收集个人信息清单')
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
                  name: 'Infolist'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('隐私声明摘要')
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
                openLink('https://docs.qq.com/doc/p/396e155d30adf768c0efcac3d14bebca4876143c')
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
            Text('更多')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('应用服务模式')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text(this.allService ? '全量模式' : '基本模式')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
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
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Servicemode'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('其他')
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
                  name: 'Moresetting'
                })
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
            Row() {
              Text('关于')
                .fontWeight(FontWeight.Medium)
              Blank()
              Text('版本 ')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
              Text($r('app.string.app_version'))
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
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
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .width('100%')
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'About'
              })
            })

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('服务协议与规则')
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
                name: 'Agreements'
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
      }
      .nestedScroll({
        scrollForward: NestedScrollMode.SELF_ONLY,
        scrollBackward: NestedScrollMode.SELF_ONLY
      })
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .hideBackButton(true)
    .padding({
      top: $r('sys.float.ohos_id_elements_margin_vertical_m')
    })
    .title('设置')
    .titleMode(NavigationTitleMode.Mini)
    .onAppear(() => {
      this.getSetting()
      this.context.eventHub.on('refreshSetting', () => {
        this.getSetting()
      })
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshSetting')
    })
  }
}