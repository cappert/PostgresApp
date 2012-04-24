//
//  AppDelegate.m
//  PostgreSQL
//
//  Created by Mattt Thompson on 12/04/04.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import "AppDelegate.h"
#import "PostgresServer.h"
#import "PostgresStatusMenuItemViewController.h"

static NSString * const kPostgresAppWebsiteURLString = @"http://postgresapp.com/";

static NSString * const kPostgresAutomaticallyOpenDocumentationPreferenceKey = @"com.heroku.postgres.preference.open-documentation-at-start";
static BOOL PostgresIsHelperApplicationSetAsLoginItem() {
    NSArray *jobs = (__bridge NSArray *)SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    for (NSDictionary *job in jobs) {
        if ([[job valueForKey:@"Label"] isEqualToString:@"com.heroku.PostgresHelper"]) {
            return YES;
        }
    }
    
    return NO;
}

static NSUInteger kPostgresAppDefaultPort = 5432;

@implementation AppDelegate {
    __strong NSStatusItem *_statusBarItem;
}
@synthesize postgresStatusMenuItemViewController = _postgresStatusMenuItemViewController;
@synthesize statusBarMenu = _statusBarMenu;
@synthesize postgresStatusMenuItem = _postgresStatusMenuItem;
@synthesize automaticallyOpenDocumentationMenuItem = _automaticallyOpenDocumentationMenuItem;
@synthesize automaticallyStartMenuItem = _automaticallyStartMenuItem;

- (void)awakeFromNib {
    _statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    _statusBarItem.highlightMode = YES;
    _statusBarItem.menu = self.statusBarMenu;
    _statusBarItem.image = [NSImage imageNamed:@"pg-elephant-status-item"];
    
    [self.postgresStatusMenuItem setEnabled:NO];    
    self.postgresStatusMenuItem.view = self.postgresStatusMenuItemViewController.view;
    [self.postgresStatusMenuItemViewController startAnimatingWithTitle:NSLocalizedString(@"Postgres: Starting Up", nil)];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kPostgresAutomaticallyOpenDocumentationPreferenceKey]];
    [self.automaticallyOpenDocumentationMenuItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:kPostgresAutomaticallyOpenDocumentationPreferenceKey]];
    [self.automaticallyStartMenuItem setState:PostgresIsHelperApplicationSetAsLoginItem() ? NSOnState : NSOffState];
    
    [[PostgresServer sharedServer] startOnPort:kPostgresAppDefaultPort completionBlock:^{
        [self.postgresStatusMenuItemViewController stopAnimatingWithTitle:NSLocalizedString(@"Postgres: Running on Port 5432", nil) wasSuccessful:YES];
    }]; 
        
    [NSApp activateIgnoringOtherApps:YES];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPostgresAutomaticallyOpenDocumentationPreferenceKey]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kPostgresAppWebsiteURLString]];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {    
    // TODO: Use termination handlers instead of delay 
    [[PostgresServer sharedServer] stop];
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [sender replyToApplicationShouldTerminate:YES];
    });
    
    return NSTerminateLater;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"applicationWillTerminate");
}

#pragma mark - IBAction

- (IBAction)selectPostgresStatus:(id)sender {
    
}

- (IBAction)selectAbout:(id)sender {
    [NSApp orderFrontStandardAboutPanel:nil];
}

- (IBAction)selectDocumentation:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kPostgresAppWebsiteURLString]];
}

- (IBAction)selectAutomaticallyOpenDocumentation:(id)sender {
    [self.automaticallyOpenDocumentationMenuItem setState:![self.automaticallyOpenDocumentationMenuItem state]];

    [[NSUserDefaults standardUserDefaults] setBool:self.automaticallyOpenDocumentationMenuItem.state == NSOnState forKey:kPostgresAutomaticallyOpenDocumentationPreferenceKey];
}

- (IBAction)selectAutomaticallyStart:(id)sender {
    [self.automaticallyStartMenuItem setState:![self.automaticallyStartMenuItem state]];
    
    NSURL *helperApplicationURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/PostgresHelper.app"];
    NSLog(@"Helper Application URL: %@", helperApplicationURL);
    if (LSRegisterURL((__bridge CFURLRef)helperApplicationURL, true) != noErr) {
        NSLog(@"LSRegisterURL Failed");
    }
    
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)@"com.heroku.PostgresHelper", [self.automaticallyStartMenuItem state] == NSOnState)) {
        NSLog(@"SMLoginItemSetEnabled Failed");
    }
}

@end