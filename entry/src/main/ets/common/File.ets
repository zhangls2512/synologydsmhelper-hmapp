import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'

export async function read(path: string, ignoreNotexist = false) {
  try {
    const filestring = await fileIo.readText(path)
    return filestring
  } catch (err) {
    if (err.code !== 13900002) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
    if (err.code === 13900002 && !ignoreNotexist) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
    return 'fail'
  }
}

export async function readUri(uri: string) {
  try {
    const file = fileIo.openSync(uri)
    const size = fileIo.statSync(file.fd).size
    const filebuffer = new ArrayBuffer(size)
    await fileIo.read(file.fd, filebuffer)
    fileIo.closeSync(file)
    const decoder = util.TextDecoder.create()
    return decoder.decodeToString(new Uint8Array(filebuffer))
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}

export async function write(path: string, content: string) {
  try {
    const lastSlashIndex = path.lastIndexOf('/')
    const dir = path.substring(0, lastSlashIndex)
    if (!fileIo.accessSync(dir)) {
      await fileIo.mkdir(dir, true)
    }
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC)
    await fileIo.write(file.fd, content)
    fileIo.closeSync(file)
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function writeUri(uri: string, content: string) {
  try {
    const file = fileIo.openSync(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC)
    await fileIo.write(file.fd, content)
    fileIo.closeSync(file)
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function getDirectorySize(path: string) {
  let totalSize = 0
  try {
    const fileNames = await fileIo.listFile(path, {
      recursion: true
    })
    fileNames.forEach(item => {
      const fileStat = fileIo.statSync(path + item)
      if (!fileStat.isDirectory()) {
        totalSize += fileStat.size
      }
    })
  } catch {
  }
  return totalSize
}