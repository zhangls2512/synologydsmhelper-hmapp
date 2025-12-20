import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { readUri } from './File'
import { dsmRequest } from './Request'

export interface AccountInfo {
  id: string,
  path: string,
  name: string,
  password: string,
  sid: string,
  did: string,
  bz: string,
  isLogin: string
}

interface InAccountInfo {
  path: string,
  name: string,
  password: string,
  sid: string,
  did: string,
  bz?: string,
  isLogin?: string
}

export async function setAccount(context: Context, UIContext: UIContext, accountInfo: InAccountInfo) {
  await exitAccount(context, UIContext, false)
  const bz = accountInfo.bz ? accountInfo.bz : ''
  const isLogin = accountInfo.isLogin ? accountInfo.isLogin : 'true'
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
    await appAccountManager.setCredential(id, 'did', accountInfo.did)
    await appAccountManager.setCustomData(id, 'bz', bz)
    await appAccountManager.setCustomData(id, 'isLogin', isLogin)
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
        bz: bz,
        isLogin: isLogin
      }
    })
    await appAccountManager.setCredential(id, 'password', accountInfo.password)
    await appAccountManager.setCredential(id, 'sid', accountInfo.sid)
    await appAccountManager.setCredential(id, 'did', accountInfo.did)
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
    did: '',
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
        did: await appAccountManager.getCredential(id, 'did'),
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
        did: appAccountManager.getCustomDataSync(id, 'did'),
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
      await appAccountManager.setCredential(id, 'did', accountInfo.did)
    }
  })
  await Promise.all(promises)
  return appAccounts
}

export async function exitAccount(context: Context, UIContext: UIContext, logout: boolean) {
  const accounts = await getAccountList()
  const account = accounts.find(item => item.isLogin === 'true')
  if (account) {
    if (logout) {
      await dsmRequest(context, UIContext, '', 'SYNO.API.Auth', '&method=logout')
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
      await setAccount(context, UIContext, {
        path: item.path,
        name: item.name,
        password: item.password,
        sid: item.sid,
        did: item.did,
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