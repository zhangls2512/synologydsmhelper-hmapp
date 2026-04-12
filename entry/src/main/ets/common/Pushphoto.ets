import { url } from '@kit.ArkTS'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { AccountInfo, getAccountHash } from './Account'
import { getDnsServer } from './Dnsserver'
import { sha256hash } from './Hash'
import { getFlushPreference } from './Preference'
import { PhotoItem, PhotoThumbnail } from '../pages/Album'

@Concurrent
export async function pushPhotoIntoPhotoArray(context: Context, accountInfo: AccountInfo, photoItem: PhotoItem,
  thumbnail: PhotoThumbnail) {
  if (photoItem.type === 'photo') {
    const inPhotoItem = photoItem
    const dir = getAccountHash(accountInfo, context, context.cacheDir + '/albumphotothumbnail')
    let thumbnailPath = dir + '/' + sha256hash(inPhotoItem.path) + '.jpg'
    const thumbnailPathExist = fileIo.accessSync(thumbnailPath)
    if (!thumbnailPathExist) {
      if (!fileIo.accessSync(dir)) {
        await fileIo.mkdir(dir, true)
      }
      if (photoItem.filename.endsWith('.mv.png')) {
        thumbnailPath = dir + '/' + sha256hash(inPhotoItem.path) + '.zip'
      }
      inPhotoItem.thumbnailUri = fileUri.getUriFromPath(thumbnailPath)
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
        let requestPath = inPhotoItem.url
        if (thumbnail.sm === 'ready') {
          requestPath = accountInfo.path + '/synofoto/api/v2/p/Thumbnail/get?' + new url.URLParams({
            id: String(inPhotoItem.id),
            cache_key: thumbnail.cache_key,
            type: 'unit',
            size: 'sm',
            SynoToken: accountInfo.synotoken
          }).toString()
        }
        await session.get(requestPath)
      } catch {
      }
    }
    if (thumbnailPathExist) {
      if (!photoItem.filename.endsWith('.mv.png')) {
        inPhotoItem.thumbnailUri = fileUri.getUriFromPath(thumbnailPath)
      }
      if (photoItem.filename.endsWith('.mv.png')) {
        const imageUri = fileUri.getUriFromPath(dir + '/' + sha256hash(inPhotoItem.path) + '.jpg')
        const videoUri = fileUri.getUriFromPath(dir + '/' + sha256hash(inPhotoItem.path) + '.mp4')
        inPhotoItem.type = 'movingphoto'
        inPhotoItem.movingPhotoImageUri = imageUri
        inPhotoItem.movingPhotoVideoUri = videoUri
        inPhotoItem.movingPhoto = await photoAccessHelper.MediaAssetManager.loadMovingPhoto(context, imageUri, videoUri)
      }
    }
    return inPhotoItem
  } else {
    return photoItem
  }
}