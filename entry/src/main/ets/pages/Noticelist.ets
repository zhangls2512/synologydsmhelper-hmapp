import { common } from '@kit.AbilityKit'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { dsmRequest } from '../common/Request'

interface NoticeString {
  msg: string,
  title: string
}

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
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext

  getTime(time: string) {
    try {
      const timejson = JSON.parse(time) as object
      return timejson['%DATE%'] + ' ' + timejson['%TIME%']
    } catch {
      return '未知'
    }
  }

  async get() {
    this.loading = true
    const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Core.DSMNotify', '&method=notify&action=load')
    if (res !== 'fail') {
      const resa =
        await dsmRequest(this.context, this.UIContext, '', 'SYNO.Core.DSMNotify.Strings', '&method=get&lang=chs')
      this.loading = false
      if (resa !== 'fail') {
        const noticeres = res as NoticeResponseData
        const noticeString = resa as Record<string, NoticeString>
        this.notices = noticeres.items.map((item): NoticeItem => {
          return {
            level: item.level,
            className: noticeString[item.title].title,
            msg: item.msg,
            title: noticeString[item.title].msg
          }
        })
      }
    }
    if (res === 'fail') {
      this.loading = false
    }
  }

  build() {
    List() {
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
      if (!this.loading) {
        ListItem() {
          Button('清除全部')
            .role(ButtonRole.ERROR)
            .onClick(async () => {
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '清除中...'
                })
              })
              dialogControllerProgress.open()
              const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Core.DSMNotify',
                '&method=notify&action=apply&clean=all')
              dialogControllerProgress.close()
              if (res !== 'fail') {
                promptAction.openToast({
                  message: '清除成功'
                })
                this.get()
              }
            })
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })
        .width('100%')
      }
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
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(item.level === 'NOTIFICATION_INFO' ? '信息' :
                item.level === 'NOTIFICATION_WARN' ? '警告' :
                  item.level === 'NOTIFICATION_ERROR' ? '重要' :
                    '未知')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
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
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(item.className !== '' ? item.className : '未知')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
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
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(item.title)
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
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
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.getTime(item.msg[0]))
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
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
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      this.get()
    })
  }
}