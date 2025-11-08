import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'
import { fileIo } from '@kit.CoreFileKit'

@ComponentV2
export default struct Cleardata {
  @Local setting: string[] = []
  @Local allSetting: boolean = false
  @Local cardSetting: boolean = false
  @Local commonSetting: boolean = false
  @Local permissionSetting: boolean = false
  @Local debugSetting: boolean = false
  @Local cache: string[] = []
  @Local allCache: boolean = false
  @Local appCache: boolean = false
  @Local webviewCache: boolean = false
  @Local apiVersionCache: boolean = false
  @Local log: string[] = []
  @Local allLog: boolean = false
  @Local errorLog: boolean = false
  @Local nouse: string[] = []
  @Local allNouse: boolean = false
  @Local tempFileNouse: boolean = false
  @Local commonSettingNouse: boolean = false
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
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'setting'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allSetting!!)
                .onChange((itemName) => {
                  this.setting = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
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
                name: 'cardSetting',
                group: 'setting'
              })
                .select(this.cardSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('卡片')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                .select(this.commonSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('通用')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                .select(this.permissionSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('权限')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                .select(this.debugSetting!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('调试')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'cache'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allCache!!)
                .onChange((itemName) => {
                  this.cache = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
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
                .select(this.appCache!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('应用')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                .select(this.webviewCache!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('Webview')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                name: 'apiVersionCache',
                group: 'cache'
              })
                .select(this.apiVersionCache!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('API版本号')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                if (item === 'apiVersionCache') {
                  const filePath = this.context.cacheDir + '/apiversion.txt'
                  if (fileIo.accessSync(filePath)) {
                    fileIo.unlinkSync(filePath)
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
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'log'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allLog!!)
                .onChange((itemName) => {
                  this.log = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
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
                .select(this.errorLog!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('故障')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
              left: 12,
              right: 12
            })
          Column() {
            Row() {
              CheckboxGroup({
                group: 'nouse'
              })
                .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                .selectAll(this.allNouse!!)
                .onChange((itemName) => {
                  this.nouse = itemName.name
                })
              Text('全部')
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
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
                name: 'tempFileNouse',
                group: 'nouse'
              })
                .select(this.tempFileNouse!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('临时文件')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
                name: 'commonSettingNouse',
                group: 'nouse'
              })
                .select(this.commonSettingNouse!!)
                .shape(CheckBoxShape.ROUNDED_SQUARE)
              Text('无用通用设置')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
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
            this.nouse.forEach((item) => {
              if (item === 'tempFileNouse') {
                const tempDir = this.context.tempDir
                fileIo.listFileSync(tempDir).forEach((item) => {
                  const path = tempDir + '/' + item
                  const isDirectory = fileIo.statSync(path)
                  if (!isDirectory) {
                    fileIo.unlinkSync(path)
                  }
                  if (isDirectory) {
                    fileIo.rmdirSync(path)
                  }
                })
              }
              if (item === 'commonSettingNouse') {
                const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
                  name: 'commonSetting'
                })
                const keys = ['disallowScreenshot', 'cellularDataDownloadRemind']
                keys.forEach((item) => {
                  commonSettingDataPreferences.deleteSync(item)
                })
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