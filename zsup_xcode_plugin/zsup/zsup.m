//
//  zsup.m
//  zsup
//
//  Created by Dymov, Yuri on 05.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "zsup.h"
#import "ASIFormDataRequest.h"
#import "SettingsBundle.h"
#import "SettingWindowController.h"
#import "ProjectAPI.h"
#import "UpdateManager.h"


#define Z_SUP_MENU_TITLE @"Z_SUP"
#define Z_SUP_MIGRATE_TITLE @"Migrate"
#define Z_SUP_CHECK_UPDATES @"Check Updates"
#define Z_SUP_FIX_PROJECT @"Fix Project"

@implementation zsup

static SettingWindowController *globalSettingWindowController;

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}

- (NSString*)_getProjectPath {
    return [NSApp mainWindow].representedFilename;
}

- (ProjectAPI*)getProjectAPI {
    return [ProjectAPI getInstanceForProjectPath:[self _getProjectPath]];
}

- (SettingsBundle*)getSettingBundle {
    return [SettingsBundle getInstanceForProjectPath:[self _getProjectPath]];
}

- (NSString*)_getSUPVersionFromMenuItem:(NSMenuItem*)aMenuItem {
    return [[aMenuItem.title stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@""];
}

- (void)initMenu {
    NSMenu *mainMenu = [NSApp mainMenu];
    // create a new menu and add a new item
    NSMenu *menu = [[NSMenu alloc] initWithTitle:Z_SUP_MENU_TITLE];
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:@"Get Generated Code" action:@selector(getGeneratedCode) keyEquivalent:@"u"];
    menu.delegate = self;
    //        [item1 setKeyEquivalentModifierMask:NSCommandKeyMask];
    [item1 setTarget:self];
    [menu addItem:item1];
    [item1 release];
    
    NSMenuItem *migrateMenuItem = [[NSMenuItem alloc] initWithTitle:Z_SUP_MIGRATE_TITLE action:NULL keyEquivalent:@""];
    NSMenu *migrateMenu = [[NSMenu alloc] init];
    
    NSMenuItem *sup213 = [[NSMenuItem alloc] initWithTitle:@"SUP 2.1.3" action:@selector(migrateMenuItemSelected:) keyEquivalent:@""];
    [sup213 setRepresentedObject:sup213];
    [sup213 setState:NSOnState];
    [sup213 setTarget:self];
    [migrateMenu addItem:sup213];
    [sup213 release];
    
    NSMenuItem *sup22 = [[NSMenuItem alloc] initWithTitle:@"SUP 2.2" action:@selector(migrateMenuItemSelected:) keyEquivalent:@""];
    [sup22 setRepresentedObject:sup22];
    [sup22 setTarget:self];
    [migrateMenu addItem:sup22];
    [sup22 release];
    
    
    [migrateMenuItem setSubmenu:migrateMenu];
    [migrateMenu release];
    [menu addItem:migrateMenuItem];
    [migrateMenuItem release];
    
    NSMenuItem *fixProject = [[NSMenuItem alloc] initWithTitle:Z_SUP_FIX_PROJECT action:@selector(fixImports) keyEquivalent:@""];
    [fixProject setTarget:self];
    [menu addItem:fixProject];
    [fixProject release];
    
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:@"Z_SUP Settings..." action:@selector(showSettings) keyEquivalent:@""];
    [item2 setTarget:self];
    [menu addItem:item2];
    [item2 release];
    // add the newly created menu to the main menu bar
    NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:Z_SUP_MENU_TITLE action:NULL keyEquivalent:@""];
    [newMenuItem setSubmenu:menu];
    [menu release];
    [mainMenu addItem:newMenuItem];
    [newMenuItem release];
    
    item2 = [[NSMenuItem alloc] initWithTitle:Z_SUP_CHECK_UPDATES action:@selector(performUpdate) keyEquivalent:@""];
    [item2 setTarget:self];
    [menu addItem:item2];
    [item2 release];
    
}

- (id)init
{
    if (self = [super init]) {
        [self initMenu];
    }
    return self;
}

- (void)menuWillOpen:(NSMenu *)menu {
    if ([menu.title isEqualToString:Z_SUP_MENU_TITLE]) {
        [menu setAutoenablesItems:NO];
        ProjectAPI *api = [self getProjectAPI];
        BOOL enabled = api && [[[[NSApp mainWindow].representedFilename componentsSeparatedByString:@"/"] lastObject] rangeOfString:@".xcodeproj" options:NSCaseInsensitiveSearch].location != NSNotFound && api.SUPVersion;
        for (NSMenuItem *menuItem in menu.itemArray) {
            [menuItem setEnabled:enabled];
            if ([menuItem.title isEqualToString:Z_SUP_MIGRATE_TITLE]) {
                for (NSMenuItem *migrateChildItem in menuItem.submenu.itemArray) {
                    NSString *version = [self _getSUPVersionFromMenuItem:migrateChildItem];
                    if ([version isEqualToString:api.SUPVersion]) {
                        [migrateChildItem setState:NSOnState];
                    } else {
                        [migrateChildItem setState:NSOffState];
                    }
                }
            }
            if ([menuItem.title isEqualToString:Z_SUP_CHECK_UPDATES]) {
                [menuItem setEnabled:YES];
            }
            if ([menuItem.title isEqualToString:Z_SUP_FIX_PROJECT] && [self _getProjectPath].length) {
                [menuItem setEnabled:YES];
            }
            
        }        
    }
}

- (void)performUpdate {
    [[UpdateManager getInstance] checkForUpdatesWithCompletionBlock:^(NSInteger ret) {
        if (ret > 0) {
            [[UpdateManager getInstance] showUpdateWindow];
        } else if (ret == 0) {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert setMessageText:@"Nothing to update!"];
            [alert setInformativeText:@"You are running the latest Z_SUP version!"];
            [alert runModal];
        } else {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert setMessageText:@"Unable to connect to update server!"];
            [alert setInformativeText:@"zsup.mobi is not reachable or down. Please check your network or try again later!"];
            [alert runModal];
        }
    }];
    
}


- (void)fixImports {
    if (![[self getProjectAPI] SUPVersion]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:@"Wrong credentials!"];
        [alert setInformativeText:@"Please go to Z_SUP->Z_SUP Settings and update login credentials appropriately"];
        [alert runModal];
    }
    [[self getProjectAPI] fixImports];
}

- (void)migrateMenuItemSelected:(id)sender {
    NSMenuItem *menuItem = [sender representedObject];
    NSString *newVersion = [self _getSUPVersionFromMenuItem:menuItem];
    [[self getProjectAPI] migrateToSUPVersion:newVersion];
//    [self getGeneratedCode];
}

- (void)getGeneratedCodeRequestFailed:(ASIHTTPRequest*)req {
    if (req.responseStatusCode == 401) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:@"Wrong credentials!"];
        [alert setInformativeText:@"Please go to Z_SUP->Z_SUP Settings and update login credentials appropriately"];
        [alert runModal];        
    }
}

- (void)getGeneratedCode {
    ProjectAPI *api = [self getProjectAPI];
    SettingsBundle *bundle = [self getSettingBundle];
    ASIFormDataRequest *req = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://zsup.mobi/get"]];
    req.validatesSecureCertificate = NO;
    [req setPostValue:bundle.username forKey:@"email"];
    [req setPostValue:bundle.projectName forKey:@"project"];
    [req setPostValue:bundle.password forKey:@"password"];
    [req setPostValue:api.SUPVersion forKey:@"version"];
    req.delegate = self;
    [req setDidFailSelector:@selector(getGeneratedCodeRequestFailed:)];
    req.completionBlock = ^{
        if (req.responseData.length) {
            NSString *zsupDir = [NSHomeDirectory() stringByAppendingPathComponent:@".zsup"];
            if (![[NSFileManager defaultManager] fileExistsAtPath:zsupDir])
                [[NSFileManager defaultManager] createDirectoryAtPath:zsupDir withIntermediateDirectories:NO attributes:nil error:nil];
            NSString *archivePath = [zsupDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", bundle.projectName]];
            [req.responseData writeToFile:archivePath atomically:YES];
            [api updateGeneratedCodeFromArchive:archivePath];
            [[NSFileManager defaultManager] removeItemAtPath:archivePath error:nil];
        } else {
            [self showSettingsWithBundle:bundle andError:@"Project files not found! Upload files from Sybase Unwired Workspace or change project name accordingly!"];
        }
    };
    [req startAsynchronous];
}

- (void)showSettings {
    NSString *projectPath = [NSApp mainWindow].representedFilename;
    [self showSettingsWithBundle:[SettingsBundle getInstanceForProjectPath:projectPath ] andError:nil];
}

- (void)updateSettings:(NSNotification*)notif {
    
    SettingWindowController *swc = [notif.object windowController];
    SettingsBundle *bundle = [SettingsBundle getInstanceForProjectPath:swc.projectPath];
    bundle.username = swc.username.stringValue;
    bundle.password = swc.password.stringValue;
    bundle.projectName = swc.projectName.stringValue;
    [bundle updateSettings];
}

- (void)showSettingsWithBundle:(SettingsBundle*)bundle andError:(NSString*)error{
    NSString *projectPath = [NSApp mainWindow].representedFilename;
    if (!globalSettingWindowController)
        globalSettingWindowController = [[SettingWindowController alloc] initWithWindowNibName:@"SettingWindowController"];
        
    globalSettingWindowController.projectPath = projectPath;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSettings:) name:NSWindowWillCloseNotification object:globalSettingWindowController.window];
    globalSettingWindowController.username.stringValue = bundle.username;
    globalSettingWindowController.password.stringValue = bundle.password;
    globalSettingWindowController.projectName.stringValue = bundle.projectName;
    if (error) {
        globalSettingWindowController.error.stringValue = error;
        [globalSettingWindowController.header setHidden:YES];
    } else {
        globalSettingWindowController.error.stringValue = @"";
        [globalSettingWindowController.header setHidden:NO];
    }
    [globalSettingWindowController showWindow:[NSApp mainWindow]];
}

- (void)dealloc
{
    [super dealloc];
}

@end
