//
//  RNMediaPicker.m
//  RNMediaPicker
//
//  Copyright © 2020 Le Hau. All rights reserved.
//

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNMediaPicker, NSObject)

RCT_EXTERN_METHOD(launchGallery:(NSDictionary *)params
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)
@end
