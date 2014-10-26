//
//  TodayViewController.h
//  BeardedSpiceToday
//
//  Created by Jayson Rhynas on 2014-10-25.
//  Copyright (c) 2014 Tyler Rhodes / Jose Falcon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Chrome.h"
#import "Safari.h"
#import "Tab.h"
#import "MediaStrategyRegistry.h"

@interface TodayViewController : NSViewController {
    ChromeApplication *chromeApp;
    ChromeApplication *canaryApp;
    
    SafariApplication *safariApp;
    
    id <Tab> activeTab;
    MediaStrategyRegistry *mediaStrategyRegistry;
}

@end
