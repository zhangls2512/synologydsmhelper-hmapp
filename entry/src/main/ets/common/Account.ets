import { preferences } from '@kit.ArkData'
import { url, util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getDnsServer } from './Dnsserver'
import { readUri } from './File'
import { dsmRequest } from './Request'

export interface AccountInfo {
  id: string,
  path: string,
  name: string,
  password: string,
  sid: string,
  bz: string,
  isLogin: string
}

interface InAccountInfo {
  path: string,
  name: string,
  password: string,
  sid: string,
  bz: string,
  isLogin: string
}

export async function setAccount(context: Context, accountInfo: InAccountInfo) {
  await exitAccount(context, false)
  const accounts = await getAccountList()
  let accountIndex = -1
  accounts.forEach((item, index) => {
    if (accountInfo.path === item.path && accountInfo.name === item.name && accountInfo.password === item.password) {
      accountIndex = index
    }
  })
  const appAccountManager = appAccount.createAppAccountManager()
  if (accountIndex !== -1) {
    const id = accounts[accountIndex].id
    await appAccountManager.setCredential(id, 'sid', accountInfo.sid)
    await appAccountManager.setCustomData(id, 'bz', accountInfo.bz)
    await appAccountManager.setCustomData(id, 'isLogin', accountInfo.isLogin)
  }
  if (accountIndex === -1) {
    let oldAccountIndex = -1
    accounts.forEach((item, index) => {
      if (accountInfo.path === item.path && accountInfo.name === item.name) {
        oldAccountIndex = index
      }
    })
    const id = util.generateRandomUUID()
    await appAccountManager.createAccount(id, {
      customData: {
        path: accountInfo.path,
        name: accountInfo.name,
        bz: accountInfo.bz,
        isLogin: accountInfo.isLogin
      }
    })
    await appAccountManager.setCredential(id, 'password', accountInfo.password)
    await appAccountManager.setCredential(id, 'sid', accountInfo.sid)
    if (oldAccountIndex !== -1) {
      await removeAccount(accounts[oldAccountIndex].id)
    }
  }
}

export async function setAccountBz(id: string, bz: string) {
  const appAccountManager = appAccount.createAppAccountManager()
  await appAccountManager.setCustomData(id, 'bz', bz)
}

export async function getLoginStatus() {
  const res = await getAccountInfo()
  if (res.id) {
    return true
  }
  return false
}

export async function getAccountInfo(): Promise<AccountInfo> {
  const accounts = await getAccountList()
  const account = accounts.find(item => item.isLogin === 'true')
  if (account) {
    return account
  }
  return {
    id: '',
    path: '',
    name: '',
    password: '',
    sid: '',
    bz: '',
    isLogin: 'false'
  }
}

export async function getAccountList(): Promise<AccountInfo[]> {
  const appAccountManager = appAccount.createAppAccountManager()
  const appAccountIds = await appAccountManager.getAccountsByOwner('com.songjy.synologydsmhelper')
  const appAccounts: AccountInfo[] = []
  const promises = appAccountIds.map(async (item) => {
    let bz = ''
    try {
      bz = appAccountManager.getCustomDataSync(item.name, 'bz')
    } catch {
    }
    const id = item.name
    try {
      appAccounts.push({
        id: id,
        path: appAccountManager.getCustomDataSync(id, 'path'),
        name: appAccountManager.getCustomDataSync(id, 'name'),
        password: await appAccountManager.getCredential(id, 'password'),
        sid: await appAccountManager.getCredential(id, 'sid'),
        bz: bz,
        isLogin: appAccountManager.getCustomDataSync(item.name, 'isLogin')
      })
    } catch {
      const accountInfo: AccountInfo = {
        id: id,
        path: appAccountManager.getCustomDataSync(id, 'path'),
        name: appAccountManager.getCustomDataSync(id, 'name'),
        password: await appAccountManager.getCredential(id, 'password'),
        sid: appAccountManager.getCustomDataSync(id, 'sid'),
        bz: bz,
        isLogin: appAccountManager.getCustomDataSync(item.name, 'isLogin')
      }
      appAccounts.push(accountInfo)
      await removeAccount(id)
      const newId = util.generateRandomUUID()
      await appAccountManager.createAccount(newId, {
        customData: {
          path: accountInfo.path,
          name: accountInfo.name,
          bz: bz,
          isLogin: accountInfo.isLogin
        }
      })
      await appAccountManager.setCredential(id, 'password', accountInfo.password)
      await appAccountManager.setCredential(id, 'sid', accountInfo.sid)
    }
  })
  await Promise.all(promises)
  return appAccounts
}

export async function exitAccount(context: Context, logout: boolean) {
  const accounts = await getAccountList()
  const account = accounts.find(item => item.isLogin === 'true')
  if (account) {
    if (logout) {
      await dsmRequest(context, '', 'SYNO.API.Auth', new url.URLParams({
        method: 'logout'
      }).toString())
    }
    const appAccountManager = appAccount.createAppAccountManager()
    await appAccountManager.setCustomData(account.id, 'isLogin', 'false')
  }
}

export async function removeAccount(id: string) {
  const accounts = await getAccountList()
  if (accounts.find(item => item.id === id)) {
    const appAccountManager = appAccount.createAppAccountManager()
    await appAccountManager.removeAccount(id)
    await promptAction.openToast({
      message: '删除成功'
    })
  }
}

export async function importAccounts(context: Context, UIContext: UIContext, uri: string) {
  try {
    const array = await getAccountList()
    if (array.length > 0) {
      await promptAction.openToast({
        message: '导入失败，原因：本地存在账号'
      })
      return
    }
    const filestring = await readUri(uri)
    const accounts = JSON.parse(filestring) as AccountInfo[]
    const promises = accounts.map(async (item) => {
      const bz = item.bz ? item.bz : ''
      await setAccount(context, {
        path: item.path,
        name: item.name,
        password: item.password,
        sid: item.sid,
        bz: bz,
        isLogin: item.isLogin
      })
    })
    await Promise.all(promises)
    await promptAction.openToast({
      message: '导入成功'
    })
  } catch {
    await promptAction.openToast({
      message: '导入失败'
    })
  }
}

export async function loginBestPathAccount(context: Context) {
  const currentAccountInfo = await getAccountInfo()
  if (currentAccountInfo.bz) {
    const accountList = await getAccountList()
    const sameBzAccountList = accountList.filter(item => item.bz === currentAccountInfo.bz)
    if (sameBzAccountList.length > 1) {
      let bestPathAccountId = ''
      const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
        name: 'debugSetting'
      })
      const promises = sameBzAccountList.map(async (item, index) => {
        const session = rcp.createSession({
          requestConfiguration: {
            dns: {
              dnsRules: getDnsServer(context)
            },
            security: {
              remoteValidation: debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
                'system') as 'system' | 'skip'
            }
          }
        })
        context.eventHub.on('cancelTry' + index, (cancelTryIndex: number) => {
          if (cancelTryIndex !== index) {
            session.cancel()
          }
          context.eventHub.off('cancelTry' + index)
        })
        try {
          const response = await session.get(item.path + '/webapi/entry.cgi')
          session.close()
          if (response.statusCode === 200) {
            bestPathAccountId = item.id
            for (let i = 0; i < sameBzAccountList.length; i++) {
              context.eventHub.emit('cancelTry' + i, index)
            }
          }
        } catch {
          session.close()
        }
      })
      await Promise.all(promises)
      const bestPathAccount = sameBzAccountList.find(item => item.id === bestPathAccountId)
      if (bestPathAccount && bestPathAccountId !== currentAccountInfo.id) {
        await setAccount(context, {
          path: bestPathAccount.path,
          name: bestPathAccount.name,
          password: bestPathAccount.password,
          sid: bestPathAccount.sid,
          bz: bestPathAccount.bz,
          isLogin: 'true'
        })
      }
    }
  }
}