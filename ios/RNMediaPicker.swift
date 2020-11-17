//
//  RNMediaPicker.swift
//  RNMediaPicker
//
//  Copyright © 2020 Le Hau. All rights reserved.
//
import Foundation
import Photos
import UIKit
import TLPhotoPicker

@objc(RNMediaPicker)
class RNMediaPicker: NSObject {

var viewController: TLPhotosPickerViewController? = nil
    var resolve: RCTPromiseResolveBlock? = nil
    var reject: RCTPromiseRejectBlock? = nil
    var options: NSDictionary? = nil
    @objc(launchGallery:withResolver:withRejecter:)
    func launchGallery(arguments: NSDictionary?, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        var configure = TLPhotosPickerConfigure()
        self.options = arguments
        let assetType:String = arguments?["assetType"] as? String ?? "image"
        let limit:Int = arguments?["limit"] as? Int ?? 1
        let numberOfColumn: Int = arguments?["numberOfColumn"] as? Int ?? 3
        let messages: NSDictionary? = arguments?["messages"] as? NSDictionary
        if (messages != nil) {
            if let tapHereToChange = messages?["tapHereToChange"] {
                configure.tapHereToChange = tapHereToChange as! String
            }
            if let cancelTitle = messages?["cancelTitle"] {
                configure.cancelTitle = cancelTitle as! String
            }
            if let doneTitle = messages?["doneTitle"] {
                configure.doneTitle = doneTitle as! String
            }
            if let emptyMessage = messages?["emptyMessage"] {
                configure.emptyMessage = emptyMessage as! String
            }
        }
        if (assetType == "image") {
            configure.mediaType = PHAssetMediaType.image
        } else if (assetType == "video") {
            configure.mediaType = PHAssetMediaType.video
        }
        let maxVideoDuration: Double? = arguments!["maxVideoDuration"] as? Double
        if (maxVideoDuration != nil) {
            configure.maxVideoDuration = maxVideoDuration
        }
        configure.usedCameraButton = arguments?["usedCameraButton"] as? Bool ?? false
        configure.recordingVideoQuality = .typeHigh
        configure.singleSelectedMode = limit < 2
        configure.maxSelectedAssets = limit
        configure.numberOfColumn = numberOfColumn
        configure.autoPlay = false
        DispatchQueue.main.async {
            self.resolve = resolve
            self.reject = reject
            let rootController = self.topMostViewController()
            self.viewController = TLPhotosPickerViewController()
            self.viewController?.delegate = self
            self.viewController?.configure = configure
            rootController?.present(self.viewController!, animated: true, completion: nil)
        }
    }
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        DispatchQueue.global().async {
            var medias: Array<NSDictionary> = Array<NSDictionary>()
            for asset in withTLPHAssets {
                let media: NSMutableDictionary = NSMutableDictionary()
                media.setObject(asset.phAsset!.localIdentifier, forKey: NSString("identifier"))
                media.setObject(asset.originalFileName!, forKey: NSString("name"))
                media.setObject(asset.phAsset!.pixelWidth, forKey: NSString("width"))
                media.setObject(asset.phAsset!.pixelHeight, forKey: NSString("height"))
                let semaphore = DispatchSemaphore(value: 0)
                
                asset.tempCopyMediaFile(
                    videoRequestOptions: nil,
                    imageRequestOptions: nil,
                    livePhotoRequestOptions: nil,
                    exportPreset: AVAssetExportPresetHighestQuality,
                    convertLivePhotosToJPG: true,
                    progressBlock: { (progress) in
                        print(progress)
                    },
                    completionBlock: { (url, mimeType) in
                        media.setObject(url.absoluteString, forKey: NSString("uri"))
                        media.setObject(url.absoluteString, forKey: NSString("path"))
                        media.setObject(mimeType, forKey: NSString("mimeType"))
                        if (asset.type == .photo) {
                            asset.photoSize(completion: {(fileSize) in media.setObject(fileSize, forKey: NSString("size"))})
                            medias.append(media)
                            semaphore.signal()
                        } else if (asset.type == .video) {
                            asset.videoSize(completion: {(fileSize) in media.setObject(fileSize, forKey: NSString("size"))})
                            medias.append(media)
                            semaphore.signal()
                        }else {
                            medias.append(media)
                            semaphore.signal()
                        }
                    }
                )
                _ = semaphore.wait(timeout: .distantFuture)
            }
            DispatchQueue.main.async {
                let response: NSMutableDictionary = NSMutableDictionary()
                response.setValue(medias, forKey: "success")
                response.setValue(0, forKey: "error")
                self.resolve!(response)
                self.resolve = nil
            }
        }
    }
    
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
    }
    
    func photoPickerDidCancel() {}
    func dismissComplete() {}
    func canSelectAsset(phAsset: PHAsset) -> Bool {
        var isValid: Bool = true
        if let maxSize = self.options!["maxFileSize"] {
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.isSynchronous = true
            let resource = PHAssetResource.assetResources(for: phAsset)
            let imageSizeByte = resource.first?.value(forKey: "fileSize") as? Float ?? 0
            let imageSizeMB = imageSizeByte / (1024.0*1024.0)
            if imageSizeMB > maxSize as! Float {
                let alert = UIAlertController(title: "", message: self.t("fileTooLarge"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: self.t("ok"), style: .default, handler: nil))
                self.viewController?.present(alert, animated: true, completion: nil)
                isValid = false
            }
        }
        if phAsset.mediaType == .video {
            if let maxDuration = self.options!["maxDuration"] as? Double {
                if phAsset.duration > maxDuration {
                    let alert = UIAlertController(title: "", message: self.t("maxDuration"), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: self.t("ok"), style: .default, handler: nil))
                    self.viewController?.present(alert, animated: true, completion: nil)
                    isValid = false
                }
            }
            
        }
        return isValid
    }
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(title: "", message: self.t("maxSelection"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.t("ok"), style: .default, handler: nil))
        picker.present(alert, animated: true, completion: nil)
    }
    func handleNoAlbumPermissions(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(title: "", message: self.t("noAlbumPermission"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.t("ok"), style: .default, handler: nil))
        picker.present(alert, animated: true, completion: nil)
    }
    func handleNoCameraPermissions(picker: TLPhotosPickerViewController) {
        let alert = UIAlertController(title: "", message: self.t("noCameraPermissions"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: self.t("ok"), style: .default, handler: nil))
        picker.present(alert, animated: true, completion: nil)
    }
    
    private func t(_ message: String) -> String {
        let messages: NSDictionary? = self.options!["messages"] as? NSDictionary
        
        if let m = messages?[message] {
            return m as! String
        }
        
        return message
    }
    
    func topMostViewController() -> UIViewController? {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while topController?.presentedViewController != nil {
            topController = topController?.presentedViewController
        }
        return topController
    }

  @objc
  func constantsToExport() -> [AnyHashable : Any]! {
    return ["count": 1]
  }

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
