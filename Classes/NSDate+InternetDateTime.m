//
//  NSDate+InternetDateTime.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 07/10/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import "NSDate+InternetDateTime.h"
#import "NSDateFormatter+InternetDateTime.h"
#import "NSString+InternetDateTime.h"

// Good info on internet dates here:
// http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
@implementation NSDate (InternetDateTime)

- (NSString* )rfc3339String { 
	return [[NSDateFormatter rfc3339InternetDateTimeGenerator] stringFromDate:self];
}

// Get a date from a string - hint can be used to speed up
+ (NSDate *)dateFromInternetDateTimeString:(NSString *)dateString
								formatHint:(DateFormatHint)hint {
	NSDate *date = nil;
	if (dateString) {
		if (hint != DateFormatHintRFC3339) {
			// Try RFC822 first
			date = [dateString dateFromRFC822String];
			if (!date) date = [dateString dateFromRFC3339String];
		} else {
			// Try RFC3339 first
			date = [dateString dateFromRFC3339String];
			if (!date) date = [dateString dateFromRFC822String];
		}
	}
	return date;
}

+ (NSDate *)dateFromRFC822String:(NSString *)dateString {
	return [dateString dateFromRFC822String];
}

+ (NSDate *)dateFromRFC3339String:(NSString *)dateString {
	return [dateString dateFromRFC3339String];
}

@end
