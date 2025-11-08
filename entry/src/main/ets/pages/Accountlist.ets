import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { AccountInfo, getList, remove, set } from '../common/Account'

@ComponentV2
export default struct Accountlist {
  @Consumer() isShowAccountlistSheet: boolean = false
  @Local accountArray: AccountInfo[] = []
  @Local hoverId: number = -1
  context = this.getUIContext().getHostContext() as common.UIAbilityContext

  @Builder
  MenuBuilder(item: AccountInfo) {
    Menu() {
      MenuItem({
        startIcon: $r('app.media.delete'),
        content: '删除'
      })
        .onClick(async () => {
          const promptAction = this.getUIContext().getPromptAction()
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
            await remove(item.id)
            this.accountArray = await getList()
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
      if (this.accountArray.length === 0) {
        ListItem() {
          Text('无账号')
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
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
                promptAction.openToast({
                  message: '已登录此账号，无需重复登录'
                })
                return
              }
              await set({
                path: item.path,
                name: item.name,
                password: item.password,
                sid: item.sid,
                did: item.did
              })
              promptAction.openToast({
                message: '登录成功'
              })
              this.context.eventHub.emit('refreshCardlist')
              this.context.eventHub.emit('refreshFilelist')
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
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(async () => {
      this.accountArray = await getList()
    })
  }
}