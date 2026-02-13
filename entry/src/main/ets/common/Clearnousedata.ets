import { preferences } from '@kit.ArkData'
import { fileIo } from '@kit.CoreFileKit'

export async function clearNouseData(context: Context) {
  const tempDir = context.tempDir
  const tempFiles = await fileIo.listFile(tempDir)
  const promises = tempFiles.map(async (item) => {
    const path = tempDir + '/' + item
    const isDirectory = fileIo.statSync(path)
    if (!isDirectory) {
      await fileIo.unlink(path)
    }
    if (isDirectory) {
      await fileIo.rmdir(path)
    }
  })
  await Promise.all(promises)
  const commonSettingDataPreferences = preferences.getPreferencesSync(context, {
    name: 'commonSetting'
  })
  const commonKeys = ['disallowScreenshot', 'cellularDataDownloadRemind']
  commonKeys.forEach(item => {
    commonSettingDataPreferences.deleteSync(item)
  })
}