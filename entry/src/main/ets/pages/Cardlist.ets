import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { display } from '@kit.ArkUI'
import { hdsEffect } from '@kit.UIDesignKit'
import { getLoginStatus } from '../common/Account'
import { dsmRequest } from '../common/Request'
import Cardedit from './Cardedit'
import Noticelist from './Noticelist'
import Systeminfo from '../card/Systeminfo'

interface NoticeResponseData {
  total: number
}

@ComponentV2
export default struct Cardlist {
  @Local isShowCardeditSheet: boolean = false
  @Local isShowNoticelistSheet: boolean = false
  @Local isLogin: boolean = false
  @Local cards: string[] = []
  @Local haveNotice: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1

  async get() {
    this.isLogin = await getLoginStatus()
    const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cardSetting'
    })
    this.cards = cardSettingDataPreferences.getSync('cards', []) as string[]
    this.context.eventHub.emit('refreshCard')
    if (this.isLogin) {
      const res = await dsmRequest('', 'SYNO.Core.DSMNotify', '&method=notify&action=load')
      if (res !== 'fail') {
        const noticeres = res as NoticeResponseData
        if (noticeres.total === 0) {
          this.haveNotice = false
        }
        if (noticeres.total > 0) {
          this.haveNotice = true
        }
      }
    }
  }

  @Builder
  CardeditSheetBuilder() {
    Cardedit()
  }

  @Builder
  NoticelistSheetBuilder() {
    Noticelist()
  }

  build() {
    List() {
      if (!this.isLogin) {
        ListItem() {
          Text('未登录账号')
        }
        .height('100%')
        .width('100%')
      }
      if (this.isLogin) {
        ListItem() {
          Row() {
            Column() {
              Image($r('app.media.edit'))
            }
            .backgroundColor($r('sys.color.interactive_hover'))
            .borderRadius(20)
            .height(40)
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(() => {
              this.isShowCardeditSheet = true
            })
            .bindSheet(this.isShowCardeditSheet!!, this.CardeditSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              title: {
                title: '编辑卡片'
              },
              onDisappear: () => {
                this.get()
              }
            })

            Badge({
              value: '',
              style: {
                badgeSize: 10,
                badgeColor: this.haveNotice ? Color.Red : 'rgba(0,0,0,0)',
                borderColor: this.haveNotice ? Color.Red : 'rgba(0,0,0,0)'
              }
            }) {
              Column() {
                Image($r('app.media.notice'))
              }
              .backgroundColor($r('sys.color.interactive_hover'))
              .borderRadius(20)
              .height(40)
              .padding(11)
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
              .onClick(() => {
                this.isShowNoticelistSheet = true
              })
              .bindSheet(this.isShowNoticelistSheet!!, this.NoticelistSheetBuilder(), {
                preferType: this.preferType,
                title: {
                  title: '消息'
                },
                onDisappear: () => {
                  this.get()
                }
              })
            }
          }
          .justifyContent(FlexAlign.End)
          .width('100%')
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.cards.length === 0) {
          ListItem() {
            Text('暂无卡片，可点击右上角添加')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        if (this.cards.includes('systeminfo')) {
          ListItem() {
            Systeminfo()
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
      }
    }
    .padding({
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      const currentOrientation = display.getDefaultDisplaySync().orientation
      if (currentOrientation === display.Orientation.PORTRAIT ||
        currentOrientation === display.Orientation.PORTRAIT_INVERTED) {
        this.preferType = 0
      }
      if (currentOrientation === display.Orientation.LANDSCAPE ||
        currentOrientation === display.Orientation.LANDSCAPE_INVERTED) {
        this.preferType = 1
      }
      display.on('change', (displayId) => {
        const orientation = display.getDisplayByIdSync(displayId).orientation
        if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
          this.preferType = 0
        }
        if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
          this.preferType = 1
        }
      })
      this.context.eventHub.on('refreshCardlist', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCardlist')
      display.off('change')
    })
  }
}