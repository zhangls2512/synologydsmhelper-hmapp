import { url, util } from '@kit.ArkTS'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { AccountInfo, getAccountHash } from './Account'
import { getDnsServer } from './Dnsserver'
import { getFileTypeIcon } from './File'
import { sha256hash } from './Hash'
import { getFlushPreference } from './Preference'

@Concurrent
export async function getFileThumbnail(context: Context, path: string, accountInfo: AccountInfo,
  apiVersion: number): Promise<string | Resource> {
  const dir = getAccountHash(accountInfo, context, context.cacheDir + '/filethumbnail')
  const thumbnailPath = dir + '/' + sha256hash(path) + '.png'
  const thumbnailPathExist = fileIo.accessSync(thumbnailPath)
  if (!thumbnailPathExist) {
    if (!fileIo.accessSync(dir)) {
      await fileIo.mkdir(dir, true)
    }
    const file = fileIo.openSync(thumbnailPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
    const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
    netBoost.setSceneDesc({
      scene: 'download',
      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
    })
    const session = rcp.createSession({
      requestConfiguration: {
        tracing: {
          httpEventsHandler: {
            onDataReceive: async (incomingData) => {
              await fileStream.write(incomingData)
            },
            onDataEnd: () => {
              session.close()
              netBoost.setSceneDesc({
                scene: 'download',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
              })
              fileStream.closeSync()
            }
          }
        },
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
      },
      headers: {
        referer: accountInfo.path,
        'x-syno-token': accountInfo.synotoken
      },
      cookies: {
        id: accountInfo.sid
      }
    })
    try {
      await session.get(accountInfo.path + '/webapi/entry.cgi?' + new url.URLParams({
        api: 'SYNO.FileStation.Thumb',
        version: String(apiVersion),
        method: 'get',
        path: path
      }).toString())
    } catch {
      session.close()
      netBoost.setSceneDesc({
        scene: 'download',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
      })
      fileStream.closeSync()
    }
    const fileb = fileIo.openSync(thumbnailPath)
    const filebuffer = new ArrayBuffer(15)
    fileIo.readSync(fileb.fd, filebuffer)
    fileIo.closeSync(fileb)
    const decoder = util.TextDecoder.create()
    const fileHead = decoder.decodeToString(new Uint8Array(filebuffer))
    if (fileHead === '<!DOCTYPE html>') {
      await fileIo.unlink(thumbnailPath)
      const file = fileIo.openSync(thumbnailPath, fileIo.OpenMode.CREATE)
      fileIo.closeSync(file)
    }
  }
  if (fileIo.statSync(thumbnailPath).size === 0) {
    return getFileTypeIcon(path)
  }
  return fileUri.getUriFromPath(thumbnailPath)
}