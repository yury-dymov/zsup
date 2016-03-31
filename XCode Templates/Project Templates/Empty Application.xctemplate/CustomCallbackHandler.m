#import "CustomCallbackHandler.h"

@implementation CustomCallbackHandler

- (void)onRegistrationStatusChanged:(SUPRegistrationStatusType)registrationStatus :(int32_t)errorCode :(NSString *)errorMessage {
}

- (void)onApplicationSettingsChanged:(SUPStringList *)names {
}

- (void)onConnectionStatusChanged:(SUPConnectionStatusType)connectionStatus :(int32_t)errorCode :(NSString *)errorMessage {    
}

- (void)onDeviceConditionChanged:(SUPDeviceConditionType)condition {
}

- (void)onHttpCommunicationError:(int32_t)errorCode :(NSString *)errorMessage :(SUPStringProperties *)responseHeaders {
}

#if __SUP_VERSION__ >= 2200

- (void)onCustomizationBundleDownloadComplete:(NSString *)customizationBundleID :(int32_t)errorCode :(NSString *)errorMessage {
}

- (int)onPushNotification :(NSDictionary*)notification {
    return 0;
}

#endif


@end
