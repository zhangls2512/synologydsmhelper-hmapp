import openLink from '../common/Openlink'

interface Item {
  property: string,
  value: string
}

interface ItemWithDesc {
  property: string,
  value: string,
  desc: string
}

@Builder
export function LicenseBuilder() {
  License()
}

@ComponentV2
struct License {
  gabaInfoArray: Item[] = [
    { property: '名称', value: '轩铭密码智能备忘录' },
    { property: '主体类型', value: '个人' },
    { property: '开办者名称', value: '张**' },
    { property: '注册地公安机关', value: '萨尔图区网安大队' },
    { property: '注册时间', value: '2025-05-14' }
  ]
  tscjInfoArray: ItemWithDesc[] = [
    {
      property: '适老化',
      value: '轩铭2512适备12号-1L',
      desc: '字体跟随系统关怀模式设置放大'
    },
    {
      property: '无障碍',
      value: '轩铭2512适备12号-2Z',
      desc: '尽可能多地使用系统组件、API，以最大化地利用系统内置的无障碍特性'
    },
    {
      property: '大小屏',
      value: '轩铭2512适备12号-3P',
      desc: '适配平板、PC 大屏'
    },
    {
      property: '特殊网络环境',
      value: '轩铭2512适备12号-4W',
      desc: '无网环境使用在线功能时弹窗提示'
    },
    {
      property: '深色模式',
      value: '轩铭2512适备12号-5S',
      desc: '界面跟随“我的”>“设置”>“通用”>“通用”>“界面”>“深色模式”设置改变颜色主题'
    }
  ]

  build() {
    NavDestination() {
      List() {
        ListItem() {
          Text() {
            Span('ICP备案：')
            Span('黑ICP备2024023054号-9A')
              .fontColor($r('sys.color.font_emphasize'))
              .onClick(() => {
                openLink('https://beian.miit.gov.cn/#/Integrated/recordQuery')
              })
          }
          .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('公安备案')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                openLink('https://beian.mps.gov.cn/#/query/appSearch')
              })
            Flex({
              alignItems: ItemAlign.Stretch,
              wrap: FlexWrap.Wrap
            }) {
              ForEach(this.gabaInfoArray, (item: Item) => {
                Column() {
                  Text(item.property)
                    .fontWeight(FontWeight.Medium)
                    .textAlign(TextAlign.Center)
                }
                .border({
                  color: $r('sys.color.font_primary'),
                  width: {
                    right: 1,
                    top: 1
                  }
                })
                .justifyContent(FlexAlign.Center)
                .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
                .width('50%')

                Column() {
                  Text(item.value)
                    .textAlign(TextAlign.Center)
                }
                .border({
                  color: $r('sys.color.font_primary'),
                  width: {
                    top: 1
                  }
                })
                .justifyContent(FlexAlign.Center)
                .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
                .width('50%')
              })
            }
            .border({
              color: $r('sys.color.font_primary'),
              width: {
                bottom: 1,
                left: 1,
                right: 1
              }
            })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Text() {
            Span('产品备案：')
            Span('轩铭2512品备12号-HA')
              .fontColor($r('sys.color.font_emphasize'))
              .onClick(() => {
                openLink('https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=轩铭2512品备12号-HA')
              })
          }
          .enableAutoSpacing(true)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('许可')
              .fontWeight(FontWeight.Bold)
            Flex({
              alignItems: ItemAlign.Stretch,
              wrap: FlexWrap.Wrap
            }) {
              Column() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('许可号')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('敏感信息收集处理服务')
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('轩铭2512许12号-1M')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_emphasize'))
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    openLink('https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=轩铭2512许12号-1M')
                  })
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')
            }
            .border({
              color: $r('sys.color.font_primary'),
              width: {
                bottom: 1,
                left: 1,
                right: 1
              }
            })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('特殊场景适配备案')
              .fontWeight(FontWeight.Bold)
            Flex({
              alignItems: ItemAlign.Stretch,
              wrap: FlexWrap.Wrap
            }) {
              Column() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('备案号')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              ForEach(this.tscjInfoArray, (item: ItemWithDesc) => {
                Column() {
                  Text(item.property)
                    .fontColor($r('sys.color.font_emphasize'))
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      const promptAction = this.getUIContext().getPromptAction()
                      promptAction.showDialog({
                        title: '描述',
                        message: item.desc,
                        buttons: [
                          {
                            text: '确定',
                            color: $r('sys.color.font_emphasize')
                          }
                        ]
                      })
                    })
                }
                .border({
                  color: $r('sys.color.font_primary'),
                  width: {
                    right: 1,
                    top: 1
                  }
                })
                .justifyContent(FlexAlign.Center)
                .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
                .width('50%')

                Column() {
                  Text(item.value)
                    .enableAutoSpacing(true)
                    .fontColor($r('sys.color.font_emphasize'))
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      openLink('https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=' + item.value)
                    })
                }
                .border({
                  color: $r('sys.color.font_primary'),
                  width: {
                    top: 1
                  }
                })
                .justifyContent(FlexAlign.Center)
                .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
                .width('50%')
              })
            }
            .border({
              color: $r('sys.color.font_primary'),
              width: {
                bottom: 1,
                left: 1,
                right: 1
              }
            })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('隐私安全备案')
              .fontWeight(FontWeight.Bold)
            Flex({
              alignItems: ItemAlign.Stretch,
              wrap: FlexWrap.Wrap
            }) {
              Column() {
                Text('描述')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('备案号')
                  .fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('有隐私相关功能，包括但不限于权限管理、业务与隐私的声明、第三方SDK列表、已收集个人信息清单、隐私声明摘要')
                  .enableAutoSpacing(true)
                  .textAlign(TextAlign.Center)
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  right: 1,
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')

              Column() {
                Text('轩铭2512私安备12号-1')
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_emphasize'))
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    openLink('https://www.zhangls2512.cn/product/baxk/jqcx?baxknumber=轩铭2512私安备12号-1')
                  })
              }
              .border({
                color: $r('sys.color.font_primary'),
                width: {
                  top: 1
                }
              })
              .justifyContent(FlexAlign.Center)
              .padding($r('sys.float.ohos_id_elements_margin_vertical_m'))
              .width('50%')
            }
            .border({
              color: $r('sys.color.font_primary'),
              width: {
                bottom: 1,
                left: 1,
                right: 1
              }
            })
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
      }
      .padding({
        bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .title('资质证照')
  }
}