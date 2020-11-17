package com.reactnativemediapicker

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Point
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.app.ActivityCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.zhihu.matisse.MimeType
import com.zhihu.matisse.internal.utils.PhotoMetadataUtils


class MediaPickerUtils {
  fun hasReadPermission(activity: Activity?): Boolean {
    val readPermission = ActivityCompat.checkSelfPermission(activity!!, Manifest.permission.READ_EXTERNAL_STORAGE)
    return readPermission == PackageManager.PERMISSION_GRANTED
  }

  fun getResponseMap(context: Context, uri: Uri, options: ReadableMap?): ReadableMap? {
    val resolver = context.contentResolver
    val returnCursor: Cursor = resolver.query(uri, null, null, null, null)!!
    val nameIndex: Int = returnCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
    returnCursor.moveToFirst()
    val fileName: String = returnCursor.getString(nameIndex)
    val absolutePathOfImage = returnCursor.getString(returnCursor.getColumnIndexOrThrow("_data"));
    val mimeType: String? = resolver.getType(uri)
    val fileSize = getFileSize(context, uri)
    val map: WritableMap = Arguments.createMap()
    map.putString("uri", uri.toString())
    map.putString("path", "file://$absolutePathOfImage")
    map.putDouble("size", fileSize)
    map.putString("name", fileName)
    map.putString("type", mimeType)
    var dimensions: Point? = getImageSize(context, uri)
    if(MimeType.isVideo(mimeType)) {
      dimensions = getVideoSize(context, uri)
      getVideoDuration(context, uri)?.let { map.putInt("duration", it) }
    }
    if (dimensions != null) {
      map.putInt("width", dimensions.x)
      map.putInt("height", dimensions.y)
    }
    returnCursor.close()
    if(options!!.hasKey("maxFileSize")) {
      if(fileSize > options.getInt("maxFileSize") * 1000000) {
        return null
      }
    }
    return map
  }

  private fun getFileSize(context: Context, uri: Uri?): Double {
    return try {
      val f = context.contentResolver.openFileDescriptor(uri!!, "r")
      f!!.statSize.toDouble()
    } catch (e: Exception) {
      e.printStackTrace()
      0.0
    }
  }

  private fun getImageSize(context: Context, uri: Uri?): Point? {
    val contentProvider: ContentResolver = context.contentResolver
    val imageSize: Point = PhotoMetadataUtils.getBitmapBound(contentProvider, uri)
    val w: Int = imageSize.x
    val h: Int = imageSize.y
    return Point(w, h)
  }
  private fun getVideoDuration(context: Context, uri: Uri?): Int? {
    val contentProvider: ContentResolver = context.contentResolver
    val retriever = MediaMetadataRetriever()
    retriever.setDataSource(PhotoMetadataUtils.getPath(contentProvider, uri))
    return retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION).toInt()
  }
  private fun getVideoSize(context: Context, uri: Uri?): Point? {
    val contentProvider: ContentResolver = context.contentResolver
    val retriever = MediaMetadataRetriever()
    retriever.setDataSource(PhotoMetadataUtils.getPath(contentProvider, uri))
    val w = Integer.valueOf(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH))
    val h = Integer.valueOf(retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT))
    retriever.release()
    return Point(w, h)
  }
}
