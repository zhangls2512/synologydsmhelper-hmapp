@Entry
@Component
struct EntranceCard {
  build() {
    Column() {
      Row() {
        Image($r('app.media.card_form'))
          .width('50%')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: {
                shortcutId: 'card'
              }
            })
          })
        Image($r('app.media.file_form'))
          .width('50%')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: {
                shortcutId: 'file'
              }
            })
          })
      }

      Row() {
        Image($r('app.media.album_form'))
          .width('50%')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: {
                shortcutId: 'album'
              }
            })
          })
        Image($r('app.media.me_form'))
          .width('50%')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: {
                shortcutId: 'me'
              }
            })
          })
      }
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
  }
}