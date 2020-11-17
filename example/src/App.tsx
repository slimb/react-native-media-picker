import React from 'react'
import { Button, PermissionsAndroid, Platform, View } from 'react-native'
import RNMediaPicker from 'react-native-media-picker'

const App = () => {
  const _openPicker = async () => {
    try {
      if (Platform.OS === 'android') {
        const result = await PermissionsAndroid.requestMultiple([
          'android.permission.CAMERA',
          'android.permission.READ_EXTERNAL_STORAGE',
        ])
        if (
          !result['android.permission.CAMERA'] ||
          !result['android.permission.READ_EXTERNAL_STORAGE']
        ) {
          return
        }
      }
      RNMediaPicker.launchGallery({
        assetType: 'image',
        limit: 12,
        maxFileSize: 5,
        usedCameraButton: false,
      })
    } catch (error) {}
  }

  return (
    <View>
      <Button title='Open Picker' onPress={_openPicker} />
    </View>
  )
}

export default App
