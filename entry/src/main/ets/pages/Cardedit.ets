import { common } from '@kit.AbilityKit'
import { getFlushPreference, setFlushPreference } from '../common/Preference'

interface CardItem {
  name: string,
  value: string
}

@ComponentV2
export default struct Cardeditsetting {
  @Local cards: string[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  cardArray: CardItem[] = [
    {
      name: '资源监控',
      value: 'resourcemoniter'
    },
    {
      name: '系统信息',
      value: 'systeminfo'
    },
    {
      name: '存储空间信息',
      value: 'storageinfo'
    },
    {
      name: '硬盘信息',
      value: 'diskinfo'
    },
    {
      name: '网络信息',
      value: 'networkinfo'
    },
    {
      name: '套件',
      value: 'package'
    },
    {
      name: 'Docker容器',
      value: 'dockercontainer'
    }
  ]

  build() {
    List() {
      ForEach(this.cards, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(this.cardArray.find(cardItem => cardItem.value === item)?.name)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              if (index !== 0) {
                Image($r('app.media.up'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(() => {
                    const temp = this.cards[index]
                    this.cards[index] = this.cards[index - 1]
                    this.cards[index - 1] = temp
                    setFlushPreference(this.context, 'cardSetting', 'cards', this.cards)
                    this.context.eventHub.emit('refreshCardlist')
                  })
              }
              if (index !== this.cards.length - 1) {
                Image($r('app.media.down'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(() => {
                    const temp = this.cards[index]
                    this.cards[index] = this.cards[index + 1]
                    this.cards[index + 1] = temp
                    setFlushPreference(this.context, 'cardSetting', 'cards', this.cards)
                    this.context.eventHub.emit('refreshCardlist')
                  })
              }
              Image($r('app.media.delete'))
                .height(24)
                .onClick(() => {
                  this.cards.splice(index, 1)
                  setFlushPreference(this.context, 'cardSetting', 'cards', this.cards)
                  this.context.eventHub.emit('refreshCardlist')
                })
            }
            .borderRadius(12)
            .padding(12)
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      ForEach(this.cardArray.filter(item => !this.cards.includes(item.value)), (item: CardItem) => {
        ListItem() {
          Column() {
            Row() {
              Text(item.name)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.add'))
                .height(24)
                .onClick(() => {
                  this.cards.push(item.value)
                  setFlushPreference(this.context, 'cardSetting', 'cards', this.cards)
                  this.context.eventHub.emit('refreshCardlist')
                })
            }
            .borderRadius(12)
            .padding(12)
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(() => {
      this.cards = getFlushPreference(this.context, 'cardSetting', 'cards', []) as string[]
    })
  }
}