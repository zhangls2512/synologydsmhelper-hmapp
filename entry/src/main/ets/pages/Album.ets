import { common } from '@kit.AbilityKit'
import { display, LoadingDialog, promptAction, SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI'
import { get, getLoginStatus } from '../common/Account'
import { getPreferType, getPreferTypeByDisplayId } from '../common/Prefertype'
import { util } from '@kit.ArkTS'
import { dsmRequest } from '../common/Request'

interface FolderItem {
  id: number,
  path: string
}

interface PhotoItem {
  id: number,
  filename: string,
  filesize: number,
  time: number,
  folder_id: number,
  url: string
}

interface PhotoResItem {
  id: number,
  filename: string,
  filesize: number,
  time: number,
  folder_id: number
}

interface AlbumItem {
  id: number,
  item_count: number,
  name: string
}

@ComponentV2
export default struct Album {
  @Local preferType: number = 1
  @Local selectedIndex: number = 0
  @Local loading: boolean = false
  @Local photoArray: PhotoItem[] = []
  @Local albumArray: AlbumItem[] = []
  @Local isLogin: boolean = false
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '加载中...'
    })
  })

  async get() {
    this.isLogin = await getLoginStatus()
    if (this.isLogin) {
      this.dialogControllerProgress.open()
      const albumres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Album',
        '&method=list&offset=0&limit=5000&additional=["thumbnail"]')
      this.dialogControllerProgress.close()
      if (albumres !== 'fail') {
        this.albumArray = albumres['list']
      }
      this.dialogControllerProgress.open()
      const res = await dsmRequest(this.context, this.UIContext, '', 'SYNO.API.Auth.Key',
        '&method=grant&allow_api=SYNO.FileStation.Download&allow_methods=["download"]')
      this.dialogControllerProgress.close()
      if (res !== 'fail') {
        const tid = res['tid'] as string
        const accountInfo = await get()
        const textEncoder = new util.TextEncoder()
        this.dialogControllerProgress.open()
        const photores = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Item',
          '&method=list&offset=0&limit=5000')
        this.dialogControllerProgress.close()
        if (photores !== 'fail') {
          const photos = photores['list'] as PhotoResItem[]
          const photoArray: PhotoItem[] = []
          const folderArray: FolderItem[] = []
          this.dialogControllerProgress.open()
          for (let i = 0; i < photos.length; i++) {
            const item = photos[i]
            const folderIndex = folderArray.findIndex(itema => itema.id === item.folder_id)
            if (folderIndex !== -1) {
              photoArray.push({
                id: item.id,
                filename: item.filename,
                filesize: item.filesize,
                time: item.time,
                folder_id: item.folder_id,
                url: accountInfo.path + '/fbdownload/' + item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') +
                  '?tid=' + tid + '&mode=open&dlink=' +
                Array.from(textEncoder.encodeInto(folderArray[folderIndex].path))
                  .map(byte => byte.toString(16).padStart(2, '0')).join('')
              })
            }
            if (folderIndex === -1) {
              const folderres = await dsmRequest(this.context, this.UIContext, '', 'SYNO.Foto.Browse.Folder',
                '&method=get&id=' + item.folder_id)
              if (folderres !== 'fail') {
                const folderPath = folderres['folder']['name'] as string
                const path = '/home/Photos' + folderPath + '/' + item.filename
                folderArray.push({
                  id: item.folder_id,
                  path: path
                })
                photoArray.push({
                  id: item.id,
                  filename: item.filename,
                  filesize: item.filesize,
                  time: item.time,
                  folder_id: item.folder_id,
                  url: accountInfo.path + '/fbdownload/' + item.filename.replace(/[\/\\\:\?\>\<\*\"\;\|\#\%]/g, '-') +
                    '?tid=' + tid + '&mode=open&dlink=' +
                  Array.from(textEncoder.encodeInto(path)).map(byte => byte.toString(16).padStart(2, '0')).join('')
                })
              }
            }
          }
          this.dialogControllerProgress.close()
          this.photoArray = photoArray
        }
      }
    }
  }

  build() {
    Scroll() {
      Column() {
        if (!this.isLogin) {
          Text('未登录账号')
            .height('100%')
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        if (this.isLogin) {
          TabSegmentButtonV2({
            items: new SegmentButtonV2Items([
              { text: '照片' },
              { text: '相册' }
            ]),
            selectedIndex: this.selectedIndex!!
          })
            .margin({
              bottom: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          Refresh({
            refreshing: $$this.loading
          }) {
            List() {
              if (this.selectedIndex === 0) {
                ListItem() {
                  Flex() {
                    ForEach(this.photoArray, (item: PhotoItem) => {
                      Image(item.url)
                        .aspectRatio(1)
                        .copyOption(CopyOptions.LocalDevice)
                        .enableAnalyzer(true)
                        .width('25%')
                    })
                  }
                }
              }
              if (this.selectedIndex === 1) {
                ListItem() {
                  Column() {
                    ForEach(this.albumArray, (item: AlbumItem, index) => {
                      if (index !== 0) {
                        Divider()
                          .padding({
                            left: 12,
                            right: 12
                          })
                      }
                      Row() {
                        Text(item.name)
                          .fontWeight(FontWeight.Medium)
                          .layoutWeight(1)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                        Text(String(item.item_count))
                          .fontColor($r('sys.color.font_secondary'))
                          .fontSize($r('sys.float.ohos_id_text_size_body2'))
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                          })
                        Image($r('app.media.right'))
                          .fillColor($r('sys.color.icon_fourth'))
                          .height(12)
                          .width(12)
                      }
                      .borderRadius(12)
                      .padding(12)
                      .stateStyles({
                        normal: {
                          .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                            $r('sys.color.ohos_id_color_card_bg'))
                        },
                        pressed: {
                          .backgroundColor($r('sys.color.interactive_pressed'))
                        }
                      })
                      .width('100%')
                      .onHover((isHover) => {
                        if (!isHover) {
                          this.hoverId = -1
                        }
                        if (isHover) {
                          this.hoverId = index
                        }
                      })
                      .onClick(() => {
                        promptAction.openToast({
                          message: '暂未上线，敬请期待'
                        })
                      })
                    })
                  }
                  .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .padding($r('sys.float.ohos_id_corner_radius_mark'))
                }
              }
            }
          }
          .layoutWeight(1)
          .onRefreshing(async () => {
            await this.get()
            this.loading = false
          })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .height('100%')
    }
    .padding({
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(() => {
      this.preferType = getPreferType()
      display.on('change', (displayId) => {
        this.preferType = getPreferTypeByDisplayId(displayId)
      })
      this.context.eventHub.on('refreshAlbum', () => {
        this.get()
      })
      this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshAlbum')
      display.off('change')
    })
  }
}