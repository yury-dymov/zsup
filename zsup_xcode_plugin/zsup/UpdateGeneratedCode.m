//
//  UpdateGeneratedCode.m
//  zsup
//
//  Created by Dymov, Yuri on 11.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "UpdateGeneratedCode.h"

@implementation UpdateGeneratedCode
@synthesize projectDict;
@synthesize projectPath;

- (id)initWithProjectDict:(NSMutableDictionary *)aProjectDict andProjectPath:(NSString *)aProjectPath {
    self = [super init];
    if (self) {
        self.projectDict = aProjectDict;
        self.projectPath = aProjectPath;
    }
    return self;
}

- (void)dealloc {
    [keys release];
    [super dealloc];
}

- (void)process {    
    NSString *generatedCodePathKey = [self _findGeneratedCodeKey];
    
    if (generatedCodePathKey) {
        [self _deleteElemWithKey:generatedCodePathKey];
    }
        
    NSArray *files = [self _getAllObjectsWithRelativePath:nil];
    keys = [[self _generateKeys:[self _evalKeysAmountToGenerateFromStructure:files] * 2] retain];
    currentKeyIndex = 0;
    
    NSMutableDictionary *generatedCodeRootDict = [NSMutableDictionary new];
    [generatedCodeRootDict setValue:@"\"Generated Code\"" forKey:@"path"];
    [generatedCodeRootDict setValue:@"YES" forKey:@"is_directory"];
    [generatedCodeRootDict setValue:files forKey:@"files"];
    NSString *gcKey = [[self _processFiles:[NSArray arrayWithObject:generatedCodeRootDict]] objectAtIndex:0];
    [self _insertOrReplaceGeneratedCodeKey:gcKey instead:generatedCodePathKey];

    [generatedCodeRootDict release];
    [keys release];
}

- (NSString*)_findGeneratedCodeKey {
    NSMutableDictionary *objectDict = [projectDict valueForKey:@"objects"];
    NSString *generatedCodePathKey = nil;
    for (NSString *keyName in objectDict.allKeys) {
        NSMutableDictionary *dataDict = [objectDict valueForKey:keyName];
        NSString *elem_isa = [dataDict valueForKey:@"isa"];
        if (elem_isa) {
            if ([elem_isa isEqualToString:@"PBXGroup"]) {
                if ([[dataDict valueForKey:@"name"] isEqualToString:@"\"Generated Code\""]) {
                    generatedCodePathKey = keyName;
                    break;
                }
            }
        }
    }
    return generatedCodePathKey;
}

- (NSArray*)_processFiles:(NSArray*)files {
    NSMutableArray *ret = [NSMutableArray new];
    NSMutableDictionary *objectDict = [projectDict valueForKey:@"objects"];
    for (NSDictionary *fileDict in files) {
        if ([fileDict valueForKey:@"is_directory"]) {
            NSMutableDictionary *dirDict = [NSMutableDictionary new];
            [dirDict setValue:@"PBXGroup" forKey:@"isa"];
            [dirDict setValue:[[[fileDict valueForKey:@"path"] componentsSeparatedByString:@"/"] lastObject] forKey:@"name"];
            [dirDict setValue:@"\"<group>\"" forKey:@"sourceTree"];
            NSString *key = [keys objectAtIndex:currentKeyIndex++];
            [ret addObject:key];
            [objectDict setValue:dirDict forKey:key];
            
            NSArray *children = [self _processFiles:[fileDict valueForKey:@"files"]];
            NSString *schildren = @"(";
            for (NSString *str in children) {
                schildren = [schildren stringByAppendingString:[NSString stringWithFormat:@"%@, ", str]];
            }
            schildren = [schildren stringByAppendingString:@")"];
            [dirDict setValue:schildren forKey:@"children"];
            [dirDict release];
        } else {
            NSMutableDictionary *srcDict = [NSMutableDictionary new];
            [srcDict setValue:@"PBXFileReference" forKey:@"isa"];
            [srcDict setValue:[NSString stringWithFormat:@"\"%@\"",[[[fileDict valueForKey:@"path"] componentsSeparatedByString:@"/"] lastObject]]  forKey:@"name"];
            NSString *key = [keys objectAtIndex:currentKeyIndex++];
            [ret addObject:key];
            [objectDict setValue:srcDict forKey:key];
            if ([[[[fileDict valueForKey:@"path"] componentsSeparatedByString:@"."] lastObject] isEqualToString:@"h"]) {
                [srcDict setValue:@"sourcecode.c.h" forKey:@"lastKnownFileType"];
            } else {
                [srcDict setValue:@"sourcecode.c.objc" forKey:@"lastKnownFileType"];
                NSMutableDictionary *buildDict = [NSMutableDictionary new];
                [buildDict setValue:key forKey:@"fileRef"];
                [buildDict setValue:@"PBXBuildFile" forKey:@"isa"];
                NSString *buildKey = [keys objectAtIndex:currentKeyIndex++];
                [objectDict setValue:buildDict forKey:buildKey];
                for (NSMutableDictionary *objectElemDict in objectDict.allValues) {
                    if ([[objectElemDict valueForKey:@"isa"] isEqualToString:@"PBXSourcesBuildPhase"]) {
                        NSString *fileList = [[objectElemDict valueForKey:@"files"] stringByReplacingOccurrencesOfString:@")" withString:@""];
                        [objectElemDict setValue:[fileList stringByAppendingString:[NSString stringWithFormat:@"%@, )", buildKey]] forKey:@"files"];
                        break;
                    }
                }
                [buildDict release];
            }
            [srcDict setValue:@"\"<group>\"" forKey:@"sourceTree"];
            [srcDict setValue:[NSString stringWithFormat:@"\"Generated Code/%@\"", [fileDict valueForKey:@"path"]] forKey:@"path"];
        }
    }
    return [ret autorelease];
}

- (NSArray*)_getAllObjectsWithRelativePath:(NSString*)relativePath {
    NSMutableArray *ret = [NSMutableArray new];
    if (!relativePath)
        relativePath = @"";
    NSString *compositePath = [projectPath stringByAppendingPathComponent:relativePath];
    for (NSString *str in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:compositePath error:nil]) {
        BOOL isDir;
        [[NSFileManager defaultManager] fileExistsAtPath:[compositePath stringByAppendingPathComponent:str] isDirectory:&isDir];
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [dict setValue:[relativePath stringByAppendingPathComponent:str] forKey:@"path"];
        [ret addObject:dict];
        if (isDir) {
            [dict setValue:@"YES" forKey:@"is_directory"];
            [dict setValue:[self _getAllObjectsWithRelativePath:[relativePath stringByAppendingPathComponent:str]] forKey:@"files"];
        }
        [dict release];
    }
    return [ret autorelease];
}

- (NSInteger)_evalKeysAmountToGenerateFromStructure:(NSArray*)data {
    NSInteger ret = [data count];
    for (NSDictionary *dict in data) {
        NSArray *files = [dict valueForKey:@"files"];
        if (files) {
            ret += [self _evalKeysAmountToGenerateFromStructure:files];
        }
    }
    return ret;
}

- (NSArray*)_generateKeys:(NSInteger)amountOfKeys {
    unsigned int maxId = 0;
    NSString *suffix = 0;
    for (NSString *key in [[projectDict valueForKey:@"objects"] allKeys]) {
        NSScanner* pScanner = [NSScanner scannerWithString: [NSString stringWithFormat:@"0x%@", [key substringToIndex:8]]];
        suffix = [key substringFromIndex:8];
        unsigned int tint;
        [pScanner scanHexInt:&tint];
        maxId = MAX(maxId, tint);
    }
    NSMutableArray *ret = [NSMutableArray new];
    for (NSInteger i = 1; i <= amountOfKeys; ++i) {
        NSString *retKey = [NSString stringWithFormat:@"%lX", maxId + i];
        while (retKey.length < 8) {
            retKey = [NSString stringWithFormat:@"0%@", retKey];
        }
        [ret addObject:[retKey stringByAppendingString:suffix]];
    }
    return [ret autorelease];
}

- (NSArray*)_keysToDeleteFromRootKey:(NSString*)rootKey {
    NSMutableDictionary *objectDict = [projectDict valueForKey:@"objects"];    
    NSMutableArray *ret = [NSMutableArray new];
    [ret addObject:rootKey];
    NSDictionary *dictToDelete = [objectDict valueForKey:rootKey];
    if ([[dictToDelete valueForKey:@"isa"] isEqualToString:@"PBXGroup"]) {
        NSArray *children = [[[[[dictToDelete valueForKey:@"children"] stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""]  componentsSeparatedByString:@","];
        for (NSString *child in children) {
            child = [child stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([child length])
                [ret addObjectsFromArray:[self _keysToDeleteFromRootKey:child]];
        }
    } else {
        for (NSString *objectElemKey in objectDict.allKeys) {
            NSDictionary *objectElemDict = [objectDict valueForKey:objectElemKey];
            if ([[objectElemDict valueForKey:@"isa"] isEqualToString:@"PBXBuildFile"] && [[objectElemDict valueForKey:@"fileRef"] isEqualToString:rootKey]) {
                [ret addObject:objectElemKey];
            }
        }
    }
    return [ret autorelease];
}

- (void)_deleteElemWithKey:(NSString*)key {
    NSMutableDictionary *objectDict = [projectDict valueForKey:@"objects"];
    NSArray *keysToDelete = [self _keysToDeleteFromRootKey:key];
    
    for (NSMutableDictionary *buildDict in objectDict.allValues) {
        if ([[buildDict valueForKey:@"isa"] isEqualToString:@"PBXSourcesBuildPhase"]) {
            NSString *newFiles = [[buildDict valueForKey:@"files"] stringByReplacingOccurrencesOfString:@" ," withString:@","];
            for (NSString *key in keysToDelete) {
                [objectDict removeObjectForKey:key];
                newFiles = [newFiles stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@,", key] withString:@""];
            }
            [buildDict setValue:newFiles forKey:@"files"];
            break;
        }
    }
}

- (void)_insertOrReplaceGeneratedCodeKey:(NSString*)newKey instead:(NSString*)oldKey {
    NSMutableDictionary *objectDict = [projectDict valueForKey:@"objects"];    
    for (NSDictionary *objectDictElem in objectDict.allValues) {
        if ([[objectDictElem valueForKey:@"isa"] isEqualToString:@"PBXGroup"]) {
            if (![objectDictElem valueForKey:@"name"] && [objectDictElem valueForKey:@"path"]) {
                NSString *children = [objectDictElem valueForKey:@"children"];
                if (oldKey) {
                    children = [children stringByReplacingOccurrencesOfString:oldKey withString:newKey];
                } else {
                    children = [NSString stringWithFormat:@"(%@, %@", newKey, [children substringFromIndex:1]];
                }
                [objectDictElem setValue:children forKey:@"children"];
                break;
            }
        }
    }    
}



@end
