package com.lehau.reactnativemediapicker

import android.app.Activity
import android.content.Intent
import com.facebook.react.bridge.*
import com.reactnativemediapicker.MediaPickerUtils
import com.zhihu.matisse.Matisse
import com.zhihu.matisse.MimeType
import com.zhihu.matisse.engine.impl.GlideEngine
import com.zhihu.matisse.internal.entity.CaptureStrategy

class RNMediaPickerModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private var mPickerPromise: Promise? = null
    private var pendingResult = false
    private var options: ReadableMap? = null
    private val mediaPickerUtils = MediaPickerUtils()

    override fun getName() = "RNMediaPicker"

    override fun getConstants(): MutableMap<String, Any> {
        return hashMapOf("count" to 1)
    }

    private val mActivityEventListener: ActivityEventListener = object : BaseActivityEventListener() {
        override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent?) {
            if (requestCode == 23 && resultCode == Activity.RESULT_OK) {
                val listUri = Matisse.obtainResult(data);
                val response: WritableMap = WritableNativeMap();
                val listFile: WritableArray = WritableNativeArray();
                var error = 0
                for (uri in listUri) {
                    val map = mediaPickerUtils.getResponseMap(reactApplicationContext, uri, options)
                    if(map != null) {
                        listFile.pushMap(map);
                    } else {
                        error+=1
                    }
                }
                response.putArray("success: ", listFile)
                response.putInt("error: ", error)
                mPickerPromise?.resolve(response)
            }
            pendingResult = false
        }
    }

    @ReactMethod
    fun launchGallery(readableMap: ReadableMap, promise: Promise) {
        if(pendingResult) {
            return
        }
        pendingResult = true
        var assetType = "any"
        var limit = 1
        var numberOfColumn = 3
        var showPreview = false
        var maxOriginalSize: Int = 0
        val currentActivity = currentActivity
        if (currentActivity == null) {
            promise.reject("E_ACTIVITY_DOES_NOT_EXIST", "Activity doesn't exist")
            return
        }
        if(!mediaPickerUtils.hasReadPermission(currentActivity)) {
            promise.reject("PERMISSION_ERROR", "Don't have permission")
            return
        }
        if (readableMap.hasKey("assetType")) {
            assetType = readableMap.getString("assetType").toString()
        }
        if (readableMap.hasKey("limit")) {
            limit = readableMap.getInt("limit")
        }
        if (readableMap.hasKey("numberOfColumn")) {
            numberOfColumn = readableMap.getInt("numberOfColumn")
        }
        if (readableMap.hasKey("showPreview")) {
            showPreview = readableMap.getBoolean("showPreview")
        }
        if (readableMap.hasKey("maxOriginalSize")) {
            maxOriginalSize = readableMap.getInt("maxOriginalSize")
        }
        var mimeTypes = when (assetType) {
            "image" -> {
                MimeType.of(MimeType.PNG, MimeType.JPEG)
            }
            "video" -> {
                MimeType.of(MimeType.MP4)
            }
            else -> {
                MimeType.ofAll()
            }
        }

        val packageName: String = reactApplicationContext.packageName
        val captureStrategy = CaptureStrategy(
                true,
                StringBuilder(packageName).append(".provider").toString(),
                "."
        )
        mPickerPromise = promise
        options = readableMap
        try {
            Matisse.from(currentActivity)
                    .choose(mimeTypes)
                    .countable(limit > 1)
                    .captureStrategy(captureStrategy)
                    .showSingleMediaType("any" != assetType)
                    .capture("video" != assetType)
                    .spanCount(numberOfColumn)
                    .maxSelectable(limit)
                    .thumbnailScale(0.85f)
                    .imageEngine(GlideEngine())
                    .showPreview(showPreview)
                    .originalEnable(maxOriginalSize != 0)
                    .maxOriginalSize(maxOriginalSize)
                    .forResult(23)
        } catch (e: Exception) {
            mPickerPromise!!.reject("E_FAILED_TO_SHOW_PICKER", e);
            mPickerPromise = null;
        }
    }

    init {
        reactContext.addActivityEventListener(mActivityEventListener);
    }
}
