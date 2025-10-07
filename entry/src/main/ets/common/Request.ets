import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { get, set } from './Account'
import { ResponseData } from '../pages/Login'

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

async function getDsmApiMaxVersion(path: string, api: string) {
  const accountInfo = await get()
  let requestPath = path
  if (!requestPath) {
    requestPath = accountInfo.path
  }
  const session = rcp.createSession()
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
        return res.data[api].maxVersion as number
      }
      const errCodeMap: Record<number, string> = {
        100: '未知错误',
        101: '请求的参数不存在 API、方法或版本',
        102: '请求的 API 不存在',
        103: '请求的方法不存在',
        104: '请求的版本不支持此功能',
        105: '会话无权限',
        106: '会话超时',
        107: '会话因重复登录而中断',
        108: '无法上传文件',
        109: '网络连接不稳定或系统繁忙',
        110: '网络连接不稳定或系统繁忙',
        111: '网络连接不稳定或系统繁忙',
        114: '此 API 的参数丢失',
        115: '不允许上传文件',
        116: '不允许为演示站点执行',
        117: '网络连接不稳定或系统繁忙',
        118: '网络连接不稳定或系统繁忙',
        119: '会话无效',
        150: '请求源 IP 与登录 IP 不匹配',
        400: '账号不存在或密码错误',
        401: '账号被停用',
        402: '权限被拒绝',
        403: '需要二次验证',
        404: '二次验证失败',
        406: '强制要求二次验证',
        407: '请求源 IP 被封锁',
        408: '不允许修改已过期的密码',
        409: '密码已过期',
        410: '需要修改密码'
      }
      const errCode = res.error?.code
      if (!errCodeMap[errCode]) {
        promptAction.openToast({
          message: '接口调用失败，错误码：' + errCode
        })
      }
      if (errCodeMap[errCode]) {
        promptAction.openToast({
          message: '接口调用失败，错误码：' + errCode + '，错误信息：' + errCodeMap[errCode]
        })
      }
      return 'fail'
    }
    promptAction.openToast({
      message: '请求失败，错误码：' + response.statusCode
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

export async function dsmRequest(path: string, api: string, params: string): Promise<string | object> {
  const accountInfo = await get()
  let requestPath = path
  if (!requestPath) {
    requestPath = accountInfo.path
  }
  const version = await getDsmApiMaxVersion(path, api)
  if (version !== 'fail') {
    const session = rcp.createSession({
      cookies: {
        id: accountInfo.sid,
        did: accountInfo.did
      }
    })
    try {
      const response = await session.get(requestPath + '/webapi/entry.cgi?api=' + api + '&version=' + version + params)
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
        if (res.error?.code === 106 || res.error?.code === 107) {
          netBoost.setSceneDesc({
            scene: 'login',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
          })
          const loginres = await dsmRequest(accountInfo.path, 'SYNO.API.Auth',
            '&method=login&account=' + accountInfo.name + '&passwd=' + accountInfo.password)
          netBoost.setSceneDesc({
            scene: 'login',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
          })
          if (loginres !== 'fail') {
            const data = loginres as ResponseData
            await set({
              path: accountInfo.path,
              name: data.account,
              password: accountInfo.password,
              sid: data.sid,
              did: data.device_id
            })
            const resa = await dsmRequest(path, api, params)
            return resa
          }
          promptAction.openToast({
            message: '登录态失效，请重新登录'
          })
          return 'fail'
        }
        const errCodeMap: Record<number, string> = {
          100: '未知错误',
          101: '请求的参数不存在 API、方法或版本',
          102: '请求的 API 不存在',
          103: '请求的方法不存在',
          104: '请求的版本不支持此功能',
          105: '会话无权限',
          106: '会话超时',
          107: '会话因重复登录而中断',
          108: '无法上传文件',
          109: '网络连接不稳定或系统繁忙',
          110: '网络连接不稳定或系统繁忙',
          111: '网络连接不稳定或系统繁忙',
          114: '此 API 的参数丢失',
          115: '不允许上传文件',
          116: '不允许为演示站点执行',
          117: '网络连接不稳定或系统繁忙',
          118: '网络连接不稳定或系统繁忙',
          119: '会话无效',
          150: '请求源 IP 与登录 IP 不匹配',
          400: '账号不存在或密码错误',
          401: '账号被停用',
          402: '权限被拒绝',
          403: '需要二次验证',
          404: '二次验证失败',
          406: '强制要求二次验证',
          407: '请求源 IP 被封锁',
          408: '不允许修改已过期的密码',
          409: '密码已过期',
          410: '需要修改密码'
        }
        const errCode = res.error?.code
        if (!errCodeMap[errCode]) {
          promptAction.openToast({
            message: '接口调用失败，错误码：' + errCode
          })
        }
        if (errCodeMap[errCode]) {
          promptAction.openToast({
            message: '接口调用失败，错误码：' + errCode + '，错误信息：' + errCodeMap[errCode]
          })
        }
        return 'fail'
      }
      promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
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
  return 'fail'
}

export async function developerRequest(path: string, body: rcp.RequestContent) {
  const context = getContext()
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
  const session = rcp.createSession()
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
      message: '请求失败，错误码：' + response.statusCode
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