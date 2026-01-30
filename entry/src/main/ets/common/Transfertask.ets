import { wantAgent } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { deviceInfo } from '@kit.BasicServicesKit'
import { Environment, fileIo, fileUri, picker } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { notificationManager } from '@kit.NotificationKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getDnsServer } from './Dnsserver'
import { write } from './File'
import { getPermission } from './Permission'
import { DsmResponse, getDsmApiMaxVersion } from './Request'
import { getSizeString } from './Stringformat'
import { TransferTaskItem } from '../pages/Index'

@Concurrent
export async function download(context: Context, id: string) {
  const transferTaskDataPreferences = preferences.getPreferencesSync(context, {
    name: 'transferTask'
  })
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const transferTaskString = transferTaskDataPreferences.getSync(id, '{}') as string
  const transferTask = JSON.parse(transferTaskString) as TransferTaskItem
  transferTask.status = 'processing'
  transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
  try {
    let filePath = ''
    const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
      name: 'commonSetting'
    })
    const downloadDirectory = commonSettingDataPreferences.getSync('downloadDirectory', 0)
    if (downloadDirectory === 1 && getPermission('ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY') &&
      deviceInfo.deviceType !== 'phone') {
      filePath = Environment.getUserDownloadDir() + '/' + transferTask.name
    } else {
      const documentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD
      const documentViewPicker = new picker.DocumentViewPicker(context)
      const uris = await documentViewPicker.save(documentSaveOptions)
      if (uris.length === 1) {
        filePath = new fileUri.FileUri(uris[0] + '/' + transferTask.name).path
      }
    }
    const version = await getDsmApiMaxVersion(context, transferTask.accountPath, 'SYNO.FileStation.Download')
    if (version !== 'fail') {
      const wandAgent = await wantAgent.getWantAgent({
        wants: [
          {
            bundleName: 'com.songjy.synologydsmhelper',
            abilityName: 'EntryAbility'
          }
        ],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      })
      const continuousTaskNotificationInfo =
        await backgroundTaskManager.startBackgroundRunning(context, ['dataTransfer'], wandAgent)
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
      netBoost.setSceneDesc({
        scene: 'download',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
      })
      const session = rcp.createSession({
        requestConfiguration: {
          transfer: {
            timeout: {
              transferMs: 0
            }
          },
          tracing: {
            httpEventsHandler: {
              onDataReceive: async (incomingData) => {
                await fileStream.write(incomingData)
              },
              onDownloadProgress: async (totalSize, transferredSize) => {
                transferTask.transferredSize = transferredSize
                transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
                try {
                  await notificationManager.publish({
                    content: {
                      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                      systemLiveView: {
                        typeCode: 8,
                        title: '正在下载文件：' + transferTask.name,
                        text: '进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 + '% (' +
                        getSizeString(transferredSize) + '/' + getSizeString(totalSize) + ')'
                      }
                    },
                    id: continuousTaskNotificationInfo.notificationId,
                    notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                    template: {
                      name: 'downloadTemplate',
                      data: {
                        title: '正在下载文件，进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 + '%',
                        fileName: transferTask.name,
                        progressValue: Number((transferredSize / totalSize).toFixed(2)) * 100
                      }
                    }
                  })
                } catch {
                }
              },
              onDataEnd: async () => {
                session.close()
                netBoost.setSceneDesc({
                  scene: 'download',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                })
                fileStream.closeSync()
                await backgroundTaskManager.stopBackgroundRunning(context)
                transferTask.status = 'success'
                transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
              }
            }
          },
          dns: {
            dnsRules: getDnsServer(context)
          },
          security: {
            remoteValidation: debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
              'system') as 'system' | 'skip'
          }
        },
        headers: {
          referer: transferTask.path
        },
        cookies: {
          id: transferTask.accountSid,
          'x-syno-token': transferTask.accountSynotoken
        }
      })
      backgroundTaskManager.on('continuousTaskCancel', () => {
        session.cancel()
      })
      try {
        const response = await session.get(transferTask.accountPath + '/webapi/entry.cgi?' + new url.URLParams({
          api: 'SYNO.FileStation.Download',
          version: String(version),
          method: 'download',
          path: transferTask.path,
          mode: 'download'
        }).toString())
        if (response.statusCode !== 200) {
          session.close()
          netBoost.setSceneDesc({
            scene: 'download',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
          })
          fileStream.closeSync()
          await backgroundTaskManager.stopBackgroundRunning(context)
          transferTask.status = 'fail'
          transferTask.errCode = response.statusCode
          transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
        }
      } catch (err) {
        session.close()
        netBoost.setSceneDesc({
          scene: 'download',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        fileStream.closeSync()
        if (err.code !== 1007900992) {
          await backgroundTaskManager.stopBackgroundRunning(context)
          transferTask.status = 'fail'
          transferTask.errCode = err.code
          transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
        }
        if (err.code === 1007900992) {
          transferTask.status = 'cancel'
          transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
        }
      }
    } else {
      transferTask.status = 'fail'
      transferTask.errCode = -1
      transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
    }
  } catch (err) {
    transferTask.status = 'fail'
    transferTask.errCode = err.code
    transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
  }
}

@Concurrent
export async function upload(context: Context, id: string) {
  const transferTaskDataPreferences = preferences.getPreferencesSync(context, {
    name: 'transferTask'
  })
  const debugSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'debugSetting'
  })
  const transferTaskString = transferTaskDataPreferences.getSync(id, '{}') as string
  const transferTask = JSON.parse(transferTaskString) as TransferTaskItem
  transferTask.status = 'processing'
  transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
  try {
    const version = await getDsmApiMaxVersion(context, transferTask.accountPath, 'SYNO.FileStation.Download')
    if (version !== 'fail') {
      const wandAgent = await wantAgent.getWantAgent({
        wants: [
          {
            bundleName: 'com.songjy.synologydsmhelper',
            abilityName: 'EntryAbility'
          }
        ],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      })
      const continuousTaskNotificationInfo =
        await backgroundTaskManager.startBackgroundRunning(context, ['dataTransfer'], wandAgent)
      netBoost.setSceneDesc({
        scene: 'upload',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
      })
      const session = rcp.createSession({
        requestConfiguration: {
          transfer: {
            timeout: {
              transferMs: 0
            }
          },
          tracing: {
            httpEventsHandler: {
              onUploadProgress: async (totalSize, transferredSize) => {
                transferTask.transferredSize = transferredSize
                transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
                try {
                  await notificationManager.publish({
                    content: {
                      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
                      systemLiveView: {
                        typeCode: 8,
                        title: '正在上传文件：' + transferTask.name,
                        text: '进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 + '% (' +
                        getSizeString(transferredSize) + '/' + getSizeString(totalSize) + ')'
                      }
                    },
                    id: continuousTaskNotificationInfo.notificationId,
                    notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
                    template: {
                      name: 'downloadTemplate',
                      data: {
                        title: '正在上传文件，进度：' + Number((transferredSize / totalSize).toFixed(2)) * 100 + '%',
                        fileName: transferTask.name,
                        progressValue: Number((transferredSize / totalSize).toFixed(2)) * 100
                      }
                    }
                  })
                } catch {
                }
              },
              onDataEnd: async () => {
                session.close()
                netBoost.setSceneDesc({
                  scene: 'upload',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                })
                await backgroundTaskManager.stopBackgroundRunning(context)
              }
            }
          },
          dns: {
            dnsRules: getDnsServer(context)
          },
          security: {
            remoteValidation: debugSettingDataPreferences.getSync('closeRemoteValidationWhenLinkDsm',
              'system') as 'system' | 'skip'
          }
        },
        headers: {
          'content-type': 'multipart/form-data; boundary=AaB03x',
          referer: transferTask.path
        },
        cookies: {
          id: transferTask.accountSid,
          'x-syno-token': transferTask.accountSynotoken
        }
      })
      backgroundTaskManager.on('continuousTaskCancel', () => {
        session.cancel()
      })
      const filePath = context.tempDir + '/upload/' + transferTask.name
      let header =
        '--AaB03x\r\ncontent-disposition: form-data; name="api"\r\n\r\nSYNO.FileStation.Upload\r\n--AaB03x\r\n'
      header += 'content-disposition: form-data; name="version"\r\n\r\n' + version + '\r\n--AaB03x\r\n'
      header += 'content-disposition: form-data; name="path"\r\n\r\n' + transferTask.path + '\r\n--AaB03x\r\n'
      header += 'content-disposition: form-data; name="file"; filename="' + transferTask.name + '"\r\n\r\n'
      await write(filePath, header)
      try {
        const filebuffer = new ArrayBuffer(fileIo.statSync(transferTask.srcFileUri).size)
        const file = fileIo.openSync(transferTask.srcFileUri)
        await fileIo.read(file.fd, filebuffer)
        fileIo.closeSync(file)
        const fileb = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE)
        await fileIo.write(fileb.fd, filebuffer, {
          offset: fileIo.statSync(filePath).size
        })
        await fileIo.write(fileb.fd, '\r\n\r\n--AaB03x--', {
          offset: fileIo.statSync(filePath).size
        })
        const filebufferb = new ArrayBuffer(fileIo.statSync(filePath).size)
        await fileIo.read(fileb.fd, filebufferb)
        fileIo.closeSync(fileb)
        const response = await session.post(transferTask.accountPath + '/webapi/entry.cgi?' + new url.URLParams({
          api: 'SYNO.FileStation.Upload',
          version: String(version),
          method: 'upload',
          SynoToken: transferTask.accountSynotoken
        }).toString(), filebufferb)
        await fileIo.unlink(filePath)
        if (response.statusCode === 200) {
          let body = ''
          if (response.toString()) {
            body = response.toString() as string
          }
          const res = JSON.parse(body) as DsmResponse
          if (!res.success) {
            transferTask.status = 'fail'
            transferTask.errCode = res.error.code
          }
          if (res.success) {
            transferTask.status = 'success'
          }
          transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
        }
        if (response.statusCode !== 200) {
          session.close()
          netBoost.setSceneDesc({
            scene: 'upload',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
          })
          await backgroundTaskManager.stopBackgroundRunning(context)
          transferTask.status = 'fail'
          transferTask.errCode = response.statusCode
          transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
        }
      } catch (err) {
        await fileIo.unlink(filePath)
        session.close()
        netBoost.setSceneDesc({
          scene: 'upload',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (err.code !== 1007900992) {
          await backgroundTaskManager.stopBackgroundRunning(context)
          transferTask.status = 'fail'
          transferTask.errCode = err.code
          transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
        }
        if (err.code === 1007900992) {
          transferTask.status = 'cancel'
          transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
        }
      }
    } else {
      transferTask.status = 'fail'
      transferTask.errCode = -1
      transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
    }
  } catch (err) {
    transferTask.status = 'fail'
    transferTask.errCode = err.code
    transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
  }
}