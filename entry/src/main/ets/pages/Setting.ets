import { common } from '@kit.AbilityKit'
import { appAccount } from '@kit.BasicServicesKit'
import { privacyManager } from '@kit.AppGalleryKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { formProvider } from '@kit.FormKit'
import { get, getAccountInfo } from '../common/Accesstoken'
import getCloudServiceStatus from '../common/Cloudservice'
import openLink from '../common/Openlink'
import { checkPermission } from '../common/Permission'
import request from '../common/Request'
import { Account } from './Huaweiaccount'

@ComponentV2
export default struct Setting {
  @Local allService: boolean = false
  @Local agreedPrivacyAgreement: number | undefined = undefined
  @Local email: string = ''
  @Local isBindHuaweiAccount: boolean = false
  @Local cloudService: boolean = false
  @Local accountLoading: boolean = false
  @Local accountDataSync: boolean = false
  @Local accountDataSyncEnabled: boolean = false
  @Local autoLoginByHuaweiAccount: boolean = false
  @Local autoLoginByPasskey: boolean = false
  @Local accessToken: string = ''
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
    const accountInfo = await getAccountInfo()
    this.email = accountInfo.email
    this.accessToken = await get()
    if (this.accessToken) {
      const res = await checkPermission('ohos.permission.DISTRIBUTED_DATASYNC')
      this.accountDataSyncEnabled = res
      if (res) {
        const appAccountManager = appAccount.createAppAccountManager()
        this.accountDataSync = await appAccountManager.checkDataSyncEnabled('default')
      }
      this.autoLoginByHuaweiAccount = commonSettingDataPreferences.getSync('autoLoginByHuaweiAccount', false) as boolean
      if (this.allService) {
        this.accountLoading = true
        const accountres = await request('/account/getExternalAccount', {
          accessToken: this.accessToken
        })
        if (accountres !== 'fail') {
          const account = JSON.parse(accountres).data as Account[]
          this.isBindHuaweiAccount = account.some(item => item.platform === 'huawei')
        }
        this.cloudService = await getCloudServiceStatus()
        this.accountLoading = false
      }
    }
  }

  build() {
    Navigation(this.pageInfos) {
      List() {
        if (this.accessToken) {
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
                if (!this.email) {
                  Row() {
                    Text('绑定邮箱')
                      .fontColor($r('sys.color.font_emphasize'))
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
                      name: 'Email'
                    })
                  })

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                }
                Row() {
                  if (!this.isBindHuaweiAccount) {
                    Text('绑定华为账号')
                      .fontColor($r('sys.color.font_emphasize'))
                      .fontWeight(FontWeight.Medium)
                  }
                  if (this.isBindHuaweiAccount) {
                    Text('解绑华为账号')
                      .fontColor($r('sys.color.warning'))
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
                .onClick(() => {
                  if (!this.email) {
                    promptAction.openToast({
                      message: '轩铭 2512 统一账号未绑定邮箱，无法使用此功能'
                    })
                    return
                  }
                  this.pageInfos.pushPath({
                    name: 'Huaweiaccount'
                  })
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Column() {
                    Text('华为账号静默登录')
                      .fontWeight(FontWeight.Medium)
                    Text('需绑定华为账号')
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .margin({
                        top: $r('sys.float.ohos_id_text_margin_vertical')
                      })
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.autoLoginByHuaweiAccount!!
                  })
                    .enabled(!this.autoLoginByPasskey)
                    .onChange((isOn) => {
                      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                        name: 'commonSetting'
                      })
                      commonSettingDataPreferences.putSync('autoLoginByHuaweiAccount', isOn)
                      commonSettingDataPreferences.flushSync()
                    })
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('新增通行密钥')
                    .fontColor($r('sys.color.font_emphasize'))
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
                  if (!this.email) {
                    promptAction.openToast({
                      message: '轩铭 2512 统一账号未绑定邮箱，无法使用此功能'
                    })
                    return
                  }
                  if (1 === 1) {
                    promptAction.openToast({
                      message: '暂未上线，敬请期待'
                    })
                    return
                  }
                  this.pageInfos.pushPath({
                    name: 'Newpasskey'
                  })
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Column() {
                    Text('通行密钥静默登录')
                      .fontWeight(FontWeight.Medium)
                    Text('需新增通行密钥')
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .margin({
                        top: $r('sys.float.ohos_id_text_margin_vertical')
                      })
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.autoLoginByPasskey!!
                  })
                  //.enabled(!this.autoLoginByHuaweiAccount)
                    .enabled(false)
                    .onChange((isOn) => {
                      const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                        name: 'commonSetting'
                      })
                      commonSettingDataPreferences.putSync('autoLoginByPasskey', isOn)
                      commonSettingDataPreferences.flushSync()
                    })
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('设备间同步')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.accountDataSync!!
                  })
                    .enabled(this.accountDataSyncEnabled)
                    .onChange(async (isOn) => {
                      try {
                        const appAccountManager = appAccount.createAppAccountManager()
                        await appAccountManager.setDataSyncEnabled('default', isOn)
                      } catch (err) {
                        this.accountDataSync = false
                        promptAction.openToast({
                          message: '发生错误，错误码：' + err.code
                        })
                      }
                    })
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')
              }
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding($r('sys.float.ohos_id_corner_radius_mark'))

              Text('账号中心')
                .fontColor($r('sys.color.font_emphasize'))
                .fontSize($r('sys.float.ohos_id_text_size_body3'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: 6,
                  left: 12,
                  right: 12
                })
                .onClick(() => {
                  openLink('https://www.zhangls2512.cn/product/account/panel')
                })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          if (this.accountLoading) {
            ListItem() {
              LoadingProgress()
                .height(20)
                .width(20)
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          }
          if (this.cloudService && !this.accountLoading) {
            ListItem() {
              Column() {
                Text('云备份')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    bottom: 6,
                    left: 12
                  })
                Column() {
                  Row() {
                    Text('自动开启')
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
                      name: 'Autocloudbackupsetting'
                    })
                  })

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Text('管理')
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
                      name: 'Cloudbackupmanage'
                    })
                  })

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
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
                  .onClick(() => {
                    this.pageInfos.pushPath({
                      name: 'Cloudbackupimport'
                    })
                  })

                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Text('密钥')
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
                      name: 'Key'
                    })
                  })
                }
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))

                Text('安全保障说明')
                  .fontColor($r('sys.color.font_emphasize'))
                  .fontSize($r('sys.float.ohos_id_text_size_body3'))
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    top: 6,
                    left: 12,
                    right: 12
                  })
                  .onClick(() => {
                    openLink('https://docs.qq.com/doc/p/2fc9d7d60e5b79dcc09dec8251cb049fb29c7705')
                  })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          }
        }
        ListItem() {
          Column() {
            Text('数据')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('设备间同步')
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
                  name: 'Tablesync'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('导入与导出')
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
                  name: 'DataInOut'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('备份与恢复')
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
                  name: 'DataBackupRecovery'
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('通用')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
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

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('卡片')
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
                formProvider.openFormManager({
                  bundleName: 'com.zhangxm.aipasswordmemo'
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
                openLink('https://docs.qq.com/doc/p/2bde62f6c2aaea97fbcca04c929c284005326d37')
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
                openLink('https://docs.qq.com/doc/p/bdc2799638a46746599c68d82697b10a2becb2e4')
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