import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { appInfoManager } from '@kit.AppGalleryKit'
import { preferences } from '@kit.ArkData'
import { promptAction, uiAppearance, window } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'

@Builder
export function CommonsettingBuilder() {
  Commonsetting()
}

@ComponentV2
struct Commonsetting {
  @Local iconModeIndex: number = 1
  @Local iconModeValue: string = '浅色'
  @Local allowContinue: boolean = false
  @Local exitAfterContinue: boolean = false
  @Local allowRestore: boolean = false
  @Local acceptCollaborate: boolean = false
  @Local destroyWhenBackPressed: boolean = false
  @Local colorModeIndex: number = 0
  @Local colorModeValue: string = '跟随系统'
  @Local windowRectAutoSave: boolean = false
  @Local windowTopmost: boolean = false
  @Local keepScreenOn: boolean = false
  @Local disallowScreenshot: boolean = true
  @Local showPasswordInIndex: boolean = false
  @Local passwordInfoValueDataDetector: boolean = true
  @Local mfaSecondsRemainingStyleIndex: number = 0
  @Local mfaSecondsRemainingStyleValue: string = 'progress'
  @Local pushItemWhenBlur: boolean = false
  @Local checkVersionUpdateIndex: number = 1
  @Local checkVersionUpdateValue: string = '仅 WLAN 下'
  @Local openLinkTypeIndex: number = 0
  @Local openLinkTypeValue: string = '系统默认'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Column() {
            Text('应用')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12
              })
            Column() {
              Row() {
                Text('图标模式')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Select([
                  { value: '自动' },
                  { value: '浅色' },
                  { value: '深色' }
                ])
                  .selected(this.iconModeIndex!!)
                  .value(this.iconModeValue!!)
                  .onSelect(async (index) => {
                    try {
                      if (index === 0) {
                        if (this.colorModeIndex === 0) {
                          const systemColorMode = uiAppearance.getDarkMode()
                          if (systemColorMode === 0) {
                            await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
                          }
                          if (systemColorMode === 1) {
                            await appInfoManager.disableDynamicIcon()
                          }
                        }
                        if (this.colorModeIndex === 1) {
                          await appInfoManager.disableDynamicIcon()
                        }
                        if (this.colorModeIndex === 2) {
                          await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
                        }
                      }
                      if (index === 1) {
                        await appInfoManager.disableDynamicIcon()
                      }
                      if (index === 2) {
                        await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
                      }
                    } catch (err) {
                      if (err.code !== 1006800012) {
                        promptAction.openToast({
                          message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                        })
                      }
                    }
                    this.commonSettingDataPreferences.putSync('iconMode', index)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('接续')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.allowContinue!!
                })
                  .onChange(async (isOn) => {
                    this.commonSettingDataPreferences.putSync('allowContinue', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('接续成功后退出')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.exitAfterContinue!!
                })
                  .onChange((isOn) => {
                    this.commonSettingDataPreferences.putSync('exitAfterContinue', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('备份恢复')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.allowRestore!!
                })
                  .onChange(async (isOn) => {
                    this.commonSettingDataPreferences.putSync('allowRestore', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('接受协同')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.acceptCollaborate!!
                })
                  .onChange((isOn) => {
                    this.commonSettingDataPreferences.putSync('acceptCollaborate', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('侧滑返回时退出')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.destroyWhenBackPressed!!
                })
                  .onChange((isOn) => {
                    this.commonSettingDataPreferences.putSync('destroyWhenBackPressed', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('防窥保护')
                  .fontWeight('medium')
                Blank()
                Text('去设置')
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
                this.context.startAbility({
                  bundleName: 'com.huawei.hmos.settings',
                  abilityName: 'com.huawei.hmos.settings.MainAbility',
                  uri: 'privacy_settings',
                  parameters: {
                    pushParams: 'com.zhangxm.aipasswordmemo'
                  }
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
            Text('界面')
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
                  Text('深色模式')
                    .fontWeight(FontWeight.Medium)
                  Text('不对卡片生效')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()
                Select([
                  { value: '跟随系统' },
                  { value: '浅色模式' },
                  { value: '深色模式' }
                ])
                  .selected(this.colorModeIndex!!)
                  .value(this.colorModeValue!!)
                  .onSelect((index) => {
                    const applicationContext = this.context.getApplicationContext()
                    if (index === 0) {
                      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
                    }
                    if (index === 1) {
                      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
                    }
                    if (index === 2) {
                      applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
                    }
                    this.commonSettingDataPreferences.putSync('colorMode', index)
                    this.commonSettingDataPreferences.flushSync()
                  })
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              if (deviceInfo.deviceType === '2in1') {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('记忆主窗口尺寸')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.windowRectAutoSave!!
                  })
                    .onChange(async (isOn) => {
                      this.commonSettingDataPreferences.putSync('windowRectAutoSave', isOn)
                      this.commonSettingDataPreferences.flushSync()
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
              }
              if (deviceInfo.deviceType !== 'phone') {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('窗口置顶')
                    .fontWeight(FontWeight.Medium)
                  Blank()
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.windowTopmost!!
                  })
                    .onChange(async (isOn) => {
                      const lastWindow = await window.getLastWindow(this.context)
                      await lastWindow.setWindowTopmost(isOn)
                      this.commonSettingDataPreferences.putSync('windowTopmost', isOn)
                      this.commonSettingDataPreferences.flushSync()
                    })
                }
                .borderRadius(12)
                .padding(12)
                .width('100%')
              }
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('屏幕常亮')
                    .fontWeight(FontWeight.Medium)
                  Text('仅在本次使用期间生效')
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
                  isOn: this.keepScreenOn!!
                })
                  .onChange(async (isOn) => {
                    const lastWindow = await window.getLastWindow(this.context)
                    lastWindow.setWindowKeepScreenOn(isOn)
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
                Text('敏感页面禁止截、录屏')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.disallowScreenshot!!
                })
                  .onChange((isOn) => {
                    this.commonSettingDataPreferences.putSync('disallowScreenshot', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('背景图')
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
                const backgroundImagePath = this.context.filesDir + '/media/backgroundimage.png'
                const res = fileIo.accessSync(backgroundImagePath)
                if (!res) {
                  try {
                    const photoPicker = new photoAccessHelper.PhotoViewPicker()
                    const pickerres = await photoPicker.select({
                      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
                      maxSelectNumber: 1,
                      isPhotoTakingSupported: false,
                      isOriginalSupported: false
                    })
                    const fileSource = await fileIo.open(pickerres.photoUris[0])
                    const imageSource = image.createImageSource(fileSource.fd)
                    const imagePixelMap = await imageSource.createPixelMap()
                    if (!fileIo.accessSync(this.context.filesDir + '/media')) {
                      fileIo.mkdirSync(this.context.filesDir + '/media')
                    }
                    const file =
                      fileIo.openSync(backgroundImagePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                    const imagePacker = image.createImagePacker()
                    await imagePacker.packToFile(imagePixelMap, file.fd, {
                      format: 'image/png',
                      quality: 100
                    })
                    fileIo.closeSync(file)
                    this.context.eventHub.emit('refreshIndex')
                  } catch (err) {
                    if (err.code !== 13900020) {
                      promptAction.openToast({
                        message: '发生错误，错误码：' + err.code
                      })
                    }
                  }
                  return
                }
                if (res) {
                  const promptAction = this.getUIContext().getPromptAction()
                  const data = await promptAction.showActionMenu({
                    title: '设置背景图',
                    buttons: [
                      {
                        text: '从图库中选择',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '恢复默认',
                        color: $r('sys.color.font_primary')
                      }
                    ]
                  })
                  if (data.index === 0) {
                    try {
                      const photoPicker = new photoAccessHelper.PhotoViewPicker()
                      const pickerres = await photoPicker.select({
                        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
                        maxSelectNumber: 1,
                        isPhotoTakingSupported: false,
                        isOriginalSupported: false
                      })
                      const fileSource = await fileIo.open(pickerres.photoUris[0])
                      const imageSource = image.createImageSource(fileSource.fd)
                      const imagePixelMap = await imageSource.createPixelMap()
                      const file =
                        fileIo.openSync(backgroundImagePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
                      const imagePacker = image.createImagePacker()
                      await imagePacker.packToFile(imagePixelMap, file.fd, {
                        format: 'image/png',
                        quality: 100
                      })
                      fileIo.closeSync(file)
                      this.context.eventHub.emit('refreshIndex')
                    } catch (err) {
                      if (err.code !== 13900020) {
                        promptAction.openToast({
                          message: '发生错误，错误码：' + err.code
                        })
                      }
                    }
                  }
                  if (data.index === 1) {
                    fileIo.unlinkSync(backgroundImagePath)
                    this.context.eventHub.emit('refreshIndex')
                  }
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('首页显示密码')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.showPasswordInIndex!!
                })
                  .onChange((isOn) => {
                    this.commonSettingDataPreferences.putSync('showPasswordInIndex', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('常用信息类型')
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
                  name: 'Oftenusedinfotype'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('默认隐藏内容密码信息类型')
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
                  name: 'Defaulthidepasswordinfotype'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('密码信息内容特殊实体识别')
                    .fontWeight(FontWeight.Medium)
                  Text('图标、MFA、URL类型除外')
                    .enableAutoSpacing(true)
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
                  isOn: this.passwordInfoValueDataDetector!!
                })
                  .onChange((isOn) => {
                    this.commonSettingDataPreferences.putSync('passwordInfoValueDataDetector', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('MFA倒计时样式')
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Select([
                  { value: '进度条' },
                  { value: '数字' }
                ])
                  .selected(this.mfaSecondsRemainingStyleIndex!!)
                  .value(this.mfaSecondsRemainingStyleValue!!)
                  .onSelect((index) => {
                    this.commonSettingDataPreferences.putSync('mfaSecondsRemainingStyle', index)
                    this.commonSettingDataPreferences.flushSync()
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
                Column() {
                  Text('密码信息内容、标签输入框失焦时自动添加信息、标签')
                    .fontWeight(FontWeight.Medium)
                  Text('MFA信息类型仅对输入otpauthUri时生效')
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .width('85%')

                Blank()
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pushItemWhenBlur!!
                })
                  .onChange((isOn) => {
                    this.commonSettingDataPreferences.putSync('pushItemWhenBlur', isOn)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('启动时检查更新')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Select([
                  { value: '从不' },
                  { value: '仅 WLAN 下' },
                  { value: '始终' }
                ])
                  .selected(this.checkVersionUpdateIndex!!)
                  .value(this.checkVersionUpdateValue!!)
                  .onSelect((index) => {
                    this.commonSettingDataPreferences.putSync('checkVersionUpdate', index)
                    this.commonSettingDataPreferences.flushSync()
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
                Text('链接打开方式')
                  .fontWeight(FontWeight.Medium)
                Blank()
                Select([
                  { value: '系统默认' },
                  { value: '自行选择' }
                ])
                  .selected(this.openLinkTypeIndex!!)
                  .value(this.openLinkTypeValue!!)
                  .onSelect((index) => {
                    this.commonSettingDataPreferences.putSync('openLinkType', index)
                    this.commonSettingDataPreferences.flushSync()
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
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('通用')
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      const iconMode = this.commonSettingDataPreferences.getSync('iconMode', 1)
      this.iconModeIndex = iconMode as number
      if (iconMode === 0) {
        this.iconModeValue = '自动'
      }
      if (iconMode === 1) {
        this.iconModeValue = '浅色'
      }
      if (iconMode === 2) {
        this.iconModeValue = '深色'
      }
      this.allowContinue = this.commonSettingDataPreferences.getSync('allowContinue', true) as boolean
      this.exitAfterContinue = this.commonSettingDataPreferences.getSync('exitAfterContinue', true) as boolean
      this.allowRestore = this.commonSettingDataPreferences.getSync('allowRestore', true) as boolean
      this.acceptCollaborate = this.commonSettingDataPreferences.getSync('acceptCollaborate', true) as boolean
      this.destroyWhenBackPressed =
        this.commonSettingDataPreferences.getSync('destroyWhenBackPressed', false) as boolean
      const colorMode = this.commonSettingDataPreferences.getSync('colorMode', 0)
      this.colorModeIndex = colorMode as number
      if (colorMode === 0) {
        this.colorModeValue = '跟随系统'
      }
      if (colorMode === 1) {
        this.colorModeValue = '浅色模式'
      }
      if (colorMode === 2) {
        this.colorModeValue = '深色模式'
      }
      this.windowRectAutoSave = this.commonSettingDataPreferences.getSync('windowRectAutoSave', false) as boolean
      this.windowTopmost = this.commonSettingDataPreferences.getSync('windowTopmost', false) as boolean
      const lastWindow = await window.getLastWindow(this.context)
      this.keepScreenOn = lastWindow.getWindowProperties().isKeepScreenOn
      this.disallowScreenshot = this.commonSettingDataPreferences.getSync('disallowScreenshot', true) as boolean
      this.showPasswordInIndex = this.commonSettingDataPreferences.getSync('showPasswordInIndex', false) as boolean
      this.passwordInfoValueDataDetector =
        this.commonSettingDataPreferences.getSync('passwordInfoValueDataDetector', true) as boolean
      const mfaSecondsRemainingStyle = this.commonSettingDataPreferences.getSync('mfaSecondsRemainingStyle', 0)
      this.mfaSecondsRemainingStyleIndex = mfaSecondsRemainingStyle as number
      if (mfaSecondsRemainingStyle === 0) {
        this.mfaSecondsRemainingStyleValue = '进度条'
      }
      if (mfaSecondsRemainingStyle === 1) {
        this.mfaSecondsRemainingStyleValue = '数字'
      }
      this.pushItemWhenBlur = this.commonSettingDataPreferences.getSync('pushItemWhenBlur', false) as boolean
      const checkVersionUpdate = this.commonSettingDataPreferences.getSync('checkVersionUpdate', 1)
      this.checkVersionUpdateIndex = checkVersionUpdate as number
      if (checkVersionUpdate === 0) {
        this.checkVersionUpdateValue = '从不'
      }
      if (checkVersionUpdate === 1) {
        this.checkVersionUpdateValue = '仅 WLAN 下'
      }
      if (checkVersionUpdate === 2) {
        this.checkVersionUpdateValue = '始终'
      }
      const openLinkType = this.commonSettingDataPreferences.getSync('openLinkType', 0)
      this.openLinkTypeIndex = openLinkType as number
      if (openLinkType === 0) {
        this.openLinkTypeValue = '系统默认'
      }
      if (openLinkType === 1) {
        this.openLinkTypeValue = '自行选择'
      }
    })
  }
}