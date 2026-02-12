import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'
import { HdsNavDestination } from '@kit.UIDesignKit'
import { getDnsServer } from '../common/Dnsserver'
import copy from '../common/Pasteboard'

interface FileItem {
  name: string,
  desc: string,
  type: string,
  version: string,
  downloadUrl: string,
  allDownloadsUrl: string,
  releaseNotesUrl: string
}

interface Response {
  success: boolean,
  info: Info
}

interface Info {
  system: Detail,
  utilities: Detail,
  packages: Detail,
  docs: Detail,
  androids: Detail
}

interface Detail {
  detail: DetailItem[]
}

interface DetailItem {
  title: string,
  items: DetailItemItemsItem[]
}

interface DetailItemItemsItem {
  dname: string,
  descr: string,
  version: string,
  build_ver: string,
  build_num: string,
  files: DetailItemItemsItemItem[],
  notes: DetailItemItemsItemItem[]
}

interface DetailItemItemsItemItem {
  label: string,
  url: string,
  is_china: boolean
}

@Builder
export function SynologyproductdownloadcenterBuilder() {
  Synologyproductdownloadcenter()
}

@ComponentV2
struct Synologyproductdownloadcenter {
  @Local product: string = ''
  @Local files: FileItem[] = []
  @Local hoverId: number | string = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

  build() {
    HdsNavDestination() {
      Scroll() {
        Column() {
          TextInput({
            placeholder: '请输入产品型号',
            text: this.product!!
          })
            .defaultFocus(true)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          Button('查询')
            .enabled(this.product !== '' ? true : false)
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .width('100%')
            .onClick(async () => {
              this.files = []
              const dialogControllerProgress = new CustomDialogController({
                builder: LoadingDialog({
                  content: '查询中...'
                })
              })
              dialogControllerProgress.open()
              const session = rcp.createSession({
                requestConfiguration: {
                  dns: {
                    dnsRules: getDnsServer(this.context)
                  },
                  security: {
                    tlsRange: {
                      min: 'TlsV1.2'
                    }
                  }
                }
              })
              try {
                const response =
                  await session.get('https://www.synology.cn/api/support/findDownloadInfo?' + new url.URLParams({
                    lang: 'zh-cn',
                    product: this.product
                  }).toString())
                session.close()
                dialogControllerProgress.close()
                if (response.statusCode === 200) {
                  let body = ''
                  if (response.toString()) {
                    body = response.toString() as string
                  }
                  const res = JSON.parse(body) as Response
                  if (!res.success) {
                    await promptAction.openToast({
                      message: '暂不支持查询此产品型号'
                    })
                    return
                  }
                  if (res.info.system) {
                    res.info.system.detail.forEach(itema => {
                      itema.items.forEach(itemb => {
                        const allDownloadsUrl = itemb.notes.find(item => item.label === 'all_downloads')?.url
                        const releaseNotesUrl = itemb.notes.find(item => item.label === 'release_notes')?.url
                        this.files.push({
                          name: itemb.dname,
                          desc: itemb.descr,
                          type: itema.title,
                          version: itemb.build_ver ? itemb.build_ver + '.' + itemb.build_num : '',
                          downloadUrl: itemb.files[0].url,
                          allDownloadsUrl: allDownloadsUrl ? allDownloadsUrl : '',
                          releaseNotesUrl: releaseNotesUrl ? 'https://www.synology.cn/zh-cn' + releaseNotesUrl : ''
                        })
                      })
                    })
                  }
                  if (res.info.utilities) {
                    res.info.utilities.detail.forEach(itema => {
                      itema.items.forEach(itemb => {
                        const releaseNotesUrl = itemb.notes.find(item => item.label === 'release_notes')?.url
                        this.files.push({
                          name: itemb.dname,
                          desc: itemb.descr,
                          type: '桌面应用程序',
                          version: itemb.version,
                          downloadUrl: '',
                          allDownloadsUrl: '',
                          releaseNotesUrl: releaseNotesUrl ? 'https://www.synology.cn/zh-cn' + releaseNotesUrl : ''
                        })
                      })
                    })
                  }
                  if (res.info.packages) {
                    res.info.packages.detail.forEach(itema => {
                      itema.items.forEach(itemb => {
                        const releaseNotesUrl = itemb.notes.find(item => item.label === 'release_notes')?.url
                        this.files.push({
                          name: itemb.dname,
                          desc: itemb.descr,
                          type: 'DSM套件',
                          version: itemb.version,
                          downloadUrl: itemb.files[0].url,
                          allDownloadsUrl: '',
                          releaseNotesUrl: releaseNotesUrl ? 'https://www.synology.cn/zh-cn' + releaseNotesUrl : ''
                        })
                      })
                    })
                  }
                  if (res.info.docs) {
                    res.info.docs.detail.forEach(itema => {
                      itema.items.forEach(itemb => {
                        this.files.push({
                          name: itemb.dname,
                          desc: itemb.descr,
                          type: '文档',
                          version: '',
                          downloadUrl: itemb.files[0].url,
                          allDownloadsUrl: '',
                          releaseNotesUrl: ''
                        })
                      })
                    })
                  }
                  if (res.info.androids) {
                    res.info.androids.detail.forEach(itema => {
                      itema.items.forEach(itemb => {
                        const downloadUrl = itemb.files.find(item => item.is_china)?.url
                        const allDownloadsUrl = itemb.notes.find(item => item.label === 'all_downloads')?.url
                        const releaseNotesUrl = itemb.notes.find(item => item.label === 'release_notes')?.url
                        this.files.push({
                          name: itemb.dname,
                          desc: itemb.descr,
                          type: '安卓应用程序',
                          version: '',
                          downloadUrl: downloadUrl ? downloadUrl : '',
                          allDownloadsUrl: allDownloadsUrl ? allDownloadsUrl : '',
                          releaseNotesUrl: releaseNotesUrl ? 'https://www.synology.cn/zh-cn' + releaseNotesUrl : ''
                        })
                      })
                    })
                  }
                } else {
                  await promptAction.openToast({
                    message: 'HTTP 请求失败，状态码：' + response.statusCode
                  })
                }
              } catch (err) {
                session.close()
                dialogControllerProgress.close()
                await promptAction.openToast({
                  message: '发生错误，错误码：' + err.code
                })
              }
            })
          List() {
            if (this.files.length === 0) {
              ListItem() {
                Text('无数据')
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            ForEach(this.files, (item: FileItem, index) => {
              ListItem() {
                Column() {
                  Row() {
                    Text('名称')
                      .enableAutoSpacing(true)
                      .fontWeight(FontWeight.Medium)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Text(item.name)
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .layoutWeight(1)
                      .textAlign(TextAlign.End)
                  }
                  .borderRadius(12)
                  .padding(12)
                  .width('100%')

                  if (item.desc) {
                    Divider()
                      .padding({
                        left: 12,
                        right: 12
                      })
                    Row() {
                      Text('描述')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.desc)
                        .enableAutoSpacing(true)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .width('100%')
                  }
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Text('类型')
                      .fontWeight(FontWeight.Medium)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Text(item.type)
                      .enableAutoSpacing(true)
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .layoutWeight(1)
                      .textAlign(TextAlign.End)
                  }
                  .borderRadius(12)
                  .padding(12)
                  .width('100%')

                  if (item.version) {
                    Divider()
                      .padding({
                        left: 12,
                        right: 12
                      })
                    Row() {
                      Text('版本')
                        .fontWeight(FontWeight.Medium)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Text(item.version)
                        .fontColor($r('sys.color.font_secondary'))
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.End)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .width('100%')
                  }
                  Divider()
                    .padding({
                      left: 12,
                      right: 12
                    })
                  Row() {
                    Text('下载链接')
                      .fontWeight(FontWeight.Medium)
                      .layoutWeight(1)
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                      })
                    Image($r('app.media.right'))
                      .fillColor($r('sys.color.icon_fourth'))
                      .height(12)
                      .width(12)
                  }
                  .borderRadius(12)
                  .padding(12)
                  .stateStyles({
                    normal: {
                      .backgroundColor(this.hoverId === index + ',0' ? $r('sys.color.interactive_hover') :
                        $r('sys.color.ohos_id_color_card_bg'))
                    },
                    pressed: {
                      .backgroundColor($r('sys.color.interactive_pressed'))
                    }
                  })
                  .width('100%')
                  .onHover((isHover) => {
                    if (!isHover) {
                      this.hoverId = -1
                    }
                    if (isHover) {
                      this.hoverId = index + ',0'
                    }
                  })
                  .onClick(async () => {
                    await copy(this.context, this.UIContext, item.downloadUrl)
                  })

                  if (item.allDownloadsUrl) {
                    Divider()
                      .padding({
                        left: 12,
                        right: 12
                      })
                    Row() {
                      Text('所有下载')
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Image($r('app.media.right'))
                        .fillColor($r('sys.color.icon_fourth'))
                        .height(12)
                        .width(12)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .stateStyles({
                      normal: {
                        .backgroundColor(this.hoverId === index + ',1' ?
                          $r('sys.color.interactive_hover') : $r('sys.color.ohos_id_color_card_bg'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = index + ',1'
                      }
                    })
                    .onClick(() => {
                      this.pageInfos.pushPath({
                        name: 'Webview',
                        param: item.allDownloadsUrl
                      })
                    })
                  }
                  if (item.releaseNotesUrl) {
                    Divider()
                      .padding({
                        left: 12,
                        right: 12
                      })
                    Row() {
                      Text('发行说明')
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                      Image($r('app.media.right'))
                        .fillColor($r('sys.color.icon_fourth'))
                        .height(12)
                        .width(12)
                    }
                    .borderRadius(12)
                    .padding(12)
                    .stateStyles({
                      normal: {
                        .backgroundColor(this.hoverId === index + ',2' ?
                          $r('sys.color.interactive_hover') : $r('sys.color.ohos_id_color_card_bg'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .width('100%')
                    .onHover((isHover) => {
                      if (!isHover) {
                        this.hoverId = -1
                      }
                      if (isHover) {
                        this.hoverId = index + ',2'
                      }
                    })
                    .onClick(() => {
                      this.pageInfos.pushPath({
                        name: 'Webview',
                        param: item.releaseNotesUrl
                      })
                    })
                  }
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
        .alignItems(HorizontalAlign.Start)
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      content: {
        title: {
          mainTitle: '群晖产品下载中心'
        }
      },
      enableComponentSafeArea: true
    })
    .onReady((context) => {
      this.pageInfos = context.pathStack
    })
  }
}