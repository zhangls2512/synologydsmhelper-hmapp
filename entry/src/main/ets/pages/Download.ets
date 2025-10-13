@ComponentV2
export default struct Download {
  @Consumer() isShowDownloadSheet: boolean = false
  @Consumer() transferredSize: number = -1
  @Consumer() totalSize: number = -1
  @Local oneSecondBeforeTransferredSize: number = 0
  @Local oneSecondTransferredSize: number = 0

  getSizeString(size: number) {
    if (size < Math.pow(1024, 1)) {
      return size + ' B'
    }
    if (size >= Math.pow(1024, 1) && size < Math.pow(1024, 2)) {
      return (size / Math.pow(1024, 1)).toFixed(2) + ' KB'
    }
    if (size >= Math.pow(1024, 2) && size < Math.pow(1024, 3)) {
      return (size / Math.pow(1024, 2)).toFixed(2) + ' MB'
    }
    if (size >= Math.pow(1024, 3) && size < Math.pow(1024, 4)) {
      return (size / Math.pow(1024, 3)).toFixed(2) + ' GB'
    }
    if (size >= Math.pow(1024, 4)) {
      return (size / Math.pow(1024, 4)).toFixed(2) + ' TB'
    }
    return ''
  }

  build() {
    List() {
      ListItem() {
        Row() {
          Progress({
            value: Number((this.transferredSize / this.totalSize).toFixed(2)) * 100,
            total: 100,
            type: ProgressType.Ring
          })
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .width(40)
          Column() {
            Text('进度：' + Number((this.transferredSize / this.totalSize).toFixed(2)) * 100 + '%')
            Text(this.getSizeString(this.transferredSize) + '/' + this.getSizeString(this.totalSize) + ' (' +
            this.getSizeString(this.oneSecondTransferredSize) + '/s)')
              .margin({
                top: $r('sys.float.ohos_id_text_margin_vertical')
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })

      ListItem() {
        Button('取消')
          .role(ButtonRole.ERROR)
          .onClick(async () => {
            const promptAction = this.getUIContext().getPromptAction()
            const data = await promptAction.showDialog({
              title: '提示',
              message: '取消会导致已下载到本地的文件不完整，确定取消？',
              buttons: [
                {
                  text: '取消',
                  color: $r('sys.color.font_primary')
                },
                {
                  text: '确定',
                  color: $r('sys.color.warning')
                }
              ]
            })
            if (data.index === 1) {
              this.isShowDownloadSheet = false
            }
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
      .width('100%')
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_max_padding_start'),
      right: $r('sys.float.ohos_id_max_padding_end')
    })
    .onAppear(() => {
      setInterval(() => {
        this.oneSecondTransferredSize = this.transferredSize - this.oneSecondBeforeTransferredSize
        this.oneSecondBeforeTransferredSize = this.transferredSize
      }, 1000)
    })
  }
}