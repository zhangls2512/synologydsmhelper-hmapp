import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { deviceInfo } from '@kit.BasicServicesKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { getLoginStatus } from '../common/Account'
import Cardedit from './Cardedit'
import Systeminfo from '../card/Systeminfo'

@ComponentV2
export default struct Cardlist {
  @Local isShowCardeditSheet: boolean = false
  @Local isLogin: boolean = false
  @Local cards: string[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1

  async get() {
    this.isLogin = await getLoginStatus()
    const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cardSetting'
    })
    this.cards = cardSettingDataPreferences.getSync('cards', []) as string[]
    this.context.eventHub.emit('refreshCard')
  }

  @Builder
  CardeditSheetBuilder() {
    Cardedit()
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
              onDisappear: (() => {
                this.get()
              })
            })
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
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      if (deviceInfo.deviceType === 'phone') {
        this.preferType = 0
      }
      this.context.eventHub.on('refreshCardlist', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCardlist')
    })
  }
}