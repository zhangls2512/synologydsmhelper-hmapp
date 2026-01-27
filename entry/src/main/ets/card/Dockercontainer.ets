import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { getLoginStatus } from '../common/Account'
import { dsmRequest } from '../common/Request'

interface DockerContainerItem {
  name: string,
  status: string
}

@ComponentV2
export default struct Dockercontainer {
  @Local dockerContainerArray: DockerContainerItem[] | undefined = undefined
  @Local status: string = 'fail'
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '加载中...'
    })
  })

  async refresh() {
    const cardSettingDataPreferences = preferences.getPreferencesSync(this.context, {
      name: 'cardSetting'
    })
    const isLogin = await getLoginStatus()
    if ((cardSettingDataPreferences.getSync('cards', []) as string[]).includes('dockercontainer') &&
      this.status !== 'fail' && isLogin) {
      await this.get()
    }
  }

  async get() {
    const res = await dsmRequest(this.context, '', 'SYNO.Docker.Container', new url.URLParams({
      method: 'list',
      offset: '0',
      limit: '-1'
    }).toString())
    if (res !== 'fail') {
      this.dockerContainerArray = res['containers'] as DockerContainerItem[]
      this.status = 'success'
    }
    if (res === 'fail') {
      this.dockerContainerArray = undefined
      this.status = 'fail'
    }
  }

  build() {
    Column() {
      if (this.status === 'pending' && !this.dockerContainerArray) {
        Text('获取数据中')
      }
      if (this.status === 'fail') {
        Text('获取数据失败')
      }
      if (this.dockerContainerArray) {
        Column() {
          Text('Docker容器')
            .enableAutoSpacing(true)
            .fontWeight(FontWeight.Bold)
          ForEach(this.dockerContainerArray, (item: DockerContainerItem) => {
            Row() {
              Text(item.name)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              if (item.status === 'running') {
                Image($r('app.media.reboot'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    this.dialogControllerProgress.open()
                    const res = await dsmRequest(this.context, '', 'SYNO.Docker.Container', new url.URLParams({
                      method: 'restart',
                      name: item.name
                    }).toString())
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      await promptAction.openToast({
                        message: '重启成功'
                      })
                      await this.get()
                    }
                  })
                Image($r('app.media.shutdown'))
                  .height(24)
                  .onClick(async () => {
                    const promptAction = this.UIContext.getPromptAction()
                    const data = await promptAction.showActionMenu({
                      title: '是否强制？',
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
                      this.dialogControllerProgress.open()
                      const res = await dsmRequest(this.context, '', 'SYNO.Docker.Container', new url.URLParams({
                        method: 'signal',
                        name: item.name,
                        signal: '9'
                      }).toString())
                      this.dialogControllerProgress.close()
                      if (res !== 'fail') {
                        await promptAction.openToast({
                          message: '强制停止成功'
                        })
                        await this.get()
                      }
                    }
                    if (data.index === 1) {
                      this.dialogControllerProgress.open()
                      const res = await dsmRequest(this.context, '', 'SYNO.Docker.Container', new url.URLParams({
                        method: 'stop',
                        name: item.name
                      }).toString())
                      this.dialogControllerProgress.close()
                      if (res !== 'fail') {
                        await promptAction.openToast({
                          message: '停止成功'
                        })
                        await this.get()
                      }
                    }
                  })
              }
              if (item.status === 'stopped') {
                Image($r('app.media.start'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    this.dialogControllerProgress.open()
                    const res = await dsmRequest(this.context, '', 'SYNO.Docker.Container', new url.URLParams({
                      method: 'start',
                      name: item.name
                    }).toString())
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      await promptAction.openToast({
                        message: '启动成功'
                      })
                      await this.get()
                    }
                  })
                Image($r('app.media.delete'))
                  .height(24)
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
                      this.dialogControllerProgress.open()
                      const res = await dsmRequest(this.context, '', 'SYNO.Docker.Container', new url.URLParams({
                        method: 'delete',
                        name: item.name,
                        force: 'false',
                        preserve_profile: 'false'
                      }).toString())
                      this.dialogControllerProgress.close()
                      if (res !== 'fail') {
                        await promptAction.openToast({
                          message: '删除成功'
                        })
                        await this.get()
                      }
                    }
                  })
              }
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('100%')
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .padding(12)
    .width('100%')
    .onAppear(async () => {
      this.context.eventHub.on('refreshCard', async () => {
        this.status = 'pending'
        await this.refresh()
      })
      this.status = 'pending'
      setInterval(async () => {
        await this.refresh()
      }, 5000)
      await this.refresh()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCard')
    })
  }
}