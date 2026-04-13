import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { display } from '@kit.ArkUI'
import { hdsEffect } from '@kit.UIDesignKit'
import { getLoginStatus } from '../common/Account'
import { getFlushPreference } from '../common/Preference'
import { getPreferType } from '../common/Prefertype'
import { dsmRequest } from '../common/Request'
import Cardedit from './Cardedit'
import Noticelist from './Noticelist'
import Diskinfo from '../card/Diskinfo'
import Dockercontainer from '../card/Dockercontainer'
import Networkinfo from '../card/Networkinfo'
import Package from '../card/Package'
import Resourcemoniter from '../card/Resourcemoniter'
import Storageinfo from '../card/Storageinfo'
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
    this.isLogin = await getLoginStatus(this.context)
    this.cards = getFlushPreference(this.context, 'cardSetting', 'cards', []) as string[]
    this.context.eventHub.emit('refreshCard')
    if (this.isLogin) {
      const res = await dsmRequest(this.context, '', 'SYNO.Core.DSMNotify', new url.URLParams({
        method: 'notify',
        action: 'load'
      }).toString())
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
    Scroll() {
      Column() {
        if (!this.isLogin) {
          Text('未登录账号')
            .height('100%')
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        if (this.isLogin) {
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
              onDisappear: async () => {
                await this.get()
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
                onDisappear: async () => {
                  await this.get()
                }
              })
            }
          }
          .justifyContent(FlexAlign.End)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        List() {
          if (this.isLogin) {
            if (this.cards.length === 0) {
              ListItem() {
                Column() {
                  Text('未添加卡片')
                  Button('添加')
                    .margin({
                      top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                    })
                    .onClick(() => {
                      this.isShowCardeditSheet = true
                    })
                }
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            ForEach(this.cards, (item: string) => {
              if (item === 'resourcemoniter') {
                ListItem() {
                  Resourcemoniter()
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (item === 'systeminfo') {
                ListItem() {
                  Systeminfo()
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (item === 'storageinfo') {
                ListItem() {
                  Storageinfo()
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (item === 'diskinfo') {
                ListItem() {
                  Diskinfo()
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (item === 'networkinfo') {
                ListItem() {
                  Networkinfo()
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (item === 'package') {
                ListItem() {
                  Package()
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (item === 'dockercontainer') {
                ListItem() {
                  Dockercontainer()
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
            })
          }
        }
        .layoutWeight(1)
      }
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      display.on('change', () => {
        setTimeout(() => {
          this.preferType = getPreferType(this.UIContext)
        }, 200)
      })
      this.context.eventHub.on('refreshCardlist', async () => {
        await this.get()
      })
      await this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCardlist')
      display.off('change')
    })
  }
}