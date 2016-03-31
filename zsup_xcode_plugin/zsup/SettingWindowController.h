//
//  SettingWindowController.h
//  settings
//
//  Created by Dymov, Yuri on 08.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingWindowController : NSWindowController

@property (nonatomic, retain) IBOutlet NSTextField *username;
@property (nonatomic, retain) IBOutlet NSSecureTextField *password;
@property (nonatomic, retain) IBOutlet NSTextField *projectName;
@property (nonatomic, retain) IBOutlet NSTextField *error;
@property (nonatomic, retain) IBOutlet NSTextField *header;

@property (nonatomic, copy) NSString *projectPath;

@end
