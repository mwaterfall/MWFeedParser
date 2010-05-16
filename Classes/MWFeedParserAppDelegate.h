//
//  MWFeedParserAppDelegate.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 15/05/2010.
//  Copyright d3i 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MWFeedParserAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

