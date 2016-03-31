//
//  SettingsBundle.m
//  zsup
//
//  Created by Dymov, Yuri on 08.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "SettingsBundle.h"

@implementation SettingsBundle
@synthesize username;
@synthesize password;
@synthesize projectName;
@synthesize settingFilePath;

static NSMutableDictionary *bundles;

+ (void)initBundles {
    if (!bundles)
        bundles = [NSMutableDictionary new];
}

- (void)readSettingFile {
    if ([[NSFileManager defaultManager] fileExistsAtPath:settingFilePath]) {
        NSString *str = [NSString stringWithContentsOfFile:settingFilePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *cmp = [str componentsSeparatedByString:@";"];
        self.username = [[cmp objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.password = [[cmp objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.projectName = [[cmp objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

- (void)updateSettings {
    NSString *newSettings = [NSString stringWithFormat:@"%@;%@;%@", self.username, self.password, self.projectName];
    [newSettings writeToFile:settingFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (id)initWithPath:(NSString*)aPath {
    self = [super init];
    if (self) {
        self.username = @"";
        self.password = @"";
        NSArray *components = [[aPath stringByReplacingOccurrencesOfString:@"file://localhost" withString:@""] componentsSeparatedByString:@"/"];
        NSInteger newPathCount = [components count] - 1 - ([[components lastObject] length] == 0);
        NSString *newPath = @"/";
        for (NSInteger i = 0; i < newPathCount; ++i) {
            newPath = [newPath stringByAppendingPathComponent:[components objectAtIndex:i]];
        }
        NSString *zPath = [newPath stringByAppendingPathComponent:@".zsup"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:zPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:zPath withIntermediateDirectories:YES attributes:nil error:nil];

        self.settingFilePath = [zPath stringByAppendingPathComponent:@".zsettings"];
        [self readSettingFile];
        
        if (!self.projectName.length) {
            NSString *zsupDefaults = [NSHomeDirectory() stringByAppendingPathComponent:@".zsupdefaults"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:zsupDefaults]) {
                NSString *def = [NSString stringWithContentsOfFile:zsupDefaults encoding:NSUTF8StringEncoding error:nil];
                NSArray *cred = [def componentsSeparatedByString:@";"];
                self.username = [[cred objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                self.password = [[cred objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
                
            self.projectName = [[newPath componentsSeparatedByString:@"/"] lastObject];
            [self updateSettings];
        }
    }
    return self;
}


+ (SettingsBundle*)getInstanceForProjectPath:(NSString *)path {
    [self initBundles];
//    SettingsBundle *ret = [bundles valueForKey:path];
//    if (!ret) {
        SettingsBundle *ret = [[SettingsBundle alloc] initWithPath:path];
        [bundles setValue:ret forKey:path];
        [ret release];
//    }
    return ret;
}

@end
