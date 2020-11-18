import { NativeModules } from 'react-native'

export type MediaPickerOptions = {
  assetType?: 'video' | 'image'
  limit?: number
  numberOfColumn?: number
  showPreview?: boolean
  maxFileSize?: number
  maxOriginalSize?: number
  maxDuration?: number
  usedCameraButton?: boolean
  maxVideoDuration?: number
  messages?: {
    fileTooLarge?: string
    noCameraPermissions?: string
    noAlbumPermission?: string
    maxSelection?: string
    ok?: string
    maxDuration?: string
    tapHereToChange?: string
    cancelTitle?: string
    emptyMessage?: string
    doneTitle?: string
  }
}

export type MediaPickerRespone = {
  success: {
    uri: string
    path: string
    size: number
    name: string
    type: string
    width?: number
    height?: number
    duration?: number
  }[]
  error: number
}

type MediaPickerType = {
  launchGallery(options: MediaPickerOptions): Promise<MediaPickerRespone>
}

const { RNMediaPicker } = NativeModules

export default RNMediaPicker as MediaPickerType
