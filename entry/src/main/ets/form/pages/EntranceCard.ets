@Entry
@Component
struct EntranceCard {
  build() {
    Column() {
      Row() {
        Column() {
          Image($r('app.media.card_form'))
            .height('50%')
          Text('卡片')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .height('30%')
        }
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

        Column() {
          Image($r('app.media.file_form'))
            .height('50%')
          Text('文件')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .height('30%')
        }
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
      .height('50%')

      Row() {
        Column() {
          Image($r('app.media.album_form'))
            .height('50%')
          Text('相册')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .height('30%')
        }
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

        Column() {
          Image($r('app.media.me_form'))
            .height('50%')
          Text('我的')
            .fontColor($r('sys.color.font_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Medium)
            .height('30%')
        }
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
      .height('50%')
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .height('100%')
  }
}