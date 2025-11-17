import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { get, set } from './Account'
import { getDnsServer } from './Dnsserver'
import { read, write } from './File'
import { ResponseData } from '../pages/Login'

interface ApiVersionItem {
  name: string,
  version: number
}

interface ApiVersionCacheItem {
  path: string,
  apiVersion: ApiVersionItem[]
}

interface Error {
  code: number
}

interface DsmResponse {
  data: object,
  error: Error,
  success: boolean
}

interface DeveloperErrorResponse {
  errCode: number,
  errMsg: string,
  errFix: string
}

function getCacheApiVersion(context: Context, path: string, api: string) {
  const filePath = context.cacheDir + '/apiversion.txt'
  if (!fileIo.accessSync(filePath)) {
    return -1
  } else {
    const filestring = read(filePath, true)
    let apiVersionCache: ApiVersionCacheItem[] = []
    if (filestring !== 'fail') {
      apiVersionCache = JSON.parse(filestring) as ApiVersionCacheItem[]
    }
    const pathIndex = apiVersionCache.findIndex(item => item.path === path)
    if (pathIndex === -1) {
      return -1
    } else {
      const pathApiVersionCache = apiVersionCache[pathIndex].apiVersion
      const apiVersionIndex = pathApiVersionCache.findIndex(item => item.name === api)
      if (apiVersionIndex === -1) {
        return -1
      } else {
        return pathApiVersionCache[apiVersionIndex].version
      }
    }
  }
}

export async function getDsmApiMaxVersion(context: Context, path: string, api: string) {
  const accountInfo = await get()
  let requestPath = path
  if (!requestPath) {
    requestPath = accountInfo.path
  }
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const cacheApiVersion = getCacheApiVersion(context, requestPath, api)
  const cacheApiVersionSetting = commonSettingDataPreferences.getSync('cacheApiVersion', true)
  if (cacheApiVersionSetting && cacheApiVersion !== -1) {
    return cacheApiVersion
  }
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const session = rcp.createSession({
    requestConfiguration: {
      dns: {
        dnsRules: getDnsServer(context)
      },
      security: {
        remoteValidation: debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
          'system') as 'system' | 'skip'
      }
    },
    headers: {
      referer: requestPath
    }
  })
  try {
    const response = await session.get(requestPath + '/webapi/entry.cgi?api=SYNO.API.Info&version=1&method=query')
    session.close()
    if (response.statusCode === 200) {
      let body = ''
      if (response.toString()) {
        body = response.toString() as string
      }
      const res = JSON.parse(body) as DsmResponse
      if (res.success) {
        const version = res.data[api].maxVersion as number
        if (cacheApiVersionSetting) {
          const filePath = context.cacheDir + '/apiversion.txt'
          const filestring = read(filePath, true)
          let apiVersionCache: ApiVersionCacheItem[] = []
          if (filestring !== 'fail') {
            apiVersionCache = JSON.parse(filestring) as ApiVersionCacheItem[]
          }
          const pathIndex = apiVersionCache.findIndex(item => item.path === requestPath)
          if (pathIndex === -1) {
            apiVersionCache.push({
              path: requestPath,
              apiVersion: [
                {
                  name: api,
                  version: version
                }
              ]
            })
          } else {
            const pathApiVersionCache = apiVersionCache[pathIndex].apiVersion
            const apiVersionIndex = pathApiVersionCache.findIndex(item => item.name === api)
            if (apiVersionIndex === -1) {
              pathApiVersionCache.push({
                name: api,
                version: version
              })
            } else {
              pathApiVersionCache[apiVersionIndex].version = version
            }
          }
          write(filePath, JSON.stringify(apiVersionCache))
        }
        return version
      }
      promptAction.openToast({
        message: '接口调用失败，错误码：' + res.error.code
      })
      return 'fail'
    }
    promptAction.openToast({
      message: 'HTTP 请求失败，状态码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
    promptAction.openToast({
      message: 'DSM 请求失败，错误码：' + err.code
    })
    return 'fail'
  }
}

export async function dsmRequest(context: Context, UIContext: UIContext, path: string, api: string, params: string,
  version?: number): Promise<string | object> {
  const accountInfo = await get()
  let requestPath = path
  if (!requestPath) {
    requestPath = accountInfo.path
  }
  let apiVersion = version
  if (!apiVersion) {
    const maxVersion = await getDsmApiMaxVersion(context, path, api)
    if (maxVersion !== 'fail') {
      apiVersion = maxVersion
    } else {
      return 'fail'
    }
  }
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const session = rcp.createSession({
    requestConfiguration: {
      dns: {
        dnsRules: getDnsServer(context)
      },
      security: {
        remoteValidation: debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
          'system') as 'system' | 'skip'
      }
    },
    headers: {
      referer: requestPath
    },
    cookies: {
      id: accountInfo.sid,
      did: accountInfo.did
    }
  })
  try {
    const response = await session.get(requestPath + '/webapi/entry.cgi?api=' + api + '&version=' + apiVersion + params)
    session.close()
    if (response.statusCode === 200) {
      let body = ''
      if (response.toString()) {
        body = response.toString() as string
      }
      const res = JSON.parse(body) as DsmResponse
      if (res.success) {
        return res.data
      }
      if (res.error.code === 106 || res.error.code === 107 || res.error.code === 119) {
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const loginres = await dsmRequest(context, UIContext, accountInfo.path, 'SYNO.API.Auth',
          '&method=login&account=' + encodeURIComponent(accountInfo.name) + '&passwd=' +
          encodeURIComponent(accountInfo.password))
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (loginres !== 'fail') {
          const data = loginres as ResponseData
          await set(context, UIContext, {
            path: accountInfo.path,
            name: data.account,
            password: accountInfo.password,
            sid: data.sid,
            did: data.device_id
          })
          return await dsmRequest(context, UIContext, path, api, params, version)
        }
        promptAction.openToast({
          message: '登录态失效，请重新登录'
        })
        return 'fail'
      }
      if (res.error.code === 150) {
        return await dsmRequest(context, UIContext, path, api, params)
      }
      promptAction.openToast({
        message: '接口调用失败，错误码：' + res.error.code
      })
      return 'fail'
    }
    promptAction.openToast({
      message: 'HTTP 请求失败，状态码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
    promptAction.openToast({
      message: 'DSM 请求失败，错误码：' + err.code
    })
    return 'fail'
  }
}

export async function developerRequest(context: Context, UIContext: UIContext, path: string, body: rcp.RequestContent) {
  const promptAction = UIContext.getPromptAction()
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const allService = commonSettingDataPreferences.getSync('allService', true)
  if (!allService) {
    promptAction.showDialog({
      title: '全量模式未开启',
      message: '全量模式未开启，无法使用在线功能。如需使用在线功能，请前往“我的”>“设置”>“更多”>“应用服务模式”，开启全量模式。',
      buttons: [
        {
          text: '确定',
          color: $r('sys.color.font_emphasize')
        }
      ]
    })
    return 'fail'
  }
  const session = rcp.createSession({
    requestConfiguration: {
      dns: {
        dnsRules: getDnsServer(context)
      }
    }
  })
  try {
    const response = await session.post('https://api.zhangls2512.cn' + path, body)
    session.close()
    if (response.statusCode === 200) {
      let body = ''
      if (response.toString()) {
        body = response.toString() as string
      }
      const errCode = JSON.parse(body).errCode as number
      if (errCode === 0) {
        return body
      }
      const res = JSON.parse(body) as DeveloperErrorResponse
      promptAction.showDialog({
        title: '接口调用失败',
        message: '错误码：' + res.errCode + '\n错误信息：' + res.errMsg + '\n修复方法：' + res.errFix,
        buttons: [
          {
            text: '确定',
            color: $r('sys.color.font_emphasize')
          }
        ]
      })
      return 'fail'
    }
    promptAction.openToast({
      message: 'HTTP 请求失败，状态码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
    promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}