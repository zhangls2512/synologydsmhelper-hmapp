import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { display } from '@kit.ArkUI'
import { hdsEffect } from '@kit.UIDesignKit'
import { getLoginStatus } from '../common/Account'
import { getPreferType, getPreferTypeByDisplayId } from '../common/Prefertype'
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
  @Local preferType: number = 1
  @Local isLogin: boolean = false
  @Local cards: string[] = []
  @Local haveNotice: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  async get() {
    this.isLogin = await getLoginStatus()
    const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cardSetting'
    })
    this.cards = cardSettingDataPreferences.getSync('cards', []) as string[]
    this.context.eventHub.emit('refreshCard')
    if (this.isLogin) {
      const res =
        await dsmRequest(this.context, this.UIContext, '', 'SYNO.Core.DSMNotify', '&method=notify&action=load')
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
            .borderRadius(20)
            .height(40)
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
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
              .borderRadius(20)
              .height(40)
              .padding(11)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.interactive_hover'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
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
      right: $r('sys.float.ohos_id_max_padding_end'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(() => {
      this.preferType = getPreferType()
      display.on('change', (displayId) => {
        this.preferType = getPreferTypeByDisplayId(displayId)
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