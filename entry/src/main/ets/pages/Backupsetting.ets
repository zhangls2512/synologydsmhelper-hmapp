import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LengthMetrics, promptAction, } from '@kit.ArkUI'
import { HdsNavDestination } from '@kit.UIDesignKit'
import { deviceInfo } from '@kit.BasicServicesKit'

@Builder
export function BackupsettingBuilder() {
  Backupsetting()
}

@ComponentV2
struct Backupsetting {
  @Local autoTypes: string[] = []
  @Local pauseAutoWhenLowBatteryCapacityLevel: boolean = false
  @Local pauseAutoWhenPowerSave: boolean = false
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  backupSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'backupSetting'
  })
  typeArray: string[] = ['相册', '文档', '桌面']

  async getSetting() {
    this.autoTypes = this.backupSettingDataPreferences.getSync('autoTypes', []) as string[]
    this.pauseAutoWhenLowBatteryCapacityLevel =
      this.backupSettingDataPreferences.getSync('pauseAutoWhenLowBatteryCapacityLevel', true) as boolean
    this.pauseAutoWhenPowerSave = this.backupSettingDataPreferences.getSync('pauseAutoWhenPowerSave', true) as boolean
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('自动备份')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              ForEach(this.typeArray, (item: string, index) => {
                if (index !== 0 && deviceInfo.deviceType !== 'phone') {
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                }
                if (index === 0 || (index > 0 && deviceInfo.deviceType !== 'phone')) {
                  Row() {
                    Text(item)
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Toggle({
                      type: ToggleType.Switch,
                      isOn: this.autoTypes.includes(item)
                    })
                      .onChange(async (isOn) => {
                        let autoTypes: string[] = []
                        if (!isOn) {
                          autoTypes = this.autoTypes.filter(inItem => inItem !== item)
                        }
                        if (isOn) {
                          autoTypes = [...this.autoTypes, item]
                        }
                        this.backupSettingDataPreferences.putSync('autoTypes', autoTypes)
                        this.backupSettingDataPreferences.flushSync()
                        await this.getSetting()
                      })
                  }
                  .borderRadius(12)
                  .padding(12)
                  .width('100%')
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
            Text('手动备份')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              ForEach(this.typeArray, (item: string, index) => {
                if (index !== 0 && deviceInfo.deviceType !== 'phone') {
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                }
                if (index === 0 || (index > 0 && deviceInfo.deviceType !== 'phone')) {
                  Row() {
                    Text(item)
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
                      .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                        $r('sys.color.ohos_id_color_card_bg'))
                    },
                    pressed: {
                      .backgroundColor($r('sys.color.interactive_pressed'))
                    }
                  })
                  .width('100%')
                  .onHover((isHover) => {
                    if (!isHover) {
                      this.hoverId = -1
                    }
                    if (isHover) {
                      this.hoverId = index
                    }
                  })
                  .onClick(async () => {
                    await promptAction.openToast({
                      message: '敬请期待'
                    })
                  })
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('暂停自动备份')
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
                Text('电池电量低')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pauseAutoWhenLowBatteryCapacityLevel!!
                })
                  .onChange((isOn) => {
                    this.backupSettingDataPreferences.putSync('pauseAutoWhenLowBatteryCapacityLevel', isOn)
                    this.backupSettingDataPreferences.flushSync()
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
                Text('系统开启 (超级) 省电模式')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pauseAutoWhenPowerSave!!
                })
                  .onChange((isOn) => {
                    this.backupSettingDataPreferences.putSync('pauseAutoWhenPowerSave', isOn)
                    this.backupSettingDataPreferences.flushSync()
                  })
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
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      content: {
        title: {
          mainTitle: '备份'
        }
      },
      enableComponentSafeArea: true
    })
    .onAppear(async () => {
      await this.getSetting()
    })
  }
}