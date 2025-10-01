import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'

export default function openLink(link: string) {
  const context = getContext() as common.UIAbilityContext
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const openLinkType = commonSettingDataPreferences.getSync('openLinkType', 0)
  if (openLinkType === 0) {
    context.openLink(link)
  }
  if (openLinkType === 1) {
    context.openLink(link, {
      parameters: {
        'ohos.ability.params.showDefaultPicker': true
      }
    })
  }
}