//
//  MWFeedItem.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 10/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import "MWFeedItem.h"

#define EXCERPT(str, len) (([str length] > len) ? [[str substringToIndex:len-1] stringByAppendingString:@"…"] : str)

@implementation MWFeedItem

@synthesize title, link, date, updated, summary, content, enclosures;

#pragma mark NSObject

- (NSString *)description {
	NSMutableString *string = [[NSMutableString alloc] initWithString:@"MWFeedItem: "];
	if (title)   [string appendFormat:@"“%@”", EXCERPT(title, 50)];
	if (date)    [string appendFormat:@" - %@", date];
	//if (link)    [string appendFormat:@" (%@)", link];
	//if (summary) [string appendFormat:@", %@", EXCERPT(summary, 50)];
	return [string autorelease];
}

- (void)dealloc {
	[title release];
	[link release];
	[date release];
	[updated release];
	[summary release];
	[content release];
	[enclosures release];
	[super dealloc];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		title = [[decoder decodeObjectForKey:@"title"] retain];
		link = [[decoder decodeObjectForKey:@"link"] retain];
		date = [[decoder decodeObjectForKey:@"date"] retain];
		updated = [[decoder decodeObjectForKey:@"updated"] retain];
		summary = [[decoder decodeObjectForKey:@"summary"] retain];
		content = [[decoder decodeObjectForKey:@"content"] retain];
		enclosures = [[decoder decodeObjectForKey:@"enclosures"] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	if (title) [encoder encodeObject:title forKey:@"title"];
	if (link) [encoder encodeObject:link forKey:@"link"];
	if (date) [encoder encodeObject:date forKey:@"date"];
	if (updated) [encoder encodeObject:updated forKey:@"updated"];
	if (summary) [encoder encodeObject:summary forKey:@"summary"];
	if (content) [encoder encodeObject:content forKey:@"content"];
	if (enclosures) [encoder encodeObject:enclosures forKey:@"enclosures"];
}

@end
