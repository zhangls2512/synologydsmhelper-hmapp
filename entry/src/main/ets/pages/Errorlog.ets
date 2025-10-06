import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { hiAppEvent } from '@kit.PerformanceAnalysisKit'
import { read } from '../common/File'
import copy from '../common/Pasteboard'

interface Item {
  type: string,
  content: string,
  time: string,
  externalLog: string[]
}

@Builder
export function ErrorlogBuilder() {
  Errorlog()
}

@ComponentV2
struct Errorlog {
  @Local errorLogArray: Item[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  get() {
    try {
      const errorLogFileName = fileIo.listFileSync(this.context.filesDir + '/log/error/')
      const errorLogFilePath = errorLogFileName.map(item => this.context.filesDir + '/log/error/' + item)
      this.errorLogArray = errorLogFilePath.map((item): Item => {
        const filestring = read(item)
        const errorLog = JSON.parse(filestring) as hiAppEvent.AppEventGroup
        const externalLog: string[] = []
        if (errorLog.appEventInfos) {
          errorLog.appEventInfos.forEach((item) => {
            const external_log = item.params['external_log'] as string[] | undefined
            if (external_log) {
              external_log.forEach((item) => {
                externalLog.push(item)
              })
            }
          })
        }
        return {
          type: errorLog.name,
          content: filestring,
          time: String(new Date(Number(item.replace(this.context.filesDir + '/log/error/', '').replace('.txt', '')))),
          externalLog: externalLog
        }
      })
    } catch (err) {
      if (err.code !== 13900002) {
        promptAction.openToast({
          message: '发生错误，错误码：' + err.code
        })
      }
    }
  }

  filter(type: string) {
    try {
      const errorLogFileName = fileIo.listFileSync(this.context.filesDir + '/log/error')
      const errorLogFilePath = errorLogFileName.map(item => this.context.filesDir + '/log/error/' + item)
      this.errorLogArray = errorLogFilePath.map((item): Item => {
        const filestring = read(item)
        const errorLog = JSON.parse(filestring) as hiAppEvent.AppEventGroup
        const externalLog: string[] = []
        if (errorLog.appEventInfos) {
          errorLog.appEventInfos.forEach((item) => {
            const external_log = item.params['external_log'] as string[] | undefined
            if (external_log) {
              external_log.forEach((item) => {
                externalLog.push(item)
              })
            }
          })
        }
        return {
          type: errorLog.name,
          content: filestring,
          time: String(new Date(Number(item.replace(this.context.filesDir + '/log/error/', '').replace('.txt', '')))),
          externalLog: externalLog
        }
      }).filter(item => item.type === type)
    } catch (err) {
      if (err.code !== 13900002) {
        promptAction.openToast({
          message: '发生错误，错误码：' + err.code
        })
      }
    }
  }

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Select([
            { value: '全部' },
            { value: 'js 运行异常' },
            { value: '应用崩溃' },
            { value: '应用冻屏' },
            { value: '应用查杀' },
            { value: '应用启动耗时' },
            { value: '资源泄漏' },
            { value: '地址越界' },
            { value: '主线程超时' },
            { value: '滑动丢帧' },
            { value: 'CPU 高负载' },
            { value: '24 小时功耗器件分解统计' }
          ])
            .selected(0)
            .value('全部')
            .onSelect((index: number) => {
              if (index === 0) {
                this.get()
              }
              if (index === 1) {
                this.filter('JS_ERROR')
              }
              if (index === 2) {
                this.filter('APP_CRASH')
              }
              if (index === 3) {
                this.filter('APP_FREEZE')
              }
              if (index === 4) {
                this.filter('APP_KILLED')
              }
              if (index === 5) {
                this.filter('APP_LAUNCH')
              }
              if (index === 6) {
                this.filter('RESOURCE_OVERLIMIT')
              }
              if (index === 7) {
                this.filter('ADDRESS_SANITIZER')
              }
              if (index === 8) {
                this.filter('MAIN_THREAD_JANK')
              }
              if (index === 9) {
                this.filter('SCROLL_JANK')
              }
              if (index === 10) {
                this.filter('CPU_USAGE_HIGH')
              }
              if (index === 11) {
                this.filter('BATTERY_USAGE')
              }
            })
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.errorLogArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.errorLogArray, (item: Item) => {
          ListItem() {
            Column() {
              Row() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .width('15%')
                Blank()
                  .width('5%')
                Text(item.type)
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
                Text('内容')
                  .fontWeight(FontWeight.Medium)
                  .width('15%')
                Blank()
                  .width('5%')
                Text(item.content)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('80%')
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .width('100%')
              .onClick(() => {
                copy(item.content)
              })

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
                Text(item.time)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .textAlign(TextAlign.End)
                  .width('80%')
              }
              .borderRadius(12)
              .padding(12)
              .width('100%')

              ForEach(item.externalLog, (externalLogItem: string) => {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text(externalLogItem)
                    .fontWeight(FontWeight.Medium)
                    .width('90%')
                  Blank()
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
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .width('100%')
                .onClick(async () => {
                  const filestring = read(externalLogItem)
                  if (filestring !== 'fail') {
                    const promptAction = this.getUIContext().getPromptAction()
                    const data = await promptAction.showDialog({
                      title: externalLogItem,
                      message: filestring,
                      buttons: [
                        {
                          text: '关闭',
                          color: $r('sys.color.warning')
                        },
                        {
                          text: '复制',
                          color: $r('sys.color.font_emphasize')
                        }
                      ]
                    })
                    if (data.index === 1) {
                      copy(filestring)
                    }
                  }
                })
              })
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
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('故障日志')
    .onAppear(() => {
      this.get()
    })
  }
}