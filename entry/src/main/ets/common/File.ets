import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'

export function read(path: string) {
  try {
    const file = fileIo.openSync(path)
    const size = fileIo.statSync(file.fd).size
    const filebuffer = new ArrayBuffer(size)
    fileIo.readSync(file.fd, filebuffer)
    const decoder = util.TextDecoder.create()
    const filestring = decoder.decodeToString(new Uint8Array(filebuffer))
    fileIo.closeSync(file)
    return filestring
  } catch (err) {
    promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}

export function write(path: string, content: string) {
  try {
    const lastSlashIndex = path.lastIndexOf('/')
    const dir = path.substring(0, lastSlashIndex)
    if (!fileIo.accessSync(dir)) {
      fileIo.mkdirSync(dir, true)
    }
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
    fileIo.writeSync(file.fd, content)
    fileIo.closeSync(file)
  } catch (err) {
    promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}