//
//  SettingsBundle.h
//  zsup
//
//  Created by Dymov, Yuri on 08.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsBundle : NSObject

+ (SettingsBundle*)getInstanceForProjectPath:(NSString*)path;

- (void)updateSettings;

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *projectName;
@property (nonatomic, retain) NSString *settingFilePath;

@end
