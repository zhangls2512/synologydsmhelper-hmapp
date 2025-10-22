import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'

export function getPermission(permission: Permissions) {
  const atManager = abilityAccessCtrl.createAtManager()
  const status = atManager.getSelfPermissionStatus(permission)
  if (status === 0) {
    return true
  }
  return false
}

export async function checkPermission(permission: Permissions) {
  const atManager = abilityAccessCtrl.createAtManager()
  const status = atManager.getSelfPermissionStatus(permission)
  if (status === 0) {
    return true
  }
  const context = getContext()
  if (status === 1) {
    const res = await atManager.requestPermissionsFromUser(context, [permission])
    const authResult = res.authResults[0]
    if (authResult === 0) {
      return true
    }
  }
  if (status === -1) {
    const res = await atManager.requestPermissionOnSetting(context, [permission])
    const authResult = res[0]
    if (authResult === 0) {
      return true
    }
  }
  promptAction.showDialog({
    title: '提示',
    message: '请允许授权以使用此功能',
    buttons: [
      {
        text: '确定',
        color: $r('sys.color.font_emphasize')
      }
    ]
  })
  return false
}