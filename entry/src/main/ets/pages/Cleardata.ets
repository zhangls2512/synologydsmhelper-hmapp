import { bundleManager, common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { LengthMetrics } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'
import { fileIo } from '@kit.CoreFileKit'
import { hdsMaterial, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getAccountInfo } from '../common/Account'
import { getDirectorySize, getFileSize } from '../common/File'
import { sha256hash } from '../common/Hash'
import { getSizeString } from '../common/Stringformat'

@ComponentV2
export default struct Cleardata {
  @Local setting: string[] = []
  @Local allSetting: boolean = false
  @Local cardSetting: boolean = false
  @Local backupSetting: boolean = false
  @Local backupSettingSize: string = ''
  @Local commonSetting: boolean = false
  @Local commonSettingSize: string = ''
  @Local permissionSetting: boolean = false
  @Local permissionSettingSize: string = ''
  @Local debugSetting: boolean = false
  @Local debugSettingSize: string = ''
  @Local cache: string[] = []
  @Local allCache: boolean = false
  @Local appCache: boolean = false
  @Local appCacheSize: string = ''
  @Local webviewCache: boolean = false
  @Local apiVersionCache: boolean = false
  @Local apiVersionCacheSize: string = ''
  @Local noticeJsonStringCache: boolean = false
  @Local noticeJsonStringCacheSize: string = ''
  @Local albumPhotoThumbnailCache: boolean = false
  @Local albumPhotoThumbnailCacheSize: string = ''
  @Local log: string[] = []
  @Local allLog: boolean = false
  @Local errorLog: boolean = false
  @Local errorLogSize: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  async getSize() {
    const backupSettingSize = await getDirectorySize(this.context.filesDir + '/backupsetting')
    this.backupSettingSize = getSizeString(backupSettingSize)
    this.commonSettingSize = getSizeString(getFileSize(this.context.preferencesDir + '/commonSetting.db'))
    this.permissionSettingSize = getSizeString(getFileSize(this.context.preferencesDir + '/permissionSetting.db'))
    this.debugSettingSize = getSizeString(getFileSize(this.context.preferencesDir + '/debugSetting.db'))
    const appCacheSize = await getDirectorySize(this.context.cacheDir)
    this.appCacheSize = getSizeString(appCacheSize)
    const apiVersionCacheFilePath = this.context.cacheDir + '/apiversion.txt'
    const apiVersionCacheFileExist = fileIo.accessSync(apiVersionCacheFilePath)
    if (!apiVersionCacheFileExist) {
      this.apiVersionCacheSize = getSizeString(0)
    }
    if (apiVersionCacheFileExist) {
      this.apiVersionCacheSize = getSizeString(fileIo.statSync(apiVersionCacheFilePath).size)
    }
    const noticeJsonStringCacheSize = await getDirectorySize(this.context.cacheDir + '/noticejsonstring')
    this.noticeJsonStringCacheSize = getSizeString(noticeJsonStringCacheSize)
    const accountInfo = await getAccountInfo(this.context)
    if (!accountInfo.id) {
      const albumPhotoThumbnailCacheSize = await getDirectorySize(this.context.cacheDir + '/albumphotothumbnail')
      this.albumPhotoThumbnailCacheSize = getSizeString(albumPhotoThumbnailCacheSize)
    }
    if (accountInfo.id) {
      const albumPhotoThumbnailDirectory = this.context.cacheDir + '/albumphotothumbnail/'
      if (fileIo.accessSync(albumPhotoThumbnailDirectory)) {
        const accounts = await fileIo.listFile(albumPhotoThumbnailDirectory)
        let size = 0
        this.albumPhotoThumbnailCacheSize = getSizeString(size)
        for (let i = 0; i < accounts.length; i++) {
          const item = accounts[i]
          if (item !== sha256hash(accountInfo.path + '\0' + accountInfo.name)) {
            size += await getDirectorySize(albumPhotoThumbnailDirectory + item)
            this.albumPhotoThumbnailCacheSize = getSizeString(size)
          }
        }
      }
    }
    const errorLogSize = await getDirectorySize(this.context.filesDir + '/log/error')
    this.errorLogSize = getSizeString(errorLogSize)
  }

  build() {
    HdsNavigation(this.pageInfos) {
      List() {
        ListItem()
          .margin({
            top: 64
          })
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
                Text('全部')
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                CheckboxGroup({
                  group: 'setting'
                })
                  .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                  .selectAll(this.allSetting!!)
                  .onChange(itemName => {
                    this.setting = itemName.name
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('卡片')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Checkbox({
                  name: 'cardSetting',
                  group: 'setting'
                })
                  .select(this.cardSetting!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('备份')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.backupSettingSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'backupSetting',
                  group: 'setting'
                })
                  .select(this.backupSetting!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('通用')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.commonSettingSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'commonSetting',
                  group: 'setting'
                })
                  .select(this.commonSetting!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('权限')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.permissionSettingSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'permissionSetting',
                  group: 'setting'
                })
                  .select(this.permissionSetting!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('调试')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.debugSettingSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'debugSetting',
                  group: 'setting'
                })
                  .select(this.debugSetting!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Text('高级')
              .fontColor($r('sys.color.font_emphasize'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: 6,
                left: 12,
                right: 12
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Clearpreferencekey'
                })
              })
            Button('清理设置')
              .enabled(this.setting.length > 0)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .role(ButtonRole.ERROR)
              .width('100%')
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
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
                  const promises = this.setting.map(async (item) => {
                    if (item !== 'backupSetting') {
                      const dataPreferences = preferences.getPreferencesSync(this.context, {
                        name: item,
                        storageType: preferences.StorageType.GSKV
                      })
                      dataPreferences.clearSync()
                    }
                    if (item === 'backupSetting') {
                      const backupSettingDir = this.context.filesDir + '/backupsetting'
                      if (fileIo.accessSync(backupSettingDir)) {
                        await fileIo.rmdir(backupSettingDir)
                      }
                    }
                  })
                  await Promise.all(promises)
                  await this.getSize()
                  const res = await promptAction.showDialog({
                    title: '提示',
                    message: '清理成功，需重启应用生效，是否重启？',
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
                  if (res.index === 1) {
                    const applicationContext = this.context.getApplicationContext()
                    applicationContext.restartApp({
                      bundleName: 'com.songjy.synologydsmhelper',
                      abilityName: 'EntryAbility'
                    })
                  }
                }
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

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
                Text('全部')
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                CheckboxGroup({
                  group: 'cache'
                })
                  .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                  .selectAll(this.allCache!!)
                  .onChange(itemName => {
                    this.cache = itemName.name
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('应用')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.appCacheSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'appCache',
                  group: 'cache'
                })
                  .select(this.appCache!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('Webview')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Checkbox({
                  name: 'webviewCache',
                  group: 'cache'
                })
                  .select(this.webviewCache!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('API版本号')
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.apiVersionCacheSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'apiVersionCache',
                  group: 'cache'
                })
                  .select(this.apiVersionCache!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('消息JSON字符串')
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.noticeJsonStringCacheSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'noticeJsonStringCache',
                  group: 'cache'
                })
                  .select(this.noticeJsonStringCache!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('相册照片缩略图')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.albumPhotoThumbnailCacheSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'albumPhotoThumbnailCache',
                  group: 'cache'
                })
                  .select(this.albumPhotoThumbnailCache!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Button('清理缓存')
              .enabled(this.cache.length > 0)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .role(ButtonRole.ERROR)
              .width('100%')
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
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
                  const promises = this.cache.map(async (item) => {
                    try {
                      if (item === 'appCache') {
                        await bundleManager.cleanBundleCacheFilesForSelf()
                      }
                      if (item === 'webviewCache') {
                        webview.WebviewController.removeAllCache(true)
                      }
                      if (item === 'apiVersionCache') {
                        await fileIo.unlink(this.context.cacheDir + '/apiversion.txt')
                      }
                      if (item === 'noticeJsonStringCache') {
                        const noticeJsonStringCacheDir = this.context.cacheDir + '/noticejsonstring'
                        if (fileIo.accessSync(noticeJsonStringCacheDir)) {
                          await fileIo.rmdir(noticeJsonStringCacheDir)
                        }
                      }
                      if (item === 'albumPhotoThumbnailCache') {
                        const accountInfo = await getAccountInfo(this.context)
                        const albumPhotoThumbnailDirectory = this.context.cacheDir + '/albumphotothumbnail/'
                        if (!accountInfo.id) {
                          await fileIo.rmdir(albumPhotoThumbnailDirectory)
                        }
                        if (accountInfo.id) {
                          const accounts = await fileIo.listFile(albumPhotoThumbnailDirectory)
                          const rmdirpromises = accounts.map(async (item) => {
                            if (item !== sha256hash(accountInfo.path + '\0' + accountInfo.name)) {
                              await fileIo.rmdir(albumPhotoThumbnailDirectory + item)
                            }
                          })
                          await Promise.all(rmdirpromises)
                        }
                      }
                    } catch {
                    }
                  })
                  await Promise.all(promises)
                  await promptAction.openToast({
                    message: '清理成功'
                  })
                  await this.getSize()
                }
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

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
                Text('全部')
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                CheckboxGroup({
                  group: 'log'
                })
                  .checkboxShape(CheckBoxShape.ROUNDED_SQUARE)
                  .selectAll(this.allLog!!)
                  .onChange(itemName => {
                    this.log = itemName.name
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('故障')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(this.errorLogSize)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                  })
                Checkbox({
                  name: 'errorLog',
                  group: 'log'
                })
                  .select(this.errorLog!!)
                  .shape(CheckBoxShape.ROUNDED_SQUARE)
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))

            Button('清理日志')
              .enabled(this.log.length > 0)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .role(ButtonRole.ERROR)
              .width('100%')
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
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
                  const promises = this.log.map(async (item) => {
                    if (item === 'errorLog') {
                      const errorLogDir = this.context.filesDir + '/log/error'
                      if (fileIo.accessSync(errorLogDir)) {
                        await fileIo.rmdir(errorLogDir)
                      }
                    }
                  })
                  await Promise.all(promises)
                  await promptAction.openToast({
                    message: '清理成功'
                  })
                  await this.getSize()
                }
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .hideBackButton(true)
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '清理数据'
        }
      }
    })
    .titleMode(HdsNavigationTitleMode.MODAL)
    .onAppear(async () => {
      await this.getSize()
    })
    .onDisAppear(() => {
      this.context.eventHub.emit('refreshSetting')
    })
  }
}