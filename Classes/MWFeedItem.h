//
//  MWFeedItem.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 10/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWFeedItem : NSObject {
	
	NSString *title;
	NSString *link;
	NSString *summary; // Description of item
	NSString *content; // More detailed content (if available)
	NSDate *date;

}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSDate *date;

@end
