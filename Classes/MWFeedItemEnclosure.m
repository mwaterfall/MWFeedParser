//
//  MWFeedItemEnclosure.m
//  MWFeedParser
//
//  Copyright (c) 2010 Michael Waterfall
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  1. The above copyright notice and this permission notice shall be included
//     in all copies or substantial portions of the Software.
//  
//  2. This Software cannot be used to archive or collect data such as (but not
//     limited to) that of events, news, experiences and activities, for the 
//     purpose of any concept relating to diary/journal keeping.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "MWFeedItemEnclosure.h"

@implementation MWFeedItemEnclosure

@synthesize url, type, length;

#pragma mark NSObject

- (NSString *)description {
	NSMutableString *string = [[NSMutableString alloc] initWithFormat:@"%@: ", NSStringFromClass([self class])];
	if (url)   [string appendFormat:@"“%@”", url];
	if (type)    [string appendFormat:@" (%@)", type];
	if (length)    [string appendFormat:@" %i bytes", length];
	return [string autorelease];
}

- (void)dealloc {
	[url release];
	[type release];
	[super dealloc];
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
		url = [[decoder decodeObjectForKey:@"url"] retain];
		type = [[decoder decodeObjectForKey:@"type"] retain];
		length = [decoder decodeIntegerForKey:@"length"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	if (url) [encoder encodeObject:url forKey:@"url"];
	if (type) [encoder encodeObject:type forKey:@"type"];
	if (length) [encoder encodeInteger:length forKey:@"length"];
}

@end