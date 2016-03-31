//
//  UpdateManager.h
//  httpstest
//
//  Created by Dymov, Yuri on 10.06.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CompletionBlock)(NSInteger toDownload);

@class UpdateWindowController;
@protocol UpdateWindowControllerProtocol;

@interface UpdateManager : NSObject<UpdateWindowControllerProtocol> {
    CompletionBlock block;
    NSMutableDictionary *remoteFiles;
    NSMutableDictionary *localFiles;
    NSString *fileListResponse;
    NSInteger done;
    NSLock *lock;
    UpdateWindowController *updateWindowController_;
    NSMutableDictionary *requestQueue;
}

@property (nonatomic, readonly) UpdateWindowController *updateWindowController;

- (void)checkForUpdatesWithCompletionBlock:(CompletionBlock)aBlock;
- (void)performUpdate;

- (void)showUpdateWindow;

+ (id)getInstance;

@end
