import { common } from '@kit.AbilityKit'
import { url } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import copy from '../common/Pasteboard'
import { defaultGlobalSession } from '../common/Request'
import { Param } from './Webview'

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
                  content: '请求中...'
                })
              })
              dialogControllerProgress.open()
              try {
                const response = await defaultGlobalSession.get(
                  'https://www.synology.cn/api/support/findDownloadInfo?' + new url.URLParams({
                    lang: 'zh-cn',
                    product: this.product
                  }).toString())
                dialogControllerProgress.close()
                if (response.statusCode >= 200 && response.statusCode < 300) {
                  const res = response.toJSON() as Response
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
                dialogControllerProgress.close()
                await promptAction.openToast({
                  message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
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
            ForEach(this.files, (item: FileItem) => {
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
                      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                    },
                    hovered: {
                      .backgroundColor($r('sys.color.interactive_hover'))
                    },
                    pressed: {
                      .backgroundColor($r('sys.color.interactive_pressed'))
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
                        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                      },
                      hovered: {
                        .backgroundColor($r('sys.color.interactive_hover'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .onClick(() => {
                      this.pageInfos.pushPath({
                        name: 'Webview',
                        param: {
                          url: item.allDownloadsUrl,
                          trust: false
                        } as Param
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
                        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                      },
                      hovered: {
                        .backgroundColor($r('sys.color.interactive_hover'))
                      },
                      pressed: {
                        .backgroundColor($r('sys.color.interactive_pressed'))
                      }
                    })
                    .onClick(() => {
                      this.pageInfos.pushPath({
                        name: 'Webview',
                        param: {
                          url: item.releaseNotesUrl,
                          trust: false
                        } as Param
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
            ListItem()
              .margin({
                bottom: 28
              })
          }
          .layoutWeight(1)
        }
        .margin({
          top: 64
        })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            },
            backIconStyle: {
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '群晖产品下载中心'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
    })
  }
}