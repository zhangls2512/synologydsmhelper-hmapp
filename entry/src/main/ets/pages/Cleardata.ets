import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'
import { asset } from '@kit.AssetStoreKit'
import { fileIo } from '@kit.CoreFileKit'
import { stringToArray } from '../common/Crypto'
import { getPasswordList, getTypeInfoList } from '../common/Dataget'

@ComponentV2
export default struct Cleardata {
  @Local setting: string[] = []
  @Local allSetting: boolean = false
  @Local cloudbackupSetting: boolean = false
  @Local dataSetting: boolean = false
  @Local commonSetting: boolean = false
  @Local permissionSetting: boolean = false
  @Local debugSetting: boolean = false
  @Local cache: string[] = []
  @Local allCache: boolean = false
  @Local appCache: boolean = false
  @Local webviewCache: boolean = false
  @Local invitationQrcodeCache: boolean = false
  @Local log: string[] = []
  @Local allLog: boolean = false
  @Local errorLog: boolean = false
  @Local nouse: string[] = []
  @Local allNouse: boolean = false
  @Local speakSettingNouse: boolean = false
  @Local oldaccountNouse: boolean = false
  @Local passwordIconNouse: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    List() {
      ListItem() {
        Column() {
          Text('设置')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'setting'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .selectAll(this.allSetting!!)
                .onChange((itemName) => {
                  this.setting = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
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
              Checkbox({
                name: 'cloudbackupSetting',
                group: 'setting'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.cloudbackupSetting!!)
              Column() {
                Text('云备份')
                  .fontWeight(FontWeight.Medium)
                Text('自动同步等')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'dataSetting',
                group: 'setting'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.dataSetting!!)
              Column() {
                Text('数据')
                  .fontWeight(FontWeight.Medium)
                Text('设备间自动同步等')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'commonSetting',
                group: 'setting'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.commonSetting!!)
              Column() {
                Text('通用')
                  .fontWeight(FontWeight.Medium)
                Text('应用等')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'permissionSetting',
                group: 'setting'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.permissionSetting!!)
              Column() {
                Text('权限')
                  .fontWeight(FontWeight.Medium)
                Text('写入剪贴板')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'debugSetting',
                group: 'setting'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.debugSetting!!)
              Column() {
                Text('调试')
                  .fontWeight(FontWeight.Medium)
                Text('自动上传故障日志等')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
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
        Button('清理设置')
          .enabled(this.setting.length > 0)
          .role(ButtonRole.ERROR)
          .onClick(async () => {
            const promptAction = this.getUIContext().getPromptAction()
            const data = await promptAction.showDialog({
              title: '提示',
              message: '清理成功后将恢复所选设置为默认，无法恢复。确定清理？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '清理',
                  color: $r('sys.color.warning')
                }
              ]
            })
            if (data.index === 1) {
              this.setting.forEach((item) => {
                if (item === 'dataSetting') {
                  const keys = [
                    'autoSyncTables',
                    'autoSyncDevices',
                    'autoBackupTables',
                    'pauseAutoSyncWhenLowBatteryCapacityLevel',
                    'pauseAutoSyncWhenPowerSave',
                    'pauseAutoBackupWhenLowBatteryCapacityLevel',
                    'pauseAutoBackupWhenPowerSave'
                  ]
                  const dataPreferences = preferences.getPreferencesSync(this.context, {
                    name: 'dataSetting'
                  })
                  keys.forEach((item) => {
                    dataPreferences.deleteSync(item)
                    dataPreferences.flushSync()
                  })
                  return
                }
                preferences.deletePreferences(this.context, item)
              })
              promptAction.openToast({
                message: '清理成功'
              })
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
      .width('100%')

      ListItem() {
        Column() {
          Text('缓存')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'cache'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .selectAll(this.allCache!!)
                .onChange((itemName) => {
                  this.cache = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
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
              Checkbox({
                name: 'appCache',
                group: 'cache'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.appCache!!)
              Column() {
                Text('应用')
                  .fontWeight(FontWeight.Medium)
                Text('应用缓存')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'webviewCache',
                group: 'cache'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.webviewCache!!)
              Column() {
                Text('Webview')
                  .fontWeight(FontWeight.Medium)
                Text('Webview缓存')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'invitationQrcodeCache',
                group: 'cache'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.invitationQrcodeCache!!)
              Column() {
                Text('邀请二维码图片')
                  .fontWeight(FontWeight.Medium)
                Text('邀请二维码图片缓存')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))

          Text() {
            Span('可前往')
              .fontColor($r('sys.color.font_secondary'))
            Span('系统设置')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                this.context.startAbility({
                  bundleName: 'com.huawei.hmos.settings',
                  abilityName: 'com.huawei.hmos.settings.MainAbility',
                  uri: 'storage_settings'
                })
              })
            Span('清理更多缓存。')
              .fontColor($r('sys.color.font_secondary'))
          }
          .fontSize($r('sys.float.ohos_id_text_size_body3'))
          .margin({
            top: 6,
            left: 12,
            right: 12
          })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Button('清理缓存')
          .enabled(this.cache.length > 0)
          .role(ButtonRole.ERROR)
          .onClick(async () => {
            const promptAction = this.getUIContext().getPromptAction()
            const data = await promptAction.showDialog({
              title: '提示',
              message: '清理成功后性能可能略微降低，但不会影响正常使用。确定清理？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '清理',
                  color: $r('sys.color.warning')
                }
              ]
            })
            if (data.index === 1) {
              this.cache.forEach((item) => {
                if (item === 'appCache') {
                  const cacheDir = this.context.cacheDir
                  const filenames = fileIo.listFileSync(cacheDir)
                  for (let i = 0; i < filenames.length; i++) {
                    const path = cacheDir + '/' + filenames[i]
                    if (fileIo.statSync(path).isDirectory()) {
                      fileIo.rmdirSync(path)
                    } else {
                      fileIo.unlinkSync(path)
                    }
                  }
                }
                if (item === 'webviewCache') {
                  webview.WebviewController.removeAllCache(true)
                }
                if (item === 'invitationQrcodeCache') {
                  try {
                    const invitationcodeQrcodeDir = this.context.filesDir + '/media/invitationqrcode'
                    const filenames = fileIo.listFileSync(invitationcodeQrcodeDir)
                    for (let i = 0; i < filenames.length; i++) {
                      fileIo.unlinkSync(invitationcodeQrcodeDir + '/' + filenames[i])
                    }
                  } catch (err) {
                    if (err.code !== 13900002) {
                      promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
                }
              })
              promptAction.openToast({
                message: '清理成功'
              })
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
      .width('100%')

      ListItem() {
        Column() {
          Text('日志')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'log'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .selectAll(this.allLog!!)
                .onChange((itemName) => {
                  this.log = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
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
              Checkbox({
                name: 'errorLog',
                group: 'log'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.errorLog!!)
              Column() {
                Text('故障')
                  .fontWeight(FontWeight.Medium)
                Text('故障日志')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
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
        Button('清理日志')
          .enabled(this.log.length > 0)
          .role(ButtonRole.ERROR)
          .onClick(async () => {
            const promptAction = this.getUIContext().getPromptAction()
            const data = await promptAction.showDialog({
              title: '提示',
              message: '日志有助于开发者定位问题。清理成功后无法恢复，确定清理？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '清理',
                  color: $r('sys.color.warning')
                }
              ]
            })
            if (data.index === 1) {
              this.log.forEach((item) => {
                if (item === 'errorLog') {
                  try {
                    const errorLogDir = this.context.filesDir + '/log/error'
                    const filenames = fileIo.listFileSync(errorLogDir)
                    for (let i = 0; i < filenames.length; i++) {
                      fileIo.unlinkSync(errorLogDir + '/' + filenames[i])
                    }
                  } catch (err) {
                    if (err.code !== 13900002) {
                      promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
                }
              })
              promptAction.openToast({
                message: '清理成功'
              })
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
      .width('100%')

      ListItem() {
        Column() {
          Text('无用数据')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 6,
              left: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'nouse'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .selectAll(this.allNouse!!)
                .onChange((itemName) => {
                  this.nouse = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
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
              Checkbox({
                name: 'speakSettingNouse',
                group: 'nouse'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.speakSettingNouse!!)
              Column() {
                Text('AI助手设置数据')
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                Text('语音播报、连续对话')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'oldaccountNouse',
                group: 'nouse'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.oldaccountNouse!!)
              Column() {
                Text('旧账号数据')
                  .fontWeight(FontWeight.Medium)
                Text('accessToken、登录到期时间')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
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
              Checkbox({
                name: 'passwordIconNouse',
                group: 'nouse'
              })
                .shape(CheckBoxShape.ROUNDED_SQUARE)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .select(this.passwordIconNouse!!)
              Column() {
                Text('无用密码图标图片')
                  .fontWeight(FontWeight.Medium)
                Text('无用密码图标图片文件')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
                  .width('90%')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
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
        Button('清理无用数据')
          .enabled(this.nouse.length > 0)
          .role(ButtonRole.ERROR)
          .onClick(() => {
            this.nouse.forEach(async (item) => {
              if (item === 'oldaccountNouse') {
                try {
                  const query: asset.AssetMap = new Map()
                  query.set(asset.Tag.ALIAS, stringToArray('accessToken'))
                  asset.removeSync(query)
                  await preferences.deletePreferences(this.context, {
                    name: 'login'
                  })
                } catch (err) {
                  if (err.code !== 24000002) {
                    promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  }
                }
              }
              if (item === 'speakSettingNouse') {
                preferences.deletePreferences(this.context, 'speakSetting')
              }
              if (item === 'passwordIconNouse') {
                try {
                  const passwordIconDir = this.context.filesDir + '/media/passwordicon'
                  const passwordIconFileArray =
                    fileIo.listFileSync(passwordIconDir).map(item => passwordIconDir + '/' + item)
                  const passwordArray = await getPasswordList()
                  const passwordIconPathArray: string[] = []
                  passwordArray.forEach((item) => {
                    const index = item.info.findIndex(infoItem => infoItem.type === '图标')
                    if (index !== -1) {
                      passwordIconPathArray.push(item.info[index].value.replace('file://com.zhangxm.aipasswordmemo',
                        ''))
                    }
                  })
                  const infoArray = await getTypeInfoList('图标')
                  const infoIconPathArray = infoArray.map(item => item.replace('file://com.zhangxm.aipasswordmemo', ''))
                  const iconPathSet = new Set(passwordIconPathArray.concat(infoIconPathArray))
                  const nousePasswordIconFilePathArray = passwordIconFileArray.filter(item => !iconPathSet.has(item))
                  nousePasswordIconFilePathArray.forEach(item => {
                    fileIo.unlinkSync(item)
                  })
                } catch (err) {
                  if (err.code !== 13900002) {
                    promptAction.openToast({
                      message: '发生错误，错误码：' + err.code
                    })
                  }
                }
              }
            })
            promptAction.openToast({
              message: '清理成功'
            })
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
      .width('100%')
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onDisAppear(() => {
      this.context.eventHub.emit('refreshSetting')
    })
  }
}