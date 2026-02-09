import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getAccountInfo, setAccount } from './Account'
import { getDnsServer } from './Dnsserver'
import { read, write } from './File'
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

async function getCacheApiVersion(context: Context, path: string, api: string) {
  let apiVersionCacheValue = ''
  const filePath = context.cacheDir + '/apiversion.txt'
  if (!fileIo.accessSync(filePath)) {
    return -1
  } else {
    const filestring = await read(filePath)
    if (filestring !== 'fail') {
      apiVersionCacheValue = filestring
    } else {
      return -1
    }
  }
  if (!apiVersionCacheValue) {
    return -1
  } else {
    const apiVersionCache = JSON.parse(apiVersionCacheValue) as ApiVersionCacheItem[]
    const apiVersionCacheItem = apiVersionCache.find(item => item.path === path)
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

export async function getDsmApiMaxVersion(context: Context, path: string, api: string) {
  const accountInfo = await getAccountInfo()
  let requestPath = path
  if (!requestPath) {
    if (!accountInfo.path) {
      return 'fail'
    }
    requestPath = accountInfo.path
  }
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const cacheApiVersionSetting = commonSettingDataPreferences.getSync('cacheApiVersion', true)
  if (cacheApiVersionSetting) {
    const cacheApiVersion = await getCacheApiVersion(context, requestPath, api)
    if (cacheApiVersion !== -1) {
      return cacheApiVersion
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
          'system') as 'system' | 'skip',
        tlsRange: {
          min: 'TlsV1.2'
        }
      }
    },
    headers: {
      referer: requestPath,
      'x-syno-token': accountInfo.synotoken
    }
  })
  try {
    const response = await session.get(requestPath + '/webapi/entry.cgi?' + new url.URLParams({
      api: 'SYNO.API.Info',
      version: '1',
      method: 'query'
    }).toString())
    session.close()
    if (response.statusCode === 200) {
      let body = ''
      if (response.toString()) {
        body = response.toString() as string
      }
      const res = JSON.parse(body) as DsmResponse
      if (res.success) {
        if (!res.data[api]) {
          await promptAction.openToast({
            message: '当前登录的 DSM 不支持此功能'
          })
          return 'fail'
        }
        const version = res.data[api].maxVersion as number
        if (cacheApiVersionSetting) {
          let apiVersionCache: ApiVersionCacheItem[] = []
          const filePath = context.cacheDir + '/apiversion.txt'
          const filestring = await read(filePath, true)
          if (filestring !== 'fail') {
            apiVersionCache = JSON.parse(filestring) as ApiVersionCacheItem[]
          }
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
        const sessionb = rcp.createSession({
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
            referer: requestPath,
            'x-syno-token': accountInfo.synotoken
          }
        })
        try {
          const responseb = await sessionb.get(requestPath + '/webapi/query.cgi?' + new url.URLParams({
            api: 'SYNO.API.Info',
            version: '1',
            method: 'query'
          }).toString())
          sessionb.close()
          if (responseb.statusCode === 200) {
            let bodyb = ''
            if (responseb.toString()) {
              bodyb = responseb.toString() as string
            }
            const resb = JSON.parse(bodyb) as DsmResponse
            if (resb.success) {
              if (!resb.data[api]) {
                await promptAction.openToast({
                  message: '当前登录的 DSM 不支持此功能：' + api
                })
                return 'fail'
              }
              const version = resb.data[api].maxVersion as number
              if (cacheApiVersionSetting) {
                let apiVersionCache: ApiVersionCacheItem[] = []
                const filePath = context.cacheDir + '/apiversion.txt'
                const filestring = await read(filePath, true)
                if (filestring !== 'fail') {
                  apiVersionCache = JSON.parse(filestring) as ApiVersionCacheItem[]
                }
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
          }
          await promptAction.openToast({
            message: 'HTTP 请求失败，状态码：' + responseb.statusCode
          })
          return 'fail'
        } catch (err) {
          sessionb.close()
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code
          })
          return 'fail'
        }
      }
      await promptAction.openToast({
        message: 'DSM 接口调用失败，错误码：' + res.error.code
      })
      return 'fail'
    }
    await promptAction.openToast({
      message: 'HTTP 请求失败，状态码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}

export async function dsmRequest(context: Context, path: string, api: string, params: string, version?: number,
  dsm6Login?: boolean, hide102ErrorCode?: boolean): Promise<string | object> {
  const accountInfo = await getAccountInfo()
  let requestPath = path
  if (!requestPath) {
    if (!accountInfo.path) {
      return 'fail'
    }
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
          'system') as 'system' | 'skip',
        tlsRange: {
          min: 'TlsV1.2'
        }
      }
    },
    headers: {
      'accept-language': 'zh-CN',
      referer: requestPath,
      'x-syno-token': accountInfo.synotoken
    },
    cookies: {
      id: accountInfo.sid
    }
  })
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
    const response = await session.get(path)
    session.close()
    if (response.statusCode === 200) {
      let body = ''
      if (response.toString()) {
        body = response.toString() as string
      }
      let res: string | DsmResponse = ''
      try {
        res = JSON.parse(body) as DsmResponse
      } catch {
        return body
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
          return await dsmRequest(context, path, api, params, version, dsm6Login, hide102ErrorCode)
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
          return await dsmRequest(context, path, api, params, version, dsm6Login, hide102ErrorCode)
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
    }
    await promptAction.openToast({
      message: 'HTTP 请求失败，状态码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
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
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const allService = commonSettingDataPreferences.getSync('allService', true)
  if (!allService) {
    context.eventHub.emit('dialog', '全量模式未开启',
      '全量模式未开启，无法使用在线功能。如需使用在线功能，请前往“我的”>“设置”>“更多”>“应用服务模式”，开启全量模式。')
    return 'fail'
  }
  const session = rcp.createSession({
    requestConfiguration: {
      dns: {
        dnsRules: getDnsServer(context)
      },
      security: {
        tlsRange: {
          min: 'TlsV1.2'
        }
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
      context.eventHub.emit('dialog', '接口调用失败',
        '错误码：' + res.errCode + '\n错误信息：' + res.errMsg + '\n修复方法：' + res.errFix)
      return 'fail'
    }
    await promptAction.openToast({
      message: 'HTTP 请求失败，状态码：' + response.statusCode
    })
    return 'fail'
  } catch (err) {
    session.close()
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}