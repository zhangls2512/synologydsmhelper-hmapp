import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { LoadingDialog } from '@kit.ArkUI'
import { getLoginStatus } from '../common/Account'
import { dsmRequest } from '../common/Request'

interface InstallPackageItem {
  name: string,
  version: string,
  latestVersion: string
}

interface ServerPackageItem {
  dname: string,
  version: string
}

@ComponentV2
export default struct Package {
  @Local installPackageArray: InstallPackageItem[] | undefined = undefined
  @Local status: string = 'fail'
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
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
    if ((cardSettingDataPreferences.getSync('cards', []) as string[]).includes('package') && this.status !== 'fail' &&
      isLogin) {
      let serverPackageArray: ServerPackageItem[] = []
      const serverofficalres = await dsmRequest(this.context, '', 'SYNO.Core.Package.Server', new url.URLParams({
        method: 'list',
        blloadothers: 'false'
      }).toString())
      if (serverofficalres !== 'fail') {
        serverPackageArray = serverPackageArray.concat(serverofficalres['packages'] as ServerPackageItem[])
      }
      const serverotherres = await dsmRequest(this.context, '', 'SYNO.Core.Package.Server', new url.URLParams({
        method: 'list',
        blloadothers: 'true'
      }).toString())
      if (serverotherres !== 'fail') {
        serverPackageArray = serverPackageArray.concat(serverotherres['packages'] as ServerPackageItem[])
      }
      const installres = await dsmRequest(this.context, '', 'SYNO.Core.Package', new url.URLParams({
        method: 'list'
      }).toString())
      if (installres !== 'fail') {
        const installPackageArray = installres['packages'] as InstallPackageItem[]
        this.installPackageArray = installPackageArray.map((item): InstallPackageItem => {
          const serverPackage = serverPackageArray.find(serverPackageItem => serverPackageItem.dname === item.name)
          return {
            name: item.name,
            version: item.version,
            latestVersion: serverPackage ? serverPackage.version : '-1'
          }
        })
        this.status = 'success'
      }
      if (installres === 'fail') {
        this.installPackageArray = undefined
        this.status = 'fail'
      }
    }
  }

  build() {
    Column() {
      if (this.status === 'pending' && !this.installPackageArray) {
        Text('获取数据中')
      }
      if (this.status === 'fail') {
        Text('获取数据失败')
      }
      if (this.installPackageArray) {
        Column() {
          Text('套件')
            .enableAutoSpacing(true)
            .fontWeight(FontWeight.Bold)
          ForEach(this.installPackageArray, (item: InstallPackageItem) => {
            if (item.version !== item.latestVersion && item.latestVersion !== '-1') {
              Row() {
                Text(item.name)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text('有新版本：' + item.latestVersion)
                  .fontColor(Color.Red)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
          })
          ForEach(this.installPackageArray, (item: InstallPackageItem) => {
            if (item.version === item.latestVersion) {
              Row() {
                Text(item.name)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.version + ' (最新)')
                  .fontColor(Color.Green)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
          })
          ForEach(this.installPackageArray, (item: InstallPackageItem) => {
            if (item.latestVersion === '-1') {
              Row() {
                Text(item.name)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.version)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
            }
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
      }, 10000)
      await this.refresh()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshCard')
    })
  }
}