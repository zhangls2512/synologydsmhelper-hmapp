import { appAccount } from '@kit.BasicServicesKit'

interface AccountInfo {
  path: string,
  name: string,
  password: string,
  sid: string,
  did: string
}

export async function set(accountInfo: AccountInfo) {
  const appAccountManager = appAccount.createAppAccountManager()
  await appAccountManager.createAccount('default', {
    customData: {
      path: accountInfo.path,
      name: accountInfo.name,
      sid: accountInfo.sid,
      did: accountInfo.did
    }
  })
  await appAccountManager.setCredential('default', 'password', accountInfo.password)
}

export async function get(): Promise<AccountInfo> {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    return {
      path: appAccountManager.getCustomDataSync('default', 'path'),
      name: appAccountManager.getCustomDataSync('default', 'name'),
      password: await appAccountManager.getCredential('default', 'password'),
      sid: appAccountManager.getCustomDataSync('default', 'sid'),
      did: appAccountManager.getCustomDataSync('default', 'did')
    }
  } catch {
    return {
      path: '',
      name: '',
      password: '',
      sid: '',
      did: ''
    }
  }
}

export async function remove() {
  const accountInfo = await get()
  if (accountInfo.path) {
    const appAccountManager = appAccount.createAppAccountManager()
    await appAccountManager.removeAccount('default')
  }
}