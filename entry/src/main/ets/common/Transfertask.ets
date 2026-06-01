import { sendablePreferences } from '@kit.ArkData'
import { url } from '@kit.ArkTS'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { fileIo } from '@kit.CoreFileKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { deleteBackupTask, updateBackupTaskStatus } from './Backup'
import { getDnsServer } from './Dnsserver'
import { write } from './File'
import { getFlushPreference } from './Preference'
import { DsmResponse, getDsmApiMaxVersion } from './Request'
import { addFilePathIndex } from './Stringformat'
import { TransferTaskItem } from '../pages/Index'

@Concurrent
export async function download(context: Context, id: string) {
  const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(context, {
    name: 'transferTask'
  })
  const transferTaskString = transferTaskDataPreferences.getSync(id, '{}') as string
  const transferTask = JSON.parse(transferTaskString) as TransferTaskItem
  transferTask.status = 'processing'
  transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
  let filePath = transferTask.destDownloadPath
  if (getFlushPreference(context, 'commonSetting', 'operationWhenDownloadConflict', 0) === 0) {
    let index = 0
    let fileExist = fileIo.accessSync(filePath)
    while (fileExist) {
      index++
      filePath = addFilePathIndex(transferTask.destDownloadPath, index)
      fileExist = fileIo.accessSync(filePath)
    }
  }
  try {
    const version = await getDsmApiMaxVersion(context, transferTask.accountInfo.path, 'SYNO.FileStation.Download')
    if (version !== 'fail') {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      const fileStream = fileIo.fdopenStreamSync(file.fd, 'w+')
      netBoost.setSceneDesc({
        scene: 'download',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
      })
      let lastUpdateTime = 0
      let lastTransferredSize = 0
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
                const continuousTasks = await backgroundTaskManager.getAllContinuousTasks(context)
                if (continuousTasks.length === 0) {
                  session.cancel()
                }
                transferTask.transferredSize = transferredSize
                transferTask.totalSize = totalSize
                const currentTime = Date.now()
                if (currentTime - lastUpdateTime >= 1000) {
                  transferTask.speed = transferredSize - lastTransferredSize
                  lastUpdateTime = currentTime
                  lastTransferredSize = transferredSize
                }
                transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
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
          referer: transferTask.path,
          'x-syno-token': transferTask.accountInfo.synotoken
        },
        cookies: {
          id: transferTask.accountInfo.sid
        }
      })
      try {
        const response = await session.get(transferTask.accountInfo.path + '/webapi/entry.cgi?' + new url.URLParams({
          api: 'SYNO.FileStation.Download',
          version: String(version),
          method: 'download',
          path: transferTask.path,
          mode: 'download'
        }).toString())
        if (response.statusCode >= 200 && response.statusCode < 300) {
          transferTask.status = 'success'
        } else {
          transferTask.status = 'fail'
          transferTask.errCode = response.statusCode
        }
      } catch (err) {
        session.close()
        netBoost.setSceneDesc({
          scene: 'download',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        fileStream.closeSync()
        if (err.code !== 1007900992) {
          transferTask.status = 'fail'
          transferTask.errCode = err.code
        }
        if (err.code === 1007900992) {
          transferTask.status = 'cancel'
        }
      }
    } else {
      transferTask.status = 'fail'
      transferTask.errCode = -1
    }
  } catch (err) {
    transferTask.status = 'fail'
    transferTask.errCode = err.code
  }
  transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
}

@Concurrent
export async function upload(context: Context, id: string) {
  const transferTaskDataPreferences = sendablePreferences.getPreferencesSync(context, {
    name: 'transferTask'
  })
  const transferTaskString = transferTaskDataPreferences.getSync(id, '{}') as string
  const transferTask = JSON.parse(transferTaskString) as TransferTaskItem
  transferTask.status = 'processing'
  transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
  try {
    const version = await getDsmApiMaxVersion(context, transferTask.accountInfo.path, 'SYNO.FileStation.Upload')
    if (version !== 'fail') {
      const filePath = context.tempDir + '/upload/' + transferTask.id
      let header =
        '--' + transferTask.id + '\r\ncontent-disposition: form-data; name="api"\r\n\r\nSYNO.FileStation.Upload\r\n'
      header += '--' + transferTask.id + '\r\ncontent-disposition: form-data; name="version"\r\n\r\n' + version + '\r\n'
      header += '--' + transferTask.id + '\r\ncontent-disposition: form-data; name="method"\r\n\r\nupload\r\n'
      header += '--' + transferTask.id + '\r\ncontent-disposition: form-data; name="path"\r\n\r\n' + transferTask.path +
        '\r\n'
      header += '--' + transferTask.id + '\r\ncontent-disposition: form-data; name="create_parents"\r\n\r\ntrue\r\n'
      header += '--' + transferTask.id + '\r\ncontent-disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n'
      header += '--' + transferTask.id + '\r\ncontent-disposition: form-data; name="file"; filename="' +
        transferTask.name + '"\r\n\r\n'
      await write(filePath, header)
      const srcFile = fileIo.openSync(transferTask.srcFileUri)
      const inStream = fileIo.fdopenStreamSync(srcFile.fd, 'r')
      const outStream = fileIo.createStreamSync(filePath, 'a')
      let offset = 0
      let read = 0
      let size = 1048576
      if (transferTask.totalSize < size) {
        size = transferTask.totalSize
      }
      const buf = new ArrayBuffer(size)
      read = await inStream.read(buf, {
        offset: offset
      })
      while (read > 0) {
        await outStream.write(buf)
        offset += read
        read = await inStream.read(buf, {
          offset: offset
        })
      }
      inStream.closeSync()
      outStream.closeSync()
      const file = fileIo.openSync(filePath, fileIo.OpenMode.WRITE_ONLY)
      await fileIo.write(file.fd, '\r\n\r\n--' + transferTask.id + '--', {
        offset: fileIo.statSync(filePath).size
      })
      netBoost.setSceneDesc({
        scene: 'upload',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
      })
      let lastUpdateTime = 0
      let lastTransferredSize = 0
      const session = rcp.createSession({
        requestConfiguration: {
          transfer: {
            timeout: {
              transferMs: 0
            }
          },
          tracing: {
            httpEventsHandler: {
              onUploadProgress: (totalSize, transferredSize) => {
                transferTask.transferredSize = transferredSize
                transferTask.totalSize = totalSize
                const currentTime = Date.now()
                if (currentTime - lastUpdateTime >= 1000) {
                  transferTask.speed = transferredSize - lastTransferredSize
                  lastUpdateTime = currentTime
                  lastTransferredSize = transferredSize
                }
                transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
              },
              onDataEnd: async () => {
                session.close()
                netBoost.setSceneDesc({
                  scene: 'upload',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                })
                await fileIo.unlink(filePath)
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
          'content-type': 'multipart/form-data; boundary=' + transferTask.id,
          'content-length': String(fileIo.statSync(filePath).size),
          referer: transferTask.path,
          'x-syno-token': transferTask.accountInfo.synotoken
        },
        cookies: {
          id: transferTask.accountInfo.sid
        }
      })
      const intervalId = setInterval(async () => {
        const continuousTasks = await backgroundTaskManager.getAllContinuousTasks(context)
        if (continuousTasks.length === 0) {
          session.cancel()
        }
      }, 1000)
      try {
        const response = await session.uploadFromFile(transferTask.accountInfo.path +
          '/webapi/entry.cgi?api=SYNO.FileStation.Upload&version=' + version + '&method=upload&SynoToken=' +
          transferTask.accountInfo.synotoken, new rcp.UploadFromFile(filePath))
        clearInterval(intervalId)
        if (response.statusCode >= 200 && response.statusCode < 300) {
          const res = response.toJSON() as DsmResponse
          if (!res.success) {
            transferTask.status = 'fail'
            transferTask.errCode = res.error.code
            if (transferTask.backupTaskId) {
              await updateBackupTaskStatus(context, transferTask.accountInfo, transferTask.backupTaskId, false)
            }
          }
          if (res.success) {
            transferTask.status = 'success'
            if (transferTask.backupTaskId) {
              await updateBackupTaskStatus(context, transferTask.accountInfo, transferTask.backupTaskId, true)
              const deleteAfterSuccess = getFlushPreference(context, 'backupSetting', 'deleteAfterSuccess', true)
              if (deleteAfterSuccess) {
                await deleteBackupTask(context, transferTask.accountInfo, transferTask.backupTaskId)
              }
            }
          }
        } else {
          transferTask.status = 'fail'
          transferTask.errCode = response.statusCode
          if (transferTask.backupTaskId) {
            await updateBackupTaskStatus(context, transferTask.accountInfo, transferTask.backupTaskId, false)
          }
        }
      } catch (err) {
        clearInterval(intervalId)
        session.close()
        netBoost.setSceneDesc({
          scene: 'upload',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (err.code !== 1007900992) {
          transferTask.status = 'fail'
          transferTask.errCode = err.code ?? err.message
          if (transferTask.backupTaskId) {
            await updateBackupTaskStatus(context, transferTask.accountInfo, transferTask.backupTaskId, false)
          }
        }
        if (err.code === 1007900992) {
          transferTask.status = 'cancel'
          if (transferTask.backupTaskId) {
            await updateBackupTaskStatus(context, transferTask.accountInfo, transferTask.backupTaskId, false)
          }
        }
      }
    } else {
      transferTask.status = 'fail'
      transferTask.errCode = -1
      if (transferTask.backupTaskId) {
        await updateBackupTaskStatus(context, transferTask.accountInfo, transferTask.backupTaskId, false)
      }
    }
  } catch (err) {
    transferTask.status = 'fail'
    transferTask.errCode = err.code
    if (transferTask.backupTaskId) {
      await updateBackupTaskStatus(context, transferTask.accountInfo, transferTask.backupTaskId, false)
    }
  }
  transferTaskDataPreferences.putSync(id, JSON.stringify(transferTask))
}