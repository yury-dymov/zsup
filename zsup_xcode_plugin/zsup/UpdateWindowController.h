//
//  UpdateWindowController.h
//  httpstest
//
//  Created by Dymov, Yuri on 13.06.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UpdateWindowController;
@protocol ASIProgressDelegate;

@protocol UpdateWindowControllerProtocol <NSObject>

- (void)performUpdate;
- (void)cancelUpdate;

@end

@interface UpdateWindowController : NSWindowController<ASIProgressDelegate> {
    NSProgressIndicator *progressIndicator_;
    NSTextField *totalDownloadSizeLabel;
    NSButton *updateButton;
    NSUInteger totalDownloadSize;
}

@property (nonatomic, retain) id<UpdateWindowControllerProtocol> delegate;
@property (nonatomic, readonly) NSProgressIndicator *progressIndicator;


- (void)showUpdateRequired:(NSArray*)remoteFiles oldVersions:(NSArray*)localFiles;
- (void)done;

@end
