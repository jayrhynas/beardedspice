//
//  TodayViewController.m
//  BeardedSpiceToday
//
//  Created by Jayson Rhynas on 2014-10-25.
//  Copyright (c) 2014 Tyler Rhodes / Jose Falcon. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#import "MediaStrategyRegistry.h"
#import "ChromeTabAdapter.h"
#import "SafariTabAdapter.h"

@interface TodayViewController () <NCWidgetProviding>
@property (weak) IBOutlet NSImageView *artworkView;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTextField *subtitleLabel;

@property (weak) IBOutlet NSProgressIndicator *progressBar;

@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSButton *prevButton;
@property (weak) IBOutlet NSButton *nextButton;

@end

@implementation TodayViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        mediaStrategyRegistry = [MediaStrategyRegistry getDefaultRegistry];
    }
    return self;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    id<Tab> prevActiveTab = activeTab;
    
    [self refreshActiveTab];
    
    NCUpdateResult updateResult = NCUpdateResultNoData;
    
    if (![activeTab isEqual:prevActiveTab]) {
        [self updateInterface];
        updateResult = NCUpdateResultNewData;
    }
    
    completionHandler(updateResult);
}

- (IBAction)playClicked:(id)sender
{
    if (activeTab) {
        MediaStrategy *strategy = [mediaStrategyRegistry getMediaStrategyForTab:activeTab];
        [activeTab executeJavascript:[strategy toggle]];
    }
}

- (IBAction)prevClicked:(id)sender
{
    if (activeTab) {
        MediaStrategy *strategy = [mediaStrategyRegistry getMediaStrategyForTab:activeTab];
        [activeTab executeJavascript:[strategy previous]];
    }
}

- (IBAction)nextClicked:(id)sender
{
    if (activeTab) {
        MediaStrategy *strategy = [mediaStrategyRegistry getMediaStrategyForTab:activeTab];
        [activeTab executeJavascript:[strategy next]];
    }
}

- (void)updateInterface
{
    if (activeTab) {
        MediaStrategy *strategy = [mediaStrategyRegistry getMediaStrategyForTab:activeTab];
        
        Track *trackInfo = [strategy trackInfo:activeTab];
        
        if (trackInfo) {
            self.titleLabel.stringValue    = trackInfo.track;
            self.subtitleLabel.stringValue = [NSString stringWithFormat:@"%@ - %@", trackInfo.artist, trackInfo.album];
        } else {
            self.titleLabel.stringValue    = @"";
            self.subtitleLabel.stringValue = @"";
        }
        
        self.playButton.enabled = YES;
        self.prevButton.enabled = YES;
        self.nextButton.enabled = YES;
    } else {
        self.titleLabel.stringValue    = @"";
        self.subtitleLabel.stringValue = @"";

        self.playButton.enabled = NO;
        self.prevButton.enabled = NO;
        self.nextButton.enabled = NO;
    }
    
//    [[NCWidgetController widgetController] setHasContent:(activeTab != nil)
//                           forWidgetWithBundleIdentifier:@"com.beardedspice.BeardedSpice.BeardedSpiceToday"];
    
}

- (id<Tab>)findTabWithKey:(NSString *)key inChrome:(ChromeApplication *)chrome
{
    if (chrome) {
        for (ChromeWindow *chromeWindow in chrome.windows) {
            for (ChromeTab *chromeTab in chromeWindow.tabs) {
                id<Tab> tab = [ChromeTabAdapter initWithTab:chromeTab andWindow:chromeWindow];
                if ([key isEqualToString:[tab key]]) {
                    return tab;
                }
            }
        }
    }
    return nil;
}

- (id<Tab>)findTabWithKey:(NSString *)key inSafari:(SafariApplication *)safari
{
    if (safari) {
        for (SafariWindow *safariWindow in safari.windows) {
            for (SafariTab *safariTab in safariWindow.tabs) {
                id<Tab> tab = [SafariTabAdapter initWithApplication:safari andWindow:safariWindow andTab:safariTab];
                if ([key isEqualToString:[tab key]]) {
                    return tab;
                }
            }
        }
    }
    return nil;
}

- (void)refreshActiveTab
{
    activeTab = nil;
    
    NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.beardedspice.beardedspice"];
    NSString *activeTabKey = [sharedUserDefaults stringForKey:@"activeTabKey"];
    
    if (!activeTabKey) {
        return;
    }
    
    [self refreshApplications];
    
    if ([activeTabKey hasPrefix:@"C"]) {
        activeTab = [self findTabWithKey:activeTabKey inChrome:chromeApp];
        
        // TODO: handle canary better than just a fallback
        // (need to make tab key different between chrome/canary)
        if (!activeTab) {
            activeTab = [self findTabWithKey:activeTabKey inChrome:canaryApp];
        }
    } else if ([activeTabKey hasPrefix:@"S"]) {
        activeTab = [self findTabWithKey:activeTabKey inSafari:safariApp];
    }
    
    [self updateInterface];
}

- (void)refreshApplications
{
    chromeApp = (ChromeApplication *)[self getRunningSBApplicationWithIdentifier:@"com.google.Chrome"];
    canaryApp = (ChromeApplication *)[self getRunningSBApplicationWithIdentifier:@"com.google.Chrome.canary"];
    safariApp = (SafariApplication *)[self getRunningSBApplicationWithIdentifier:@"com.apple.Safari"];
}

-(SBApplication *)getRunningSBApplicationWithIdentifier:(NSString *)bundleIdentifier
{
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
    if ([apps count] > 0) {
        NSRunningApplication *app = [apps objectAtIndex:0];
        NSLog(@"App %@ is running %@", bundleIdentifier, app);
        return [SBApplication applicationWithProcessIdentifier:[app processIdentifier]];
    }
    return NULL;
}

@end

