import { common } from '@kit.AbilityKit'
import { display, LoadingDialog } from '@kit.ArkUI'
import { hdsEffect } from '@kit.UIDesignKit'
import { exit, get } from '../common/Account'
import Accountlist from './Accountlist'
import Login from './Login'
import Setting from './Setting'

@ComponentV2
export default struct Me {
  @Provider() isShowLoginSheet: boolean = false
  @Provider() isShowAccountlistSheet: boolean = false
  @Local isShowSettingSheet: boolean = false
  @Local name: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferType = 1

  async get() {
    const accountInfo = await get()
    this.name = accountInfo.name
  }

  @Builder
  LoginSheetBuilder() {
    Login()
  }

  @Builder
  AccountlistSheetBuilder() {
    Accountlist()
  }

  @Builder
  SettingSheetBuilder() {
    Setting()
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.foreground'))
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(40)
            if (!this.name) {
              Text('登录')
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
            }
            if (this.name) {
              Text(this.name)
                .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
            }
          }
          .borderRadius(12)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onClick(() => {
            if (!this.name) {
              this.isShowLoginSheet = true
            }
          })
          .bindSheet(this.isShowLoginSheet!!, this.LoginSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '登录'
            },
            onDisappear: () => {
              this.get()
            }
          })

          Divider()
            .padding({
              left: 12,
              right: 12
            })
          Row() {
            Image($r('app.media.users'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('切换账号')
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
          .justifyContent(FlexAlign.SpaceBetween)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onClick(() => {
            this.isShowAccountlistSheet = true
          })
          .bindSheet(this.isShowAccountlistSheet!!, this.AccountlistSheetBuilder(), {
            height: SheetSize.FIT_CONTENT,
            preferType: this.preferType,
            title: {
              title: '切换账号'
            },
            onDisappear: () => {
              this.get()
            }
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }

      ListItem() {
        Column() {
          Row() {
            Image($r('app.media.setting'))
              .fillColor($r('sys.color.icon_primary'))
              .height(24)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .width(24)
            Text('设置')
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
          .justifyContent(FlexAlign.SpaceBetween)
          .padding(12)
          .stateStyles({
            normal: {
              .backgroundColor($r('sys.color.comp_background_primary'))
            },
            pressed: {
              .backgroundColor($r('sys.color.comp_background_secondary'))
            }
          })
          .width('100%')
          .onClick(() => {
            this.isShowSettingSheet = true
          })
          .bindSheet(this.isShowSettingSheet!!, this.SettingSheetBuilder(), {
            preferType: this.preferType,
            onDisappear: () => {
              this.get()
            }
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
        .padding($r('sys.float.ohos_id_corner_radius_mark'))
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      if (this.name) {
        ListItem() {
          Button('退出登录')
            .buttonStyle(ButtonStyleMode.NORMAL)
            .fontColor($r('sys.color.warning'))
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .onClick(async () => {
              const promptAction = this.getUIContext().getPromptAction()
              const data = await promptAction.showActionMenu({
                title: '是否注销会话？（注销后无法使用切换账号功能一键登录）',
                buttons: [
                  {
                    text: '是',
                    color: $r('sys.color.warning')
                  },
                  {
                    text: '否',
                    color: $r('sys.color.font_primary')
                  }
                ]
              })
              if (data.index === 0) {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '注销会话中...'
                  })
                })
                dialogControllerProgress.open()
                await exit(true)
                dialogControllerProgress.close()
              }
              if (data.index === 1) {
                await exit(false)
              }
              promptAction.openToast({
                message: '退出成功'
              })
              this.name = ''
            })
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })
        .width('100%')
      }
    }
    .padding({
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      const currentOrientation = display.getDefaultDisplaySync().orientation
      if (currentOrientation === display.Orientation.PORTRAIT ||
        currentOrientation === display.Orientation.PORTRAIT_INVERTED) {
        this.preferType = 0
      }
      if (currentOrientation === display.Orientation.LANDSCAPE ||
        currentOrientation === display.Orientation.LANDSCAPE_INVERTED) {
        this.preferType = 1
      }
      display.on('change', (displayId) => {
        const orientation = display.getDisplayByIdSync(displayId).orientation
        if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
          this.preferType = 0
        }
        if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
          this.preferType = 1
        }
      })
      this.context.eventHub.on('refreshMe', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshMe')
      display.off('change')
    })
  }
}