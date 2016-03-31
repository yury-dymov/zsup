//
//  UpdateManager.m
//  httpstest
//
//  Created by Dymov, Yuri on 10.06.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "UpdateManager.h"
#import "ASIFormDataRequest.h"
#import "SSZipArchive.h"
#import "BLAuthentication.h"
#import "UpdateElem.h"
#import "UpdateWindowController.h"


#define REMOTE_HOST @"http://zsup.mobi"
#define LOCAL_PATH @"/Library/Application Support/Developer/Shared/Xcode/"
#define DOWNLOAD_PATH @".zsup"

#define MOVE @"/bin/mv"
#define REMOVE @"/bin/rm"
#define SYMLINK @"/bin/ln"
#define MAKEDIR @"/bin/mkdir"
#define COPY @"/bin/cp"

static UpdateManager *singletonInstance;

@implementation UpdateManager
@synthesize updateWindowController = updateWindowController_;


- (NSArray*)loadLocalDistribInfo {
    return [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile: [LOCAL_PATH stringByAppendingPathComponent:@"ZSUP/.distrib"]] options:NSJSONReadingMutableContainers error:nil];
}

- (void)performUpdate {
    [self downloadFiles];
}

- (void)cancelUpdate {
    [[requestQueue allValues] makeObjectsPerformSelector:@selector(cancel)];
    [requestQueue removeAllObjects];
}

- (NSMutableDictionary*)makeDictFromDistribArray:(NSArray*)array {
    NSMutableDictionary *ret = [NSMutableDictionary new];
    for (NSDictionary *elem in array) {
        [ret setValue:[UpdateElem parseDict:elem] forKey:[elem valueForKey:@"file_file_name"]];
    }
    return [ret autorelease];
}

- (void)processDownloadedDistribArray:(NSArray*)downloaded {
    [localFiles release];
    @try {
        localFiles = [[self makeDictFromDistribArray:[self loadLocalDistribInfo]] retain];
    }
    @catch (NSException *exception) {
        localFiles = nil;
    }
    [remoteFiles release];
    remoteFiles = [[self makeDictFromDistribArray:downloaded] retain];
    for (NSString *key in remoteFiles.allKeys) {
        if ([[[localFiles valueForKey:key] fileHash] isEqualToString:[[remoteFiles valueForKey:key] fileHash]]) {
            [remoteFiles removeObjectForKey:key];
            [localFiles removeObjectForKey:key];
        }
    }
    block([remoteFiles count]);
}

- (void)checkForUpdatesWithCompletionBlock:(CompletionBlock)aBlock {
    [block release];
    block = [aBlock copy];
    
    ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[REMOTE_HOST stringByAppendingString:@"/getlist"]]];
    [req setPostValue:@"yuri@dymov.me" forKey:@"email"];
    [req setPostValue:@"catx7637" forKey:@"password"];
    [req setPostValue:@"json" forKey:@"format"];
    req.completionBlock = ^{
        [fileListResponse release];
        fileListResponse = [req.responseString copy];
        [self processDownloadedDistribArray:[NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingMutableContainers error:nil]];
    };
    req.delegate = self;
    req.didFailSelector = @selector(initialRequestFailed:);
    [req startAsynchronous];
}

- (void)initialRequestFailed:(ASIHTTPRequest*)req {
    block(-1);
    [requestQueue removeObjectForKey:req.description];
}


- (id)init {
    if (!singletonInstance) {
        self = [super init];
        if (self) {
            lock = [NSLock new];
            requestQueue = [NSMutableDictionary new];
            singletonInstance = self;
        }
    }
    return singletonInstance;
}


- (NSString*)makeMiddlePathFromElem:(UpdateElem*)anUpdateElem {
    switch (anUpdateElem.type) {
        case ZSUPFILE_Framework:
            return [LOCAL_PATH stringByAppendingPathComponent:@"ZSUP"];
        case ZSUPFILE_Plugin:
            return [LOCAL_PATH stringByAppendingPathComponent:@"Plug-ins"];
        case ZSUPFILE_FileTemplate:
            return @"/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/ZSUP";
        case ZSUPFILE_ProjectTemplate:
            return @"/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/Project Templates/ZSUP";
        default:
            return @"";
    }
}


- (void)cleanup {
    if (localFiles.count) {
        if (![[BLAuthentication sharedInstance] isAuthenticated:REMOVE]) {
            [[BLAuthentication sharedInstance] authenticate:REMOVE];
        }
        for (UpdateElem *elem in localFiles.allValues) {
            NSString *middlePath = [self makeMiddlePathFromElem:elem];
            if (elem.type == ZSUPFILE_Plugin || elem.type == ZSUPFILE_Framework) {
                NSString *target = [[LOCAL_PATH stringByAppendingPathComponent:middlePath] stringByAppendingPathComponent:[elem.fileName stringByReplacingOccurrencesOfString:@".zip" withString:@""]];
                NSArray *arguments = [NSArray arrayWithObjects:@"-rf", target, nil];
                [[BLAuthentication sharedInstance] executeCommandSynced:REMOVE withArgs:arguments];
            } else {
                for (NSString *xcode in [self findXcodePaths]) {
                    NSString *zipname = [elem.fileName stringByReplacingOccurrencesOfString:@".zip" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, elem.fileName.length)];
                    NSArray *names = [NSArray arrayWithObjects:zipname, [zipname stringByReplacingOccurrencesOfString:@"_" withString:@" "], nil];
                    for (NSString *name in names) {
                        NSString *completeMiddlePath = [xcode stringByAppendingPathComponent:middlePath];
                        NSString *path = [completeMiddlePath stringByAppendingPathComponent:name];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                            NSArray *arguments = [NSArray arrayWithObjects:@"-rf", path, nil];
                            [[BLAuthentication sharedInstance] executeCommandSynced:REMOVE withArgs:arguments];
                        }
                    }
                }
            }
        }
    }
}

- (void)updateLocalRevision {
    if (![[BLAuthentication sharedInstance] isAuthenticated:REMOVE]) {
        [[BLAuthentication sharedInstance] authenticate:REMOVE];
    }
    if (![[BLAuthentication sharedInstance] isAuthenticated:MOVE]) {
        [[BLAuthentication sharedInstance] authenticate:MOVE];
    }
    NSString *downloadPath = [NSHomeDirectory() stringByAppendingPathComponent:DOWNLOAD_PATH];
    NSString *distribLocalPath = [NSHomeDirectory() stringByAppendingPathComponent:@".distrib"];
    [fileListResponse writeToFile:distribLocalPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *distribFile = [LOCAL_PATH stringByAppendingPathComponent:@"ZSUP/.distrib"];
    NSArray *arguments = [NSArray arrayWithObjects:distribLocalPath, distribFile, nil];
    [[BLAuthentication sharedInstance] executeCommandSynced:MOVE withArgs:arguments];
    arguments = [NSArray arrayWithObjects:@"-rf", downloadPath, nil];
    [[BLAuthentication sharedInstance] executeCommandSynced:REMOVE withArgs:arguments];
}

- (void)fixSymLinks:(NSString*)root {
    if (![[BLAuthentication sharedInstance] isAuthenticated:SYMLINK]) {
        [[BLAuthentication sharedInstance] authenticate:SYMLINK];
    }
    NSMutableArray *files = [NSMutableArray new];
    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:root error:nil]) {
        NSString *file = [root stringByAppendingPathComponent:path];
        BOOL isDir;
        [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir];
        if (isDir) {
            [self fixSymLinks:file];
        } else {
            [files addObject:file];
        }
    }
    for (NSString *file in files) {
        int asize = [[NSNumber numberWithUnsignedLongLong:[[[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil] fileSize]] intValue];
        if (asize < 2000) {
            NSString *symPath = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
            if (symPath.length) {
                NSString *symAbsPath = [root stringByAppendingPathComponent:symPath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:symAbsPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
                    NSArray *arguments = [NSArray arrayWithObjects:@"-s", symPath, file, nil];
                    [[BLAuthentication sharedInstance] executeCommandSynced:SYMLINK withArgs:arguments];
                }
            }
        }
    }
    [files release];
}

- (void)installArchive:(NSString*)archiveName atPath:(NSString*)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (![[BLAuthentication sharedInstance] isAuthenticated:REMOVE]) {
            [[BLAuthentication sharedInstance] authenticate:REMOVE];
        }
        NSArray *arguments = [NSArray arrayWithObjects:@"-rf", path, nil];
        [[BLAuthentication sharedInstance] executeCommandSynced:REMOVE withArgs:arguments];
    }
    NSString *localPath = [NSHomeDirectory() stringByAppendingPathComponent:DOWNLOAD_PATH];
    NSString *localTarget = [localPath stringByAppendingPathComponent:[[archiveName stringByReplacingOccurrencesOfString:@".zip" withString:@""] stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
    [SSZipArchive unzipFileAtPath:[localPath stringByAppendingPathComponent:archiveName]  toDestination:localTarget];
    [self fixSymLinks:localTarget];
    
    NSString *ZSUPPath = [LOCAL_PATH stringByAppendingPathComponent:@"ZSUP"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:ZSUPPath]) {
        if (![[BLAuthentication sharedInstance] isAuthenticated:MAKEDIR]) {
            [[BLAuthentication sharedInstance] authenticate:MAKEDIR];
        }
        NSArray *arguments = [NSArray arrayWithObjects:ZSUPPath, nil];
        [[BLAuthentication sharedInstance] executeCommandSynced:MAKEDIR withArgs:arguments];
    }
    
    if (![[BLAuthentication sharedInstance] isAuthenticated:COPY]) {
        [[BLAuthentication sharedInstance] authenticate:COPY];
    }
    NSArray *arguments = [NSArray arrayWithObjects:@"-a", localTarget, path, nil];
    [[BLAuthentication sharedInstance] executeCommandSynced:COPY withArgs:arguments];
    
}

- (void)incDone {
    [lock lock];
    done++;
    if (done && done == [remoteFiles count]) {
        [lock unlock];
        [self.updateWindowController done];
        [self cleanup];
        for (UpdateElem *elem in remoteFiles.allValues) {
            NSString *filename = [elem.fileName stringByReplacingOccurrencesOfString:@".zip" withString:@""];
            if (elem.type == ZSUPFILE_Plugin || elem.type == ZSUPFILE_Framework) {
                [self installArchive:elem.fileName atPath:[[self makeMiddlePathFromElem:elem] stringByAppendingPathComponent:filename]];
                if (elem.type == ZSUPFILE_Framework) {
                    for (NSString *xcode in [self findXcodePaths]) {
                        NSString *middlePath = [xcode stringByAppendingPathComponent:@"Contents/Developer/Platforms"];
                        for (NSString *platform in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:middlePath error:nil]) {
                            if ([platform rangeOfString:@"iphone" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                                NSString *sdkPath = [[middlePath stringByAppendingPathComponent:platform] stringByAppendingPathComponent:@"Developer/SDKs"];
                                for (NSString *sdk in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sdkPath error:nil]) {
                                    NSString *framework = [sdk stringByAppendingPathComponent:@"System/Library/Frameworks"];
                                    if (![[BLAuthentication sharedInstance] isAuthenticated:SYMLINK]) {
                                        [[BLAuthentication sharedInstance] authenticate:SYMLINK];
                                    }
                                    if (![[BLAuthentication sharedInstance] isAuthenticated:REMOVE]) {
                                        [[BLAuthentication sharedInstance] authenticate:REMOVE];
                                    }
                                    NSString *source = [[LOCAL_PATH stringByAppendingPathComponent:@"ZSUP"] stringByAppendingPathComponent:filename];
                                    NSString *endpoint = [sdkPath stringByAppendingPathComponent:[framework stringByAppendingPathComponent:filename]];
                                    if ([[NSFileManager defaultManager] fileExistsAtPath:endpoint]) {
                                        NSArray *arguments = [NSArray arrayWithObjects:@"-rf", endpoint, nil];
                                        [[BLAuthentication sharedInstance] executeCommandSynced:REMOVE withArgs:arguments];
                                    }
                                    NSArray *arguments = [NSArray arrayWithObjects:@"-s", source, endpoint, nil];
                                    [[BLAuthentication sharedInstance] executeCommandSynced:SYMLINK withArgs:arguments];
                                }
                            }
                        }
                    }
                }
            } else {
                for (NSString *xcode in [self findXcodePaths]) {
                    if (![[BLAuthentication sharedInstance] isAuthenticated:MAKEDIR]) {
                        [[BLAuthentication sharedInstance] authenticate:MAKEDIR];
                    }
                    NSString *completeMiddlePath = [xcode stringByAppendingPathComponent:[self makeMiddlePathFromElem:elem]];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:completeMiddlePath]) {
                        NSArray *arguments = [NSArray arrayWithObjects:completeMiddlePath, nil];
                        [[BLAuthentication sharedInstance] executeCommandSynced:MAKEDIR withArgs:arguments];
                    }
                    
                    [self installArchive:elem.fileName atPath:[[xcode stringByAppendingPathComponent:[self makeMiddlePathFromElem:elem]] stringByAppendingPathComponent:[filename stringByReplacingOccurrencesOfString:@"_" withString:@" "]]];
                }
            }
        }
        [self updateLocalRevision];
    } else {
        [lock unlock];
    }
}


- (void)downloadFiles {
    if ([remoteFiles count]) {
        [lock lock];
        done = 0;
        [lock unlock];
        NSString *downloadDir = [NSHomeDirectory() stringByAppendingPathComponent:DOWNLOAD_PATH];
        if (![[NSFileManager defaultManager] fileExistsAtPath:downloadDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        for (UpdateElem *elem in remoteFiles.allValues) {
            NSString *localFile = [downloadDir stringByAppendingPathComponent:elem.fileName];
            int asize = [[NSNumber numberWithUnsignedLongLong:[[[NSFileManager defaultManager] attributesOfItemAtPath:localFile error:nil] fileSize]] intValue];
            if (asize != [[elem fileSize] intValue]) {
                ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:[REMOTE_HOST stringByAppendingString:@"/getfile"]]];
                [requestQueue setValue:req forKey:req.description];
                [req setPostValue:@"yuri@dymov.me" forKey:@"email"];
                [req setPostValue:@"catx7637" forKey:@"password"];
                [req setPostValue:elem.fileName forKey:@"file_name"];
                [req setDownloadDestinationPath:localFile];
                [req setAllowResumeForFileDownloads:YES];
                [req setDownloadProgressDelegate:self.updateWindowController];
                req.completionBlock = ^{
                    [requestQueue removeObjectForKey:req.description];
                    [self incDone];
                };
                [req startAsynchronous];
            } else {
                [self incDone];
            }
        }
    }
}

- (NSArray*)findXcodePaths {
    NSMutableArray *ret = [NSMutableArray new];
    for (NSString *xcode in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications" error:nil]) {
        if ([xcode rangeOfString:@"xcode" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSString *str = [xcode stringByReplacingOccurrencesOfString:@".app" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, xcode.length)];
            str = [str stringByReplacingOccurrencesOfString:@"xcode" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, str.length)];
            for (NSInteger i = 0; i < 10; ++i) {
                str = [str stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%ld", (long)i] withString:@""];
            }
            str = [[str stringByReplacingOccurrencesOfString:@"." withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
            str = [str stringByReplacingOccurrencesOfString:@"alpha" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, str.length)];
            str = [str stringByReplacingOccurrencesOfString:@"beta" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, str.length)];
            str = [str stringByReplacingOccurrencesOfString:@"release" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, str.length)];
            str = [str stringByReplacingOccurrencesOfString:@"r" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, str.length)];;
            if (!str.length)
                [ret addObject:[@"/Applications" stringByAppendingPathComponent:xcode]];
        }
    }
    return [ret autorelease];
}

- (void)showUpdateWindow {
    if (!self.updateWindowController) {
        updateWindowController_ = [[UpdateWindowController alloc] initWithWindow:[[[NSWindow alloc] initWithContentRect:NSMakeRect(0.0f, 0.0f, 0.0f, 0.0f) styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease]];
        self.updateWindowController.window.title = @"Checking Updates";
        self.updateWindowController.delegate = self;
    }
    [self.updateWindowController showUpdateRequired:remoteFiles.allValues oldVersions:localFiles.allValues];
    [self.updateWindowController showWindow:self];
}

+ (id)allocWithZone:(NSZone *)zone {
    if (!singletonInstance)
        return [super allocWithZone:zone];
    return singletonInstance;
}

+ (id)getInstance {
    if (!singletonInstance)
        return [UpdateManager new];
    return singletonInstance;
}

- (void)dealloc {
    [super dealloc];
}

- (oneway void)release {
    
}

- (id)autorelease {
    return singletonInstance;
}

- (id)retain {
    return singletonInstance;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

@end
