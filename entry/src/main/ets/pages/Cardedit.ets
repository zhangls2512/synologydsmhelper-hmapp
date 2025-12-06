import { preferences } from '@kit.ArkData'

interface CardItem {
  name: string,
  value: string
}

@ComponentV2
export default struct Cardeditsetting {
  @Local cards: string[] = []
  context = this.getUIContext().getHostContext()
  cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'cardSetting'
  })
  cardArray: CardItem[] = [
    {
      name: '系统信息',
      value: 'systeminfo'
    }
  ]

  getSetting() {
    this.cards = this.cardSettingDataPreferences.getSync('cards', []) as string[]
  }

  build() {
    List() {
      ListItem() {
        Column() {
          ForEach(this.cardArray, (item: CardItem, index) => {
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
              Toggle({
                type: ToggleType.Switch,
                isOn: this.cards.includes(item.value)
              })
                .onChange((isOn) => {
                  let cardlist: string[] = []
                  if (!isOn) {
                    cardlist = this.cards.filter(inItem => inItem !== item.value)
                  }
                  if (isOn) {
                    cardlist = [...this.cards, item.value]
                  }
                  this.cardSettingDataPreferences.putSync('cards', cardlist)
                  this.cardSettingDataPreferences.flushSync()
                  this.getSetting()
                })
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          })
        }
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(() => {
      this.getSetting()
    })
  }
}