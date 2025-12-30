@Entry
@Component
struct FileAlbumEntranceCard {
  build() {
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
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
  }
}