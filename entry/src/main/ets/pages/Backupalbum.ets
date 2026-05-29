import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getAccountHash, getAccountInfo } from '../common/Account'
import { AlbumItem, getAlbumList } from '../common/Backup'
import { read, write } from '../common/File'
import { checkPermission } from '../common/Permission'
import { BackupSetting } from './Backupsetting'

@Builder
export function BackupalbumBuilder() {
  Backupalbum()
}

@ComponentV2
struct Backupalbum {
  @Local albumUris: string[] = []
  @Local albumArray: AlbumItem[] = []
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  backupSettingFileContent: BackupSetting = {
    autoTypes: [],
    albumUris: []
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        if (this.albumArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ListItem() {
          Column() {
            ForEach(this.albumArray, (item: AlbumItem, index) => {
              if (index !== 0) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
              }
              Row() {
                Text(item.name)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.albumUris.includes(item.uri)
                })
                  .onChange(async (isOn) => {
                    if (!isOn) {
                      this.albumUris = this.albumUris.filter(inItem => inItem !== item.uri)
                    }
                    if (isOn) {
                      this.albumUris = Array.from(new Set([...this.albumUris, item.uri]))
                    }
                    this.backupSettingFileContent.albumUris = this.albumUris
                    const accountInfo = await getAccountInfo(this.context)
                    await write(this.context.filesDir + '/backupsetting/' + getAccountHash(accountInfo) + '.txt',
                      JSON.stringify(this.backupSettingFileContent))
                  })
              }
              .borderRadius(12)
              .padding(12)
            })
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
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
            },
            backIconStyle: {
              iconColor: $r('sys.color.icon_primary')
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
          mainTitle: '自定义备份相册'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(async () => {
      const accountInfo = await getAccountInfo(this.context)
      const filePath = this.context.filesDir + '/backupsetting/' + getAccountHash(accountInfo) + '.txt'
      const filestring = await read(filePath, true)
      if (filestring !== 'fail') {
        const backupSettingFileContent = JSON.parse(filestring) as BackupSetting
        this.albumUris = backupSettingFileContent.albumUris ?? []
        backupSettingFileContent.albumUris = this.albumUris
        this.backupSettingFileContent.autoTypes = backupSettingFileContent.autoTypes ?? []
      }
      const res = await checkPermission(this.context, this.UIContext, 'ohos.permission.READ_IMAGEVIDEO')
      if (res) {
        this.albumArray = await getAlbumList(this.context)
      }
    })
  }
}