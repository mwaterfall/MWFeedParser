//
//  MWFeedInfo.m
//  XML
//
//  Created by Michael Waterfall on 10/05/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "MWFeedInfo.h"

@implementation MWFeedInfo

@synthesize title, link, summary;

- (NSString *)description {
	NSMutableString *string = [[NSMutableString alloc] initWithString:@"\nMWFeedInfo\n"];
	if (title)   [string appendFormat:@"Title:     %@\n", title];
	if (link)    [string appendFormat:@"Link:      %@\n", link];
	if (summary) [string appendFormat:@"Summary:   %@", summary];
	return [string autorelease];
}

@end
