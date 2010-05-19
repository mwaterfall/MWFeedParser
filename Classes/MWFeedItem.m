//
//  MWFeedItem.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 10/05/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "MWFeedItem.h"

@implementation MWFeedItem

@synthesize title, link, summary, content, date;

- (NSString *)description {
	NSMutableString *string = [[NSMutableString alloc] initWithString:@"\nMWFeedItem\n"];
	if (title)   [string appendFormat:@"Title:     %@\n", title];
	if (link)    [string appendFormat:@"Link:      %@\n", link];
	if (date)    [string appendFormat:@"Date:      %@\n", date];
	if (summary) [string appendFormat:@"Summary:   %@\n", summary];
	if (content) [string appendFormat:@"Content:   %@", content];
	return [string autorelease];
}

@end
