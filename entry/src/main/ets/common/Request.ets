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

export async function getDsmApiMaxVersion(path: string, api: string) {
  const accountInfo = await get()
  let requestPath = path
  if (!requestPath) {
    requestPath = accountInfo.path
  }
  const session = rcp.createSession({
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
        return res.data[api].maxVersion as number
      }
      promptAction.openToast({
        message: '接口调用失败，错误码：' + res.error?.code
      })
      return 'fail'
    }
    promptAction.openToast({
      message: 'DSM 请求失败，错误码：' + response.statusCode
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

export async function dsmRequest(path: string, api: string, params: string): Promise<string | object> {
  const accountInfo = await get()
  let requestPath = path
  if (!requestPath) {
    requestPath = accountInfo.path
  }
  const version = await getDsmApiMaxVersion(path, api)
  if (version !== 'fail') {
    const session = rcp.createSession({
      headers: {
        referer: requestPath
      },
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
        if (res.error?.code === 106 || res.error?.code === 107 || res.error?.code === 119) {
          netBoost.setSceneDesc({
            scene: 'login',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
          })
          const loginres = await dsmRequest(accountInfo.path, 'SYNO.API.Auth',
            '&method=login&account=' + encodeURIComponent(accountInfo.name) + '&passwd=' +
            encodeURIComponent(accountInfo.password))
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
            return await dsmRequest(path, api, params)
          }
          promptAction.openToast({
            message: '登录态失效，请重新登录'
          })
          return 'fail'
        }
        promptAction.openToast({
          message: '接口调用失败，错误码：' + res.error?.code
        })
        return 'fail'
      }
      promptAction.openToast({
        message: 'DSM 请求失败，错误码：' + response.statusCode
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