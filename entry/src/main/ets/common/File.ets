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