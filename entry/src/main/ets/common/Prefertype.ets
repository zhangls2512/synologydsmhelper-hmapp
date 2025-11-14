import { display } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'

export function getPreferType() {
  if (deviceInfo.productModel !== 'VDE-AL00' && deviceInfo.productModel !== 'VDE-AL10') {
    const orientation = display.getDefaultDisplaySync().orientation
    if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
      return 0
    }
    if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
      return 1
    }
  }
  if (deviceInfo.productModel === 'VDE-AL00' || deviceInfo.productModel === 'VDE-AL10') {
    const foldDisplayMode = display.getFoldDisplayMode()
    if (foldDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_FULL) {
      const orientation = display.getDefaultDisplaySync().orientation
      if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
        return 0
      }
      if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
        return 1
      }
    }
    if (foldDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_MAIN) {
      return 0
    }
  }
  return -1
}

export function getPreferTypeByDisplayId(displayId: number) {
  if (deviceInfo.productModel !== 'VDE-AL00' && deviceInfo.productModel !== 'VDE-AL10') {
    const orientation = display.getDisplayByIdSync(displayId).orientation
    if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
      return 0
    }
    if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
      return 1
    }
  }
  if (deviceInfo.productModel === 'VDE-AL00' || deviceInfo.productModel === 'VDE-AL10') {
    const foldDisplayMode = display.getFoldDisplayMode()
    if (foldDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_FULL) {
      const orientation = display.getDisplayByIdSync(displayId).orientation
      if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
        return 0
      }
      if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
        return 1
      }
    }
    if (foldDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_MAIN) {
      return 0
    }
  }
  return -1
}