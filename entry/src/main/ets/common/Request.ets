import { url } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getAccountInfo, setAccount } from './Account'
import { getDnsServer } from './Dnsserver'
import { read, write } from './File'
import { getFlushPreference } from './Preference'
import { AddressGroupItem } from '../pages/Addressgroup'
import { LoginResponseData } from '../pages/Login'

export interface ApiVersionItem {
  name: string,
  version: number
}

export interface ApiVersionCacheItem {
  path: string,
  apiVersion: ApiVersionItem[]
}

export interface DsmResponse {
  data: object,
  error: Error,
  success: boolean
}

interface Error {
  code: number
}

interface DeveloperErrorResponse {
  errCode: number,
  errMsg: string,
  errFix: string
}

let apiVersionCache: ApiVersionCacheItem[] | undefined = undefined

export let dsmGlobalSession: rcp.Session | undefined = undefined

export const defaultGlobalSession = rcp.createSession({
  requestConfiguration: {
    security: {
      tlsRange: {
        min: 'TlsV1.2'
      }
    }
  }
})

export function getDsmGlobalSession(context: Context) {
  if (!dsmGlobalSession) {
    dsmGlobalSession = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: getDnsServer(context)
        },
        security: {
          remoteValidation: getFlushPreference(context, 'debugSetting', 'closeRemoteValidationWhenLinkDsm',
            'system') as 'system' | 'skip',
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      }
    })
  }
  return dsmGlobalSession
}

async function getCacheApiVersion(context: Context, path: string, api: string) {
  if (!apiVersionCache) {
    const filePath = context.cacheDir + '/apiversion.txt'
    const filestring = await read(filePath, true)
    if (filestring !== 'fail') {
      try {
        apiVersionCache = JSON.parse(filestring)
      } catch {
        await fileIo.unlink(filePath)
        apiVersionCache = []
      }
    }
    if (filestring === 'fail') {
      apiVersionCache = []
    }
  }
  if (apiVersionCache) {
    if (apiVersionCache.length === 0) {
      return -1
    } else {
      let apiVersionCacheItem: ApiVersionCacheItem | undefined = undefined
      apiVersionCacheItem = apiVersionCache.find(item => item.path === path)
      if (!apiVersionCacheItem) {
        const addressGroupFilePath = context.filesDir + '/addressgroup.txt'
        if (fileIo.accessSync(addressGroupFilePath)) {
          const addressGroup = JSON.parse(fileIo.readTextSync(addressGroupFilePath)) as AddressGroupItem[]
          for (let i = 0; i < addressGroup.length; i++) {
            if (addressGroup[i].list.includes(path)) {
              for (let j = 0; j < addressGroup[i].list.length; j++) {
                const apiVersionCacheItemTemp = apiVersionCache.find(item => addressGroup[i].list[j] === item.path)
                if (apiVersionCacheItemTemp) {
                  apiVersionCacheItem = apiVersionCacheItemTemp
                }
              }
            }
          }
        }
      }
      if (!apiVersionCacheItem) {
        return -1
      } else {
        const pathApiVersionCache = apiVersionCacheItem.apiVersion
        const apiVersionItem = pathApiVersionCache.find(item => item.name === api)
        if (!apiVersionItem) {
          return -1
        } else {
          return apiVersionItem.version
        }
      }
    }
  }
  return -1
}

export async function getDsmApiMaxVersion(context: Context, path: string, api: string): Promise<number | 'fail'> {
  const accountInfo = await getAccountInfo(context)
  const requestPath = path ? path : accountInfo.path
  const cacheApiVersionSetting = getFlushPreference(context, 'commonSetting', 'cacheApiVersion', true)
  if (cacheApiVersionSetting) {
    const cacheApiVersion = await getCacheApiVersion(context, requestPath, api)
    if (cacheApiVersion !== -1) {
      return cacheApiVersion
    }
  }
  try {
    const response =
      await getDsmGlobalSession(context).fetch(new rcp.Request(requestPath + '/webapi/entry.cgi?' + new url.URLParams({
        api: 'SYNO.API.Info',
        version: '1',
        method: 'query'
      }).toString(), 'GET', {
        referer: requestPath,
        'x-syno-token': accountInfo.synotoken
      }))
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const res = response.toJSON() as DsmResponse
      const filePath = context.cacheDir + '/apiversion.txt'
      if (res.success) {
        if (!res.data[api]) {
          await promptAction.openToast({
            message: '当前登录的 DSM 不支持此功能'
          })
          return 'fail'
        }
        const version = res.data[api].maxVersion as number
        if (cacheApiVersionSetting && apiVersionCache) {
          const apiVersionCacheItem = apiVersionCache.find(item => item.path === requestPath)
          if (!apiVersionCacheItem) {
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
            const pathApiVersionCache = apiVersionCacheItem.apiVersion
            const apiVersionItem = pathApiVersionCache.find(item => item.name === api)
            if (!apiVersionItem) {
              pathApiVersionCache.push({
                name: api,
                version: version
              })
            } else {
              apiVersionItem.version = version
            }
          }
          await write(filePath, JSON.stringify(apiVersionCache))
        }
        return version
      }
      if (res.error.code === 102) {
        try {
          const responseb = await getDsmGlobalSession(context)
            .fetch(new rcp.Request(requestPath + '/webapi/query.cgi?' + new url.URLParams({
              api: 'SYNO.API.Info',
              version: '1',
              method: 'query'
            }).toString(), 'GET', {
              referer: requestPath,
              'x-syno-token': accountInfo.synotoken
            }))
          if (responseb.statusCode >= 200 && responseb.statusCode < 300) {
            const resb = responseb.toJSON() as DsmResponse
            if (resb.success) {
              if (!resb.data[api]) {
                await promptAction.openToast({
                  message: '当前登录的 DSM 不支持此功能：' + api
                })
                return 'fail'
              }
              const version = resb.data[api].maxVersion as number
              if (cacheApiVersionSetting && apiVersionCache) {
                const apiVersionCacheItem = apiVersionCache.find(item => item.path === requestPath)
                if (!apiVersionCacheItem) {
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
                  const pathApiVersionCache = apiVersionCacheItem.apiVersion
                  const apiVersionItem = pathApiVersionCache.find(item => item.name === api)
                  if (!apiVersionItem) {
                    pathApiVersionCache.push({
                      name: api,
                      version: version
                    })
                  } else {
                    apiVersionItem.version = version
                  }
                }
                await write(filePath, JSON.stringify(apiVersionCache))
              }
              return version
            }
            await promptAction.openToast({
              message: 'DSM 接口调用失败，错误码：' + resb.error.code
            })
            return 'fail'
          } else {
            await promptAction.openToast({
              message: 'HTTP 请求失败，状态码：' + responseb.statusCode
            })
            return 'fail'
          }
        } catch (err) {
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code
          })
          return 'fail'
        }
      }
      if (res.error.code === 103) {
        return await getDsmApiMaxVersion(context, path, api)
      }
      await promptAction.openToast({
        message: 'DSM 接口调用失败，错误码：' + res.error.code
      })
      return 'fail'
    } else {
      await promptAction.openToast({
        message: 'HTTP 请求失败，状态码：' + response.statusCode
      })
      return 'fail'
    }
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}

export async function dsmRequest(context: Context, path: string, api: string, params: string, version?: number,
  dsm6Login = false, hide102ErrorCode = false): Promise<string | object> {
  const accountInfo = await getAccountInfo(context)
  const requestPath = path ? path : accountInfo.path
  let apiVersion = version
  if (!apiVersion) {
    const maxVersion = await getDsmApiMaxVersion(context, path, api)
    if (maxVersion !== 'fail') {
      apiVersion = maxVersion
    } else {
      return 'fail'
    }
  }
  try {
    let path = requestPath + '/webapi/entry.cgi?' + new url.URLParams({
      api: api,
      version: String(apiVersion)
    }).toString() + '&' + params
    if (dsm6Login) {
      path = requestPath + '/webapi/auth.cgi?' + new url.URLParams({
        api: api,
        version: String(apiVersion),
        session: 'FileStation'
      }).toString() + '&' + params
    }
    const response = await getDsmGlobalSession(context).fetch(new rcp.Request(path, 'GET', {
      'accept-language': 'zh-CN',
      referer: requestPath,
      'x-syno-token': accountInfo.synotoken
    }, undefined, {
      id: accountInfo.sid
    }))
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const res = response.toJSON() as DsmResponse
      if (!res) {
        return String(response)
      }
      if (res.success) {
        return res.data
      }
      if (res.error.code === 106 || res.error.code === 107 || res.error.code === 119) {
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const loginres = await dsmRequest(context, accountInfo.path, 'SYNO.API.Auth', new url.URLParams({
          method: 'login',
          account: accountInfo.name,
          passwd: accountInfo.password,
          session: 'webui',
          enable_syno_token: 'yes'
        }).toString(), undefined, false, true)
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (loginres !== 'fail') {
          const data = loginres as LoginResponseData
          await setAccount(context, {
            path: accountInfo.path,
            name: accountInfo.name,
            password: accountInfo.password,
            sid: data.sid,
            synotoken: data.synotoken,
            bz: accountInfo.bz,
            isLogin: 'true'
          })
          const resb = await dsmRequest(context, '', api, params, version, dsm6Login, hide102ErrorCode)
          return resb
        }
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const loginresb = await dsmRequest(context, accountInfo.path, 'SYNO.API.Auth', new url.URLParams({
          method: 'login',
          account: accountInfo.name,
          passwd: accountInfo.password,
          session: 'webui',
          enable_syno_token: 'yes'
        }).toString(), undefined, true, hide102ErrorCode)
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (loginresb !== 'fail') {
          const data = loginresb as LoginResponseData
          await setAccount(context, {
            path: accountInfo.path,
            name: accountInfo.name,
            password: accountInfo.password,
            sid: data.sid,
            synotoken: data.synotoken,
            bz: accountInfo.bz,
            isLogin: 'true'
          })
          const resb = await dsmRequest(context, '', api, params, version, dsm6Login, hide102ErrorCode)
          return resb
        }
        await promptAction.openToast({
          message: '登录态失效，请重新登录'
        })
        return 'fail'
      }
      if (res.error.code === 150) {
        return await dsmRequest(context, path, api, params, version, dsm6Login, hide102ErrorCode)
      }
      await promptAction.openToast({
        message: 'DSM 接口调用失败，错误码：' + res.error.code
      })
      return 'fail'
    } else {
      await promptAction.openToast({
        message: 'HTTP 请求失败，状态码：' + response.statusCode
      })
      return 'fail'
    }
  } catch (err) {
    if (err.code !== 102) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
    if (err.code === 102 && !hide102ErrorCode) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
    return 'fail'
  }
}

export async function developerRequest(context: Context, path: string, body: rcp.RequestContent) {
  const allService = getFlushPreference(context, 'commonSetting', 'allService', true)
  if (!allService) {
    context.eventHub.emit('dialog', '全量模式未开启',
      '全量模式未开启，无法使用在线功能。如需使用在线功能，请前往“我的”>“设置”>“更多”>“应用服务模式”，开启全量模式。')
    return 'fail'
  }
  try {
    const response = await defaultGlobalSession.post('https://api.zhangls2512.cn' + path, body)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const res = response.toJSON() as DeveloperErrorResponse
      if (res.errCode === 0) {
        return String(response)
      }
      context.eventHub.emit('dialog', '接口调用失败',
        '错误码：' + res.errCode + '\n错误信息：' + res.errMsg + '\n修复方法：' + res.errFix)
      return 'fail'
    } else {
      await promptAction.openToast({
        message: 'HTTP 请求失败，状态码：' + response.statusCode
      })
      return 'fail'
    }
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}