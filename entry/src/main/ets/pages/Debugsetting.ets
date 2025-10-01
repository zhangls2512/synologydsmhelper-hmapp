import { appRecovery, common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'

@Builder
export function DebugsettingBuilder() {
  Debugsetting()
}

@ComponentV2
struct Debugsetting {
  @Local globalErrorShowTypeIndex: number = 0
  @Local globalErrorShowTypeValue: string = 'Toast'
  @Local saveErrorLog: boolean = false
  @Local autoUploadErrorLog: boolean = false
  @Local showMemoryLevelChange: boolean = false
  @Local processCache: boolean = false
  @Local lowBatteryCapacityLevelIndex: number = 3
  @Local lowBatteryCapacityLevelValue: string = '低'
  @Local showNetAvailableStatusChange: boolean = false
  @Local showNetBlockStatusChange: boolean = false
  @Local showNetLost: boolean = false
  @Local showNetCapabilitiesChange: boolean = false
  @Local showNetQosChange: boolean = false
  @Local showNetSceneChange: boolean = false
  @Local autoReportHighLatency: boolean = false
  @Local highLatencyThreshold: string = '200'
  @Local optimizeParserBudget: boolean = true
  @Local destroyModeIndex: number = 0
  @Local destroyModeValue: string = '普通'
  @Local allService: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  debugSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'debugSetting'
  })
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  getSetting() {
    const globalErrorShowType = this.debugSettingDataPreferences.getSync('globalErrorShowType', 0)
    this.globalErrorShowTypeIndex = globalErrorShowType as number
    if (globalErrorShowType === 0) {
      this.globalErrorShowTypeValue = 'Toast'
    }
    if (globalErrorShowType === 1) {
      this.globalErrorShowTypeValue = 'Dialog'
    }
    this.saveErrorLog = this.debugSettingDataPreferences.getSync('saveErrorLog', true) as boolean
    this.autoUploadErrorLog = this.debugSettingDataPreferences.getSync('autoUploadErrorLog', true) as boolean
    this.showMemoryLevelChange = this.debugSettingDataPreferences.getSync('showMemoryLevelChange', false) as boolean
    this.processCache = this.debugSettingDataPreferences.getSync('processCache', true) as boolean
    const lowBatteryCapacityLevel = this.debugSettingDataPreferences.getSync('lowBatteryCapacityLevel', 4)
    this.lowBatteryCapacityLevelIndex = (lowBatteryCapacityLevel as number) - 1
    if (lowBatteryCapacityLevel === 1) {
      this.lowBatteryCapacityLevelValue = '满'
    }
    if (lowBatteryCapacityLevel === 2) {
      this.lowBatteryCapacityLevelValue = '高'
    }
    if (lowBatteryCapacityLevel === 3) {
      this.lowBatteryCapacityLevelValue = '正常'
    }
    if (lowBatteryCapacityLevel === 4) {
      this.lowBatteryCapacityLevelValue = '低'
    }
    if (lowBatteryCapacityLevel === 5) {
      this.lowBatteryCapacityLevelValue = '告警'
    }
    if (lowBatteryCapacityLevel === 6) {
      this.lowBatteryCapacityLevelValue = '极低'
    }
    if (lowBatteryCapacityLevel === 7) {
      this.lowBatteryCapacityLevelValue = '关机'
    }
    this.autoReportHighLatency = this.debugSettingDataPreferences.getSync('autoReportHighLatency', true) as boolean
    this.showNetAvailableStatusChange =
      this.debugSettingDataPreferences.getSync('showNetAvailableStatusChange', false) as boolean
    this.showNetBlockStatusChange =
      this.debugSettingDataPreferences.getSync('showNetBlockStatusChange', false) as boolean
    this.showNetLost = this.debugSettingDataPreferences.getSync('showNetLost', false) as boolean
    this.showNetCapabilitiesChange =
      this.debugSettingDataPreferences.getSync('showNetCapabilitiesChange', false) as boolean
    this.showNetQosChange = this.debugSettingDataPreferences.getSync('showNetQosChange', false) as boolean
    this.showNetSceneChange = this.debugSettingDataPreferences.getSync('showNetSceneChange', false) as boolean
    this.highLatencyThreshold = String(this.debugSettingDataPreferences.getSync('highLatencyThreshold', 200))
    this.optimizeParserBudget = this.debugSettingDataPreferences.getSync('optimizeParserBudget', true) as boolean
    const destroyMode = this.debugSettingDataPreferences.getSync('destroyMode', 0)
    this.destroyModeIndex = destroyMode as number
    if (destroyMode === 0) {
      this.destroyModeValue = '普通'
    }
    if (destroyMode === 1) {
      this.destroyModeValue = '快速'
    }
    const allService = this.commonSettingDataPreferences.getSync('allService', true)
    this.allService = allService as boolean
    if (!allService) {
      this.autoUploadErrorLog = false
    }
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('基础')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('故障展示方式')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: 'Toast' },
                  { value: 'Dialog' }
                ])
                  .selected(this.globalErrorShowTypeIndex!!)
                  .value(this.globalErrorShowTypeValue!!)
                  .onSelect((index) => {
                    this.debugSettingDataPreferences.putSync('globalErrorShowType', index)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('保存故障日志')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.saveErrorLog!!
                })
                  .enabled(this.allService)
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('saveErrorLog', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('自动上传故障日志')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoUploadErrorLog!!
                })
                  .enabled(this.allService)
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('autoUploadErrorLog', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('自动上传故障日志类型')
                  .fontWeight('medium')
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
                  name: 'Autouploaderrorlogtype'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('故障日志')
                  .fontWeight('medium')
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
                  name: 'Errorlog'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('内存占用级别变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showMemoryLevelChange!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('showMemoryLevelChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('进程缓存后快速启动')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.processCache!!
                })
                  .onChange(async (isOn) => {
                    this.debugSettingDataPreferences.putSync('processCache', isOn)
                    this.debugSettingDataPreferences.flushSync()
                    const promptAction = this.getUIContext().getPromptAction()
                    const data = await promptAction.showDialog({
                      title: '提示',
                      message: '设置成功，需重启应用生效，是否重启？',
                      buttons: [
                        {
                          text: '取消',
                          color: $r('sys.color.font_primary')
                        },
                        {
                          text: '重启',
                          color: $r('sys.color.font_emphasize')
                        }
                      ]
                    })
                    if (data.index === 1) {
                      const applicationContext = this.context.getApplicationContext()
                      applicationContext.restartApp({
                        bundleName: 'com.zhangxm.aipasswordmemo',
                        abilityName: 'EntryAbility'
                      })
                    }
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
                Text('电池电量低阈值')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '满' },
                  { value: '高' },
                  { value: '正常' },
                  { value: '低' },
                  { value: '告警' },
                  { value: '极低' },
                  { value: '关机' }
                ])
                  .selected(this.lowBatteryCapacityLevelIndex!!)
                  .value(this.lowBatteryCapacityLevelValue!!)
                  .onSelect((index) => {
                    this.debugSettingDataPreferences.putSync('lowBatteryCapacityLevel', index + 1)
                    this.debugSettingDataPreferences.flushSync()
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
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('应用')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('沙箱文件删除工具')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight('medium')
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
                  name: 'Deletefile'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('清除所有数据并退出')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight('medium')
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
                const promptAction = this.getUIContext().getPromptAction()
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '此操作将清除应用全部数据，同时撤销应用向用户申请的权限。确定清除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '清除',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  const applicationContext = this.context.getApplicationContext()
                  applicationContext.clearUpApplicationData()
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('终止所有进程并退出')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight('medium')
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
                const promptAction = this.getUIContext().getPromptAction()
                const data = await promptAction.showActionMenu({
                  title: '是否清除页面堆栈？',
                  buttons: [
                    {
                      text: '是',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '否',
                      color: $r('sys.color.font_primary')
                    }
                  ]
                })
                if (data.index === 0) {
                  const applicationContext = this.context.getApplicationContext()
                  applicationContext.killAllProcesses(true)
                }
                if (data.index === 1) {
                  const applicationContext = this.context.getApplicationContext()
                  applicationContext.killAllProcesses(false)
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
            Text('应用恢复')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('重启当前进程')
                  .fontWeight('medium')
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
                appRecovery.restartApp()
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('保存当前状态')
                  .fontWeight('medium')
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
                const res = appRecovery.saveAppState()
                if (res) {
                  promptAction.openToast({
                    message: '保存成功'
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('设置')
                  .fontWeight('medium')
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
                  name: 'Recoverysetting'
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
            Text('网络')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('可用状态变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showNetAvailableStatusChange!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('showNetAvailableStatusChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('阻塞状态变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showNetBlockStatusChange!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('showNetBlockStatusChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('丢失时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showNetLost!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('showNetLost', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('能力变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showNetCapabilitiesChange!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('showNetCapabilitiesChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('质量变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showNetQosChange!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('showNetQosChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('场景变化时弹窗')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showNetSceneChange!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('showNetSceneChange', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('高时延时自动反馈传输体验')
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoReportHighLatency!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('autoReportHighLatency', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('时延达到')
                  .fontWeight('medium')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                TextInput({
                  text: this.highLatencyThreshold!!
                })
                  .enableAutoSpacing(true)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .maxLength(4)
                  .type(InputType.Number)
                  .width('25%')
                  .onSubmit((enterKey, event) => {
                    this.debugSettingDataPreferences.putSync('highLatencyThreshold', Number(event.text))
                    this.debugSettingDataPreferences.flushSync()
                    promptAction.openToast({
                      message: '设置成功'
                    })
                  })
                Text('ms时判定为高时延')
                  .enableAutoSpacing(true)
                  .fontWeight('medium')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
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
                Text('反馈传输体验')
                  .fontWeight('medium')
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
                  name: 'ReportQoe'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('测试')
                  .fontWeight('medium')
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
                  name: 'Networktest'
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
            Text('Webview')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight('medium')
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('分段解析HTML优化')
                  .enableAutoSpacing(true)
                  .fontWeight('medium')
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.optimizeParserBudget!!
                })
                  .onChange((isOn) => {
                    this.debugSettingDataPreferences.putSync('optimizeParserBudget', isOn)
                    this.debugSettingDataPreferences.flushSync()
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
                Text('销毁模式')
                  .fontWeight('medium')
                Blank()
                Select([
                  { value: '普通' },
                  { value: '快速' }
                ])
                  .selected(this.destroyModeIndex!!)
                  .value(this.destroyModeValue!!)
                  .onSelect((index) => {
                    this.debugSettingDataPreferences.putSync('destroyMode', index)
                    this.debugSettingDataPreferences.flushSync()
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

        ListItem() {
          Button('恢复默认设置')
            .align(Alignment.Center)
            .onClick(async () => {
              const promptAction = this.getUIContext().getPromptAction()
              const data = await promptAction.showDialog({
                title: '提示',
                message: '此操作将恢复全部调试设置为默认。确定恢复？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '恢复',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
              if (data.index === 1) {
                this.debugSettingDataPreferences.clearSync()
                this.debugSettingDataPreferences.flushSync()
                promptAction.openToast({
                  message: '恢复成功'
                })
                this.getSetting()
              }
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .width('100%')
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('调试设置')
    .onReady((context) => {
      this.pageInfos = context.pathStack
      this.getSetting()
    })
  }
}