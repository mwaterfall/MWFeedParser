//
//  MWFeedParserAppDelegate.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 15/05/2010.
//  Copyright Michael Waterfall 2010. All rights reserved.
//

#import "MWFeedParserAppDelegate.h"
#import "RootViewController.h"

@implementation MWFeedParserAppDelegate

@synthesize window;
@synthesize navigationController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    // Override point for customization after app launch    
	
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
	return YES;
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

