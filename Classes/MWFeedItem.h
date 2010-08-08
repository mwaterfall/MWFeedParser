//
//  MWFeedItem.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 10/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWFeedItem : NSObject <NSCoding> {
	
	NSString *title; // Item title
	NSString *link; // Item URL
	NSDate *date; // Date the item was published
	NSDate *updated; // Date the item was updated if available
	NSString *summary; // Description of item
	NSString *content; // More detailed content (if available)
	
	// Enclosures: Holds 1 or more item enclosures (i.e. podcasts, mp3. pdf, etc)
	//  - NSArray of NSDictionaries with the following keys:
	//     url: where the enclosure is located (NSString)
	//     length: how big it is in bytes (NSNumber)
	//     type: what its type is, a standard MIME type  (NSString)
	NSArray *enclosures;

}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSDate *updated;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSArray *enclosures;

@end
