import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { getAccountInfo } from '../common/Account'
import { read, write } from '../common/File'
import { dsmRequest } from '../common/Request'
import { sha256hash } from '../common/Hash'

interface NoticeJsonString {
  jsonString: string,
  dsmVersion: number
}

interface NoticeString {
  msg: string,
  title: string
}

interface NoticeItem {
  level: string,
  className: string,
  title: string,
  time: number,
  msg: string[],
  mailContent?: string
}

interface NoticeResponseData {
  items: NoticeItem[]
}

@ComponentV2
export default struct Noticelist {
  @Local notices: NoticeItem[] = []
  @Local loading: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  getTime(time: string) {
    try {
      const timejson = JSON.parse(time) as object
      return timejson['%DATE%'] + ' ' + timejson['%TIME%']
    } catch {
      return '未知'
    }
  }

  async getNoticeJsonString(): Promise<NoticeJsonString | 'fail'> {
    const accountInfo = await getAccountInfo()
    const filePath6 = this.context.cacheDir + '/noticejsonstring/' + sha256hash(accountInfo.path) + '.6.txt'
    const filePath7 = this.context.cacheDir + '/noticejsonstring/' + sha256hash(accountInfo.path) + '.7.txt'
    let exist6 = fileIo.accessSync(filePath6)
    let exist7 = fileIo.accessSync(filePath7)
    const commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'commonSetting'
    })
    const cacheNoticeJsonString = commonSettingDataPreferences.getSync('cacheNoticeJsonString', true)
    if (!cacheNoticeJsonString) {
      exist6 = false
      exist7 = false
    }
    if (!exist6 && !exist7) {
      const res7 = await dsmRequest(this.context, '', 'SYNO.Core.DSMNotify.Strings', new url.URLParams({
        method: 'get',
        lang: 'chs'
      }).toString())
      if (res7 !== 'fail') {
        const noticeJsonString7 = JSON.stringify(res7)
        if (cacheNoticeJsonString) {
          await write(filePath7, noticeJsonString7)
        }
        return {
          jsonString: noticeJsonString7,
          dsmVersion: 7
        }
      } else {
        const res6 = await dsmRequest(this.context, '', 'SYNO.Core.Desktop.UIString', new url.URLParams({
          method: 'getjs',
          lang: 'chs'
        }).toString())
        if (res6 !== 'fail') {
          const noticeString = res6 as string
          const startIndex = noticeString.indexOf('=')
          const endIndex = noticeString.indexOf('}}')
          const noticeJsonString6 = noticeString.substring(startIndex + 1, endIndex + 2)
          if (cacheNoticeJsonString) {
            await write(filePath6, noticeJsonString6)
          }
          return {
            jsonString: noticeJsonString6,
            dsmVersion: 6
          }
        } else {
          return 'fail'
        }
      }
    } else {
      let filestring = ''
      if (exist6) {
        filestring = await read(filePath6)
      } else {
        filestring = await read(filePath7)
      }
      if (filestring !== 'fail') {
        if (exist6) {
          return {
            jsonString: filestring,
            dsmVersion: 6
          }
        } else {
          return {
            jsonString: filestring,
            dsmVersion: 7
          }
        }
      } else {
        return 'fail'
      }
    }
  }

  async get() {
    this.loading = true
    const res = await dsmRequest(this.context, '', 'SYNO.Core.DSMNotify', new url.URLParams({
      method: 'notify',
      action: 'load'
    }).toString())
    if (res !== 'fail') {
      const noticeres = res as NoticeResponseData
      if (noticeres.items.length > 0) {
        const noticeJsonString = await this.getNoticeJsonString()
        if (noticeJsonString !== 'fail') {
          this.loading = false
          if (noticeJsonString.dsmVersion === 6) {
            const noticeJson = JSON.parse(noticeJsonString.jsonString) as Record<string, Record<string, string>>
            this.notices = noticeres.items.map((item): NoticeItem => {
              const filterTitle = item.title.split(':')
              return {
                level: '',
                className: noticeJson[filterTitle[0]][filterTitle[1]],
                title: item.mailContent ? item.mailContent : item.msg[0],
                time: item.time,
                msg: []
              }
            })
          }
          if (noticeJsonString.dsmVersion === 7) {
            const noticeString = JSON.parse(noticeJsonString.jsonString) as Record<string, NoticeString>
            this.notices = noticeres.items.map((item): NoticeItem => {
              const msgJson = JSON.parse(item.msg[0]) as object
              return {
                level: item.level,
                className: noticeString[item.title].title,
                title: noticeString[item.title].msg.replace(/%(\w+)%/g, (match): string => msgJson[match]),
                time: item.time,
                msg: []
              }
            })
          }
        }
      }
      if (noticeres.items.length === 0) {
        this.loading = false
        this.notices = []
      }
    }
    if (res === 'fail') {
      this.loading = false
    }
  }

  build() {
    Scroll() {
      Column() {
        if (this.loading) {
          LoadingProgress()
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('20%')
        }
        if (!this.loading) {
          Button('清除全部')
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .role(ButtonRole.ERROR)
            .width('100%')
            .onClick(async () => {
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '清除中...'
                })
              })
              dialogControllerProgress.open()
              const res = await dsmRequest(this.context, '', 'SYNO.Core.DSMNotify', new url.URLParams({
                method: 'notify',
                action: 'apply',
                clean: 'all'
              }).toString())
              dialogControllerProgress.close()
              if (res !== 'fail') {
                await promptAction.openToast({
                  message: '清除成功'
                })
                await this.get()
              }
            })
        }
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
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Text(item.level === 'NOTIFICATION_INFO' ? '信息' :
                    item.level === 'NOTIFICATION_WARN' ? '警告' :
                      item.level === 'NOTIFICATION_ERROR' ? '重要' : '未知')
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
                    .enableAutoSpacing(true)
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
                  Text(String(new Date(item.time * 1000)))
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
        .layoutWeight(1)
      }
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      await this.get()
    })
  }
}