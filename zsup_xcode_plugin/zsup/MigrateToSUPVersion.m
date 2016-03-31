//
//  MigrateToSUPVersion.m
//  zsup
//
//  Created by Dymov, Yuri on 11.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "MigrateToSUPVersion.h"

@implementation MigrateToSUPVersion

+ (NSString*)buildReversePathForDict:(NSString*)key intermediateResult:(NSString*)res withGlobalDict:(NSDictionary*)objects{
    for (NSString *newKey in objects.allKeys) {
        NSDictionary *objectElem = [objects valueForKey:newKey];
        if ([[objectElem valueForKey:@"isa"] isEqualToString:@"PBXGroup"] && [[objectElem valueForKey:@"children"] rangeOfString:key].location != NSNotFound) {
            NSString *path = [[objectElem valueForKey:@"path"] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            if (path.length) {
                if (!res) {
                    return [self buildReversePathForDict:newKey intermediateResult:path withGlobalDict:objects];
                } else {
                    return [self buildReversePathForDict:newKey intermediateResult:[path stringByAppendingPathComponent:res] withGlobalDict:objects];
                }
            }
            return res;
        }
    }
    return nil;
}


+ (void)migrateFromVersion:(NSString *)initialVersion toVersion:(NSString *)newVersion withObjectDict:(NSMutableDictionary *)objectDict andProjectPath:(NSString*)projectPath{
    NSString *updatedProjectPath = [projectPath stringByReplacingOccurrencesOfString:@".xcodeproj" withString:@""];
    for (NSString *objectKey in objectDict.allKeys) {
        NSDictionary *objectDictElem = [objectDict valueForKey:objectKey];
        NSString *objectDictElemName = [objectDictElem valueForKey:@"name"];
        if ([objectDictElemName isEqualToString:[NSString stringWithFormat:@"%@.framework", initialVersion]]) {
            [objectDictElem setValue:[objectDictElemName stringByReplacingOccurrencesOfString:initialVersion withString:newVersion] forKey:@"name"];
            [objectDictElem setValue:[[objectDictElem valueForKey:@"path"] stringByReplacingOccurrencesOfString:initialVersion withString:newVersion] forKey:@"path"];
        }
        
        if ([[objectDictElem valueForKey:@"isa"] isEqualToString:@"PBXFileReference"] && [[objectDictElem valueForKey:@"lastKnownFileType"] rangeOfString:@"sourcecode.c"].location != NSNotFound) {
            NSString *filePath = [[updatedProjectPath stringByAppendingPathComponent:[self buildReversePathForDict:objectKey intermediateResult:nil withGlobalDict:objectDict]] stringByAppendingPathComponent:[objectDictElem valueForKey:@"path"]];
            

            NSString *file = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
            file = [file stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<%@/", initialVersion] withString:[NSString stringWithFormat:@"<%@/", newVersion]];
            [file writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
    
}

@end
