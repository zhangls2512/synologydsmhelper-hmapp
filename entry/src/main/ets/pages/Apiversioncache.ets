import { common } from '@kit.AbilityKit'
import { LengthMetrics, SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { read } from '../common/File'
import { ApiVersionCacheItem, ApiVersionItem } from '../common/Request'

@Builder
export function ApiversioncacheBuilder() {
  Apiversioncache()
}

@ComponentV2
struct Apiversioncache {
  @Local selectedIndex: number = 0
  @Local content: string = ''
  @Local array: ApiVersionCacheItem[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          TabSegmentButtonV2({
            items: new SegmentButtonV2Items([
              { text: '原始' },
              { text: '解析' }
            ]),
            selectedIndex: this.selectedIndex!!
          })
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          List() {
            if (!this.content) {
              ListItem() {
                Text('无数据')
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            if (this.selectedIndex === 0) {
              ListItem() {
                Text(this.content)
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
            if (this.selectedIndex === 1) {
              ForEach(this.array, (apiVersionCacheItem: ApiVersionCacheItem) => {
                ListItem() {
                  Column() {
                    Text(apiVersionCacheItem.path)
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .fontWeight(FontWeight.Medium)
                      .margin({
                        bottom: 6,
                        left: 12,
                        right: 12
                      })
                    Column() {
                      ForEach(apiVersionCacheItem.apiVersion, (apiVersionItem: ApiVersionItem, apiVersionIndex) => {
                        if (apiVersionIndex !== 0) {
                          Divider()
                            .padding({
                              left: 12,
                              right: 12
                            })
                        }
                        Row() {
                          Text(apiVersionItem.name)
                            .enableAutoSpacing(true)
                            .fontWeight(FontWeight.Medium)
                            .layoutWeight(1)
                            .margin({
                              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                            })
                          Text(String(apiVersionItem.version))
                            .fontColor($r('sys.color.font_secondary'))
                            .fontSize($r('sys.float.ohos_id_text_size_body2'))
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
                  .alignItems(HorizontalAlign.Start)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              })
            }
          }
          .layoutWeight(1)
        }
        .padding({
          bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
          left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
          right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
        })
      }
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('API 版本号缓存', {
      paddingEnd: LengthMetrics.vp(60)
    })
    .onAppear(async () => {
      const filePath = this.context.cacheDir + '/apiversion.txt'
      if (fileIo.accessSync(filePath)) {
        this.content = await read(filePath, true)
        this.array = JSON.parse(this.content)
      }
    })
  }
}