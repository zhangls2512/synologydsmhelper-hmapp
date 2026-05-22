import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { display, LoadingDialog, promptAction } from '@kit.ArkUI'
import { getPreferType } from '../common/Prefertype'
import { dsmRequest } from '../common/Request'
import { AlbumItem } from './Album'
import Newalbum from './Newalbum'

@ComponentV2
export default struct Addphotointoalbum {
  @Consumer() isShowAddphotointoalbumSheet: boolean = false
  @Provider() isShowNewalbumSheet: boolean = false
  @Param addId: number = -1
  @Local preferType: number = 1
  @Local albumArray: AlbumItem[] = []
  @Local hoverId: number = -1
  @Local buttonHoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  refreshAlbumEventHub() {
    this.isShowAddphotointoalbumSheet = false
  }

  @Builder
  NewalbumSheetBuilder() {
    Newalbum({
      addId: this.addId
    })
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Image($r('app.media.new_white'))
        }
        .borderRadius(20)
        .height(40)
        .keyboardShortcut('N', [ModifierKey.CTRL, ModifierKey.SHIFT])
        .padding(11)
        .stateStyles({
          normal: {
            .backgroundColor(this.buttonHoverId === 0 ? '#0754EB' : $r('sys.color.background_emphasize'))
          },
          pressed: {
            .backgroundColor('#0A50DE')
          }
        })
        .width(40)
        .onHover(isHover => {
          if (!isHover) {
            this.buttonHoverId = -1
          }
          if (isHover) {
            this.buttonHoverId = 0
          }
        })
        .onClick(() => {
          this.isShowNewalbumSheet = true
        })
        .bindSheet(this.isShowNewalbumSheet!!, this.NewalbumSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '新建相册'
          }
        })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      if (this.albumArray.length === 0) {
        ListItem() {
          Text('无数据')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
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
                .enableAutoSpacing(true)
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
            .onHover(isHover => {
              if (!isHover) {
                this.hoverId = -1
              }
              if (isHover) {
                this.hoverId = index
              }
            })
            .onClick(async () => {
              this.dialogControllerProgress.open()
              const res = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.NormalAlbum', new url.URLParams({
                method: 'add_item',
                id: String(item.id),
                item: JSON.stringify([this.addId])
              }).toString())
              this.dialogControllerProgress.close()
              if (res !== 'fail') {
                await promptAction.openToast({
                  message: '加入成功'
                })
                this.isShowAddphotointoalbumSheet = false
              }
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
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      this.context.eventHub.on('refreshAlbum', this.refreshAlbumEventHub)
      this.dialogControllerProgress.open()
      const res = await dsmRequest(this.context, '', 'SYNO.Foto.Browse.NormalAlbum', new url.URLParams({
        method: 'list',
        offset: '0',
        limit: '5000'
      }).toString(), 2)
      this.dialogControllerProgress.close()
      if (res !== 'fail') {
        this.albumArray = res['list']
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshAlbum', this.refreshAlbumEventHub)
      display.off('change')
    })
  }
}