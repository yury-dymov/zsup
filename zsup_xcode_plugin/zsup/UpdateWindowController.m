//
//  UpdateWindowController.m
//  httpstest
//
//  Created by Dymov, Yuri on 13.06.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "UpdateWindowController.h"
#import "ASIProgressDelegate.h"
#import "ASIFormDataRequest.h"
#import "UpdateElem.h"

#define UPDATE_WINDOW_CONTROLLER_UpdateTitle @"Update!"
#define UPDATE_WINDOW_CONTROLLER_StopTitle @"Stop"


@interface UpdateWindowController ()

@end

@implementation UpdateWindowController
@synthesize delegate;
@synthesize progressIndicator = progressIndicator_;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)removeAllSubviews {
    while ([self.window.contentView subviews].count)
        [[[self.window.contentView subviews] objectAtIndex:0] removeFromSuperview];
}

- (void)done {
    [self removeAllSubviews];
    NSTextField *doneLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0f, self.window.frame.size.height / 2 - 10.0f, self.window.frame.size.width, 20.0f)];
    doneLabel.stringValue = @"Update is done!";
    doneLabel.backgroundColor = [NSColor clearColor];
    doneLabel.alignment = NSCenterTextAlignment;
    [doneLabel setBezeled:NO];
    [doneLabel setSelectable:NO];
    [self.window.contentView addSubview:doneLabel];
    [doneLabel release];
    updateButton = nil;
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    [self.progressIndicator incrementBy:bytes * 100 / totalDownloadSize];
    if (self.progressIndicator.doubleValue >= 99.0f)
        [self.progressIndicator setIndeterminate:YES];
    [self.progressIndicator displayIfNeeded];
}

- (void)makeWindow {
    CGFloat hoffset = 100.0f;
    CGFloat wheight = [NSScreen mainScreen].frame.size.height;
    CGFloat width = 600.0f;
    CGFloat height = 400.0f;
    CGFloat woffset = ([NSScreen mainScreen].frame.size.width - width) / 2;
    [self.window setFrame:NSMakeRect(woffset, wheight - hoffset - height, width, height) display:YES];
}

- (void)showUpdateRequired:(NSArray *)remoteFiles oldVersions:(NSArray*)oldFiles {
    if ([updateButton.title isEqualToString:UPDATE_WINDOW_CONTROLLER_StopTitle])
        return;
    [self makeWindow];
    [self removeAllSubviews];
    if (remoteFiles.count) {
        CGFloat verWidth = 150.0f;
        CGFloat fieldHeight = 20.0f;
        CGFloat headerYOffset = self.window.frame.size.height - 2*fieldHeight;

        CGFloat descFieldWidth = self.window.frame.size.width - 2 * verWidth;
        NSTextField *descField = [[NSTextField alloc] initWithFrame:NSRectFromCGRect(CGRectMake(1.0f, headerYOffset, descFieldWidth, fieldHeight))];
        [descField setEditable:NO];
        descField.backgroundColor = [NSColor clearColor];
        [descField setAlignment:NSCenterTextAlignment];
        descField.stringValue = @"Component Description";
        [self.window.contentView addSubview:descField];
        [descField release];
        
        NSTextField *oldVersionField = [[NSTextField alloc] initWithFrame:NSRectFromCGRect(CGRectMake(1.0f + descFieldWidth, headerYOffset, verWidth, fieldHeight))];
        [oldVersionField setEditable:NO];
        oldVersionField.backgroundColor = [NSColor clearColor];
        [oldVersionField setAlignment:NSCenterTextAlignment];
        oldVersionField.stringValue = @"Installed Version";
        [self.window.contentView addSubview:oldVersionField];
        [oldVersionField release];
        
        NSTextField *newVersionField = [[NSTextField alloc] initWithFrame:NSRectFromCGRect(CGRectMake(1.0f + descFieldWidth + verWidth, headerYOffset, verWidth, fieldHeight))];
        [newVersionField setEditable:NO];
        newVersionField.backgroundColor = [NSColor clearColor];
        [newVersionField setAlignment:NSCenterTextAlignment];
        newVersionField.stringValue = @"Available Version";
        [self.window.contentView addSubview:newVersionField];
        [newVersionField release];
        
        NSInteger cnt = 0;
        totalDownloadSize = 0;
        for (UpdateElem *elem in remoteFiles) {
            ++cnt;
            NSString *title = elem.desc;
            if ([title isKindOfClass:[NSNull class]])
                title = [[elem.fileName componentsSeparatedByString:@"."] objectAtIndex:0];
            
            NSTextField *descLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0f, headerYOffset - fieldHeight * cnt - 5.0f, descFieldWidth, fieldHeight)];
            descLabel.stringValue = title;
            [descLabel setBezeled:NO];
            if (cnt % 2 == 0) {
                descLabel.backgroundColor = [NSColor whiteColor];
            } else {
                descLabel.backgroundColor = [NSColor clearColor];
            }
            [descLabel setEditable:NO];
            [descLabel setSelectable:NO];
            [descLabel setStringValue:title];
            [self.window.contentView addSubview:descLabel];
            [descLabel release];
            
            NSTextField *oldVersionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(descFieldWidth, descLabel.frame.origin.y, verWidth, fieldHeight)];
            oldVersionLabel.stringValue = @"Not installed";
            if ([oldFiles count]) {
                UpdateElem *oldElem = [oldFiles objectAtIndex:cnt - 1];
                oldVersionLabel.stringValue = oldElem.fileVersion;
            }
            if (cnt % 2 == 0) {
                oldVersionLabel.backgroundColor = [NSColor whiteColor];
            } else {
                oldVersionLabel.backgroundColor = [NSColor clearColor];
            }
            [oldVersionLabel setAlignment:NSCenterTextAlignment];
            [oldVersionLabel setBezeled:NO];
            [oldVersionLabel setSelectable:NO];
            [self.window.contentView addSubview:oldVersionLabel];
            [oldVersionLabel release];
            
            NSTextField *newVersionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(descFieldWidth + verWidth, descLabel.frame.origin.y, verWidth, fieldHeight)];
            newVersionLabel.stringValue = elem.fileVersion;            
            if (cnt % 2 == 0) {
                newVersionLabel.backgroundColor = [NSColor whiteColor];
            } else {
                newVersionLabel.backgroundColor = [NSColor clearColor];
            }
            [newVersionLabel setAlignment:NSCenterTextAlignment];
            [newVersionLabel setBezeled:NO];
            [newVersionLabel setSelectable:NO];
            [self.window.contentView addSubview:newVersionLabel];
            [newVersionLabel release];
            totalDownloadSize += [elem.fileSize intValue];
        }
        [totalDownloadSizeLabel release];
        totalDownloadSizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0f, headerYOffset - 5.0f - fieldHeight * (cnt + 2), descFieldWidth, fieldHeight)];
        totalDownloadSizeLabel.stringValue = [NSString stringWithFormat:@"Estimated download size: %.2f Mb", totalDownloadSize * 1.0f / 1024 / 1024];
        totalDownloadSizeLabel.backgroundColor = [NSColor clearColor];
        totalDownloadSizeLabel.tag = 1;
        [totalDownloadSizeLabel setBezeled:NO];
        [totalDownloadSizeLabel setSelectable:NO];
        [self.window.contentView addSubview:totalDownloadSizeLabel];

        updateButton = [[NSButton alloc] initWithFrame:NSRectFromCGRect(CGRectMake(descFieldWidth + verWidth / 2, totalDownloadSizeLabel.frame.origin.y - 14.0f, verWidth, 44.0f))];
        [updateButton setTarget:self];
        [updateButton setAction:@selector(buttonPressed:)];
        [updateButton setTitle:@"Update!"];
        [self.window.contentView addSubview:updateButton];
        [updateButton release];
        
        CGFloat delta = - totalDownloadSizeLabel.frame.origin.y - totalDownloadSizeLabel.frame.size.height - 30.0f + self.window.frame.size.height;
        [self.window setFrame:NSRectFromCGRect(CGRectMake(self.window.frame.origin.x, self.window.frame.origin.y + delta * 2, self.window.frame.size.width, self.window.frame.size.height - delta)) display:YES];
        for (NSView *subview in [self.window.contentView subviews]) {
            subview.frame = NSRectFromCGRect(CGRectMake(subview.frame.origin.x, subview.frame.origin.y - delta, subview.frame.size.width, subview.frame.size.height));
        }
        
    } else {
        
    }
}

- (void)buttonPressed:(id)sender {
    NSButton *btn = sender;
    if ([btn.title isEqualToString:UPDATE_WINDOW_CONTROLLER_UpdateTitle]) {
        btn.title = UPDATE_WINDOW_CONTROLLER_StopTitle;
        [progressIndicator_ release];
        progressIndicator_ = [[NSProgressIndicator alloc] initWithFrame:totalDownloadSizeLabel.frame];
        [self.progressIndicator setMinValue:0.0f];
        [self.progressIndicator setMaxValue:100.0f];
        [self.progressIndicator setDoubleValue:1.0f];
        [self.progressIndicator setIndeterminate:NO];
        [self.progressIndicator startAnimation:self];
        [self.window.contentView addSubview:self.progressIndicator];
        [totalDownloadSizeLabel removeFromSuperview];        
        [self.delegate performUpdate];
    } else {
        btn.title = UPDATE_WINDOW_CONTROLLER_UpdateTitle;
        [self.progressIndicator removeFromSuperview];
        [self.window.contentView addSubview:totalDownloadSizeLabel];
        [self.delegate cancelUpdate];
    }
    
}

//CGFloat newheight = 600.0f;
//[self.updateWindowController.window setFrame:CGRectMake(self.updateWindowController.window.frame.origin.x, wheight - newheight - hoffset, self.updateWindowController.window.frame.size.width, newheight) display:YES];
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
