//
//  SettingWindowController.m
//  settings
//
//  Created by Dymov, Yuri on 08.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "SettingWindowController.h"

@interface SettingWindowController ()

@end

@implementation SettingWindowController
@synthesize projectName;
@synthesize username;
@synthesize password;
@synthesize error;
@synthesize header;
@synthesize projectPath;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void)windowDidLoad
{
    [super windowDidLoad];
}


@end
