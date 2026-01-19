import { buffer, util } from '@kit.ArkTS'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'

export default function sha256hash(data: string) {
  const md = cryptoFramework.createMd('SHA256')
  md.updateSync({
    data: new Uint8Array(buffer.from(data).buffer)
  })
  return new util.Base64Helper().encodeToStringSync(md.digestSync().data, util.Type.BASIC_URL_SAFE)
}