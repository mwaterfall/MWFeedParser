//
//  RootViewController.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 07/05/2010.
//  Copyright Michael Waterfall 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWFeedParser.h"

@interface RootViewController : UITableViewController <MWFeedParserDelegate> {
	MWFeedParser *feedParser;
	NSMutableArray *items;
	NSDateFormatter *formatter;
}

@end
