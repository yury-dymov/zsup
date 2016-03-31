//
//  MigrateToSUPVersion.h
//  zsup
//
//  Created by Dymov, Yuri on 11.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MigrateToSUPVersion : NSObject

+ (void)migrateFromVersion:(NSString*)initialVesrion toVersion:(NSString*)newVersion withObjectDict:(NSMutableDictionary*)objectDict andProjectPath:(NSString*)projectPath;

@end
