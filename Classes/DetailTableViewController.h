//
//  DetailTableViewController.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 29/06/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWFeedItem.h"

@interface DetailTableViewController : UITableViewController {
	MWFeedItem *item;
	NSString *dateString, *summaryString;
}

@property (nonatomic, retain) MWFeedItem *item;
@property (nonatomic, retain) NSString *dateString, *summaryString;

@end
