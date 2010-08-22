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
	
	// Parsing
	MWFeedParser *feedParser;
	NSMutableArray *parsedItems;
	
	// Displaying
	NSArray *itemsToDisplay;
	NSDateFormatter *formatter;
	
}

// Properties
@property (nonatomic, retain) NSArray *itemsToDisplay;

@end
