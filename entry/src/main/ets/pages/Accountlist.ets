import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { AccountInfo, getAccountList, removeAccount, setAccount } from '../common/Account'
import { getDnsServer } from '../common/Dnsserver'

@ComponentV2
export default struct Accountlist {
  @Consumer() isShowAccountlistSheet: boolean = false
  @Local accountArray: AccountInfo[] = []
  @Local pathConnectionStatusArray: string[] = []
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  commonSettingDataPreferences = preferences.getPreferencesSync(this.context, {
    name: 'commonSetting'
  })

  @Builder
  MenuBuilder(item: AccountInfo) {
    Menu() {
      MenuItem({
        startIcon: $r('app.media.delete'),
        content: '删除'
      })
        .onClick(async () => {
          const promptAction = this.UIContext.getPromptAction()
          const data = await promptAction.showDialog({
            title: '提示',
            message: '删除成功后无法恢复，确定删除？',
            buttons: [
              {
                text: '取消',
                color: $r('sys.color.font_primary')
              },
              {
                text: '删除',
                color: $r('sys.color.warning')
              }
            ]
          })
          if (data.index === 1) {
            await removeAccount(item.id)
            this.accountArray = await getAccountList()
            if (item.isLogin === 'true') {
              this.context.eventHub.emit('refreshMe')
              this.isShowAccountlistSheet = false
            }
          }
        })
    }
  }

  build() {
    List() {
      ListItem() {
        Row() {
          Text('切换账号')
            .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Column() {
            Image($r('app.media.new'))
          }
          .borderRadius(20)
          .height(40)
          .margin({
            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
          })
          .padding(11)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .visualEffect(new hdsEffect.HdsEffectBuilder()
            .pointLight({
              sourceType: hdsEffect.PointLightSourceType.SOFT,
              illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
            })
            .buildEffect())
          .width(40)
          .onClick(() => {
            this.context.eventHub.emit('login')
            this.isShowAccountlistSheet = false
          })

          Column() {
            Image($r('app.media.cancel'))
          }
          .borderRadius(20)
          .height(40)
          .padding(11)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.interactive_hover'))
            },
            pressed: {
              .backgroundColor($r('sys.color.interactive_pressed'))
            }
          })
          .visualEffect(new hdsEffect.HdsEffectBuilder()
            .pointLight({
              sourceType: hdsEffect.PointLightSourceType.SOFT,
              illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
            })
            .buildEffect())
          .width(40)
          .onClick(() => {
            this.isShowAccountlistSheet = false
          })
        }
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
      .padding({
        left: $r('sys.float.ohos_id_default_padding_start'),
        right: $r('sys.float.ohos_id_default_padding_end')
      })

      if (this.accountArray.length === 0) {
        ListItem() {
          Text('无账号')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .padding({
          left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
          right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
        })
        .width('100%')
      }
      ListItem() {
        Column() {
          ForEach(this.accountArray, (item: AccountInfo, index) => {
            if (index !== 0) {
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
            }
            Row() {
              if (this.pathConnectionStatusArray[index] === 'connecting') {
                Circle({
                  height: 16,
                  width: 16
                })
                  .fill(Color.Orange)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
              }
              if (this.pathConnectionStatusArray[index] === 'connected') {
                Circle({
                  height: 16,
                  width: 16
                })
                  .fill(Color.Green)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
              }
              if (this.pathConnectionStatusArray[index] === 'disconnected') {
                Circle({
                  height: 16,
                  width: 16
                })
                  .fill(Color.Red)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
              }
              Column() {
                Text(item.name)
                  .fontWeight(FontWeight.Medium)
                Text(item.path)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .margin({
                    top: $r('sys.float.ohos_id_text_margin_vertical')
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .borderRadius(12)
            .padding(12)
            .stateStyles({
              normal: {
                .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
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
                this.hoverId = 0
              }
            })
            .onClick(async () => {
              if (item.isLogin === 'true') {
                this.isShowAccountlistSheet = false
                return
              }
              await setAccount(this.context, this.UIContext, {
                path: item.path,
                name: item.name,
                password: item.password,
                sid: item.sid,
                did: item.did
              })
              await promptAction.openToast({
                message: '登录成功'
              })
              this.context.eventHub.emit('refreshCardlist')
              this.context.eventHub.emit('refreshFilelist')
              if (this.commonSettingDataPreferences.getSync('showAlbum', true)) {
                this.context.eventHub.emit('refreshAlbum')
              }
              this.context.eventHub.emit('refreshMe')
              this.isShowAccountlistSheet = false
            })
            .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress, {
              hapticFeedbackMode: HapticFeedbackMode.AUTO
            })
            .bindContextMenu(this.MenuBuilder(item), ResponseType.RightClick)
          })
        }
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed')
    })
    .onAppear(async () => {
      this.accountArray = await getAccountList()
      this.pathConnectionStatusArray = Array(this.accountArray.length).fill('connecting')
      this.accountArray.forEach(async (item, index) => {
        const session = rcp.createSession({
          requestConfiguration: {
            dns: {
              dnsRules: getDnsServer(this.context)
            }
          }
        })
        try {
          const response = await session.get(item.path + '/webapi/entry.cgi')
          session.close()
          if (response.statusCode === 200) {
            this.pathConnectionStatusArray[index] = 'connected'
          } else {
            this.pathConnectionStatusArray[index] = 'disconnected'
          }
        } catch {
          session.close()
          this.pathConnectionStatusArray[index] = 'disconnected'
        }
      })
    })
  }
}