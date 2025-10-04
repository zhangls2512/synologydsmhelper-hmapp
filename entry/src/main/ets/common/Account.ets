import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'

export interface AccountInfo {
  id: number,
  path: string,
  name: string,
  password: string,
  sid: string,
  did: string,
  isLogin: string
}

interface InAccountInfo {
  path: string,
  name: string,
  password: string,
  sid: string,
  did: string
}

export async function set(accountInfo: InAccountInfo) {
  await exit()
  const accounts = await getList()
  let accountIndex = -1
  accounts.forEach((item, index) => {
    if (accountInfo.path === item.path && accountInfo.name === item.name && accountInfo.password === item.password) {
      accountIndex = index
    }
  })
  const appAccountManager = appAccount.createAppAccountManager()
  if (accountIndex !== -1) {
    await appAccountManager.setCustomData(String(accounts[accountIndex].id), 'sid', accountInfo.sid)
    await appAccountManager.setCustomData(String(accounts[accountIndex].id), 'did', accountInfo.did)
    await appAccountManager.setCustomData(String(accounts[accountIndex].id), 'isLogin', 'true')
  }
  if (accountIndex === -1) {
    try {
      const id = String(Date.now())
      await appAccountManager.createAccount(id, {
        customData: {
          path: accountInfo.path,
          name: accountInfo.name,
          sid: accountInfo.sid,
          did: accountInfo.did,
          isLogin: 'true'
        }
      })
      await appAccountManager.setCredential(id, 'password', accountInfo.password)
    } catch (err) {
      promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
  }
}

export async function get(): Promise<AccountInfo> {
  const accounts = await getList()
  const index = accounts.findIndex(item => item.isLogin === 'true')
  if (index !== -1) {
    return accounts[index]
  }
  return {
    id: -1,
    path: '',
    name: '',
    password: '',
    sid: '',
    did: '',
    isLogin: 'false'
  }
}

export async function getList(): Promise<AccountInfo[]> {
  const appAccountManager = appAccount.createAppAccountManager()
  const appAccountIds = await appAccountManager.getAccountsByOwner('com.songjy.synologydsmhelper')
  const appAccounts: AccountInfo[] = []
  const promises = appAccountIds.map(async (item) => {
    appAccounts.push({
      id: Number(item.name),
      path: appAccountManager.getCustomDataSync(item.name, 'path'),
      name: appAccountManager.getCustomDataSync(item.name, 'name'),
      password: await appAccountManager.getCredential(item.name, 'password'),
      sid: appAccountManager.getCustomDataSync(item.name, 'sid'),
      did: appAccountManager.getCustomDataSync(item.name, 'did'),
      isLogin: appAccountManager.getCustomDataSync(item.name, 'isLogin')
    })
  })
  await Promise.all(promises)
  return appAccounts
}

export async function exit() {
  const accounts = await getList()
  const index = accounts.findIndex(item => item.isLogin === 'true')
  if (index !== -1) {
    const appAccountManager = appAccount.createAppAccountManager()
    await appAccountManager.setCustomData(String(accounts[index].id), 'isLogin', 'false')
  }
}

export async function remove(id: number) {
  const accounts = await getList()
  if (accounts.findIndex(item => item.id === id) !== -1) {
    const appAccountManager = appAccount.createAppAccountManager()
    await appAccountManager.removeAccount(String(id))
    promptAction.openToast({
      message: '删除成功'
    })
  }
}