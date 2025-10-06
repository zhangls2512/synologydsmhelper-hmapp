import { dsmRequest } from '../common/Request'

interface NoticeItem {
  level: string,
  className: string,
  msg: string[],
  title: string
}

interface NoticeResponseData {
  items: NoticeItem[]
}

@ComponentV2
export default struct Noticelist {
  @Local notices: NoticeItem[] = []
  @Local loading: boolean = false
  empty: boolean | undefined = undefined

  getTime(time: string) {
    const timejson = JSON.parse(time) as object
    return timejson['%DATE%'] + ' ' + timejson['%TIME%']
  }

  build() {
    List() {
      if (this.notices.length === 0 && !this.loading) {
        ListItem() {
          Text('无消息')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .width('100%')
      }
      ForEach(this.notices, (item: NoticeItem) => {
        ListItem() {
          Column() {
            Row() {
              Text('层级')
                .fontWeight(FontWeight.Medium)
                .width('15%')
              Blank()
                .width('5%')
              Text(item.level)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .textAlign(TextAlign.End)
                .width('80%')
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('类别')
                .fontWeight(FontWeight.Medium)
                .width('15%')
              Blank()
                .width('5%')
              Text(item.className !== '' ? item.className : '未知')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .textAlign(TextAlign.End)
                .width('80%')
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('主题')
                .fontWeight(FontWeight.Medium)
                .width('15%')
              Blank()
                .width('5%')
              Text(item.title)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .textAlign(TextAlign.End)
                .width('80%')
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')

            Divider()
              .padding({
                left: 12,
                right: 12
              })
            Row() {
              Text('时间')
                .fontWeight(FontWeight.Medium)
                .width('15%')
              Blank()
                .width('5%')
              Text(this.getTime(item.msg[0]))
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .textAlign(TextAlign.End)
                .width('80%')
            }
            .borderRadius(12)
            .padding(12)
            .width('100%')
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
      })
      if (this.loading) {
        ListItem() {
          LoadingProgress()
            .width('20%')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .width('100%')
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      this.loading = true
      const res = await dsmRequest('', 'SYNO.Core.DSMNotify', '&method=notify&action=load')
      this.loading = false
      if (res !== 'fail') {
        const noticeres = res as NoticeResponseData
        this.notices = noticeres.items
        this.empty = false
      }
    })
    .onReachEnd(async () => {
      if (this.empty === false) {
        this.loading = true
        const res =
          await dsmRequest('', 'SYNO.Core.DSMNotify', '&method=notify&action=load&offset=' + this.notices.length)
        this.loading = false
        if (res !== 'fail') {
          const noticeres = res as NoticeResponseData
          if (noticeres.items.length === 0) {
            this.empty = true
          }
          this.notices = this.notices.concat(noticeres.items)
        }
      }
    })
  }
}