//
//  ProjectAPI.h
//  zsup
//
//  Created by Dymov, Yuri on 11.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProjectAPI : NSObject {
    NSString *projectPath;
    NSMutableDictionary *projectDict;
}

+ (ProjectAPI*)getInstanceForProjectPath:(NSString*)aProjectPath;

@property (nonatomic, readonly) NSString *SUPVersion;

- (void)migrateToSUPVersion:(NSString*)newSUPVersion;
- (void)updateGeneratedCodeFromArchive:(NSString*)archivePath;
- (void)fixImports;

@end
