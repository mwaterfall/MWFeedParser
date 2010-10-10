//
//  NSDate+InternetDateTime.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 07/10/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import "NSDate+InternetDateTime.h"

@implementation NSDate (InternetDateTime)

// Good info on internet dates here: http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html

// Get a date from a string - hit (from specs) can be used to speed up
+ (NSDate *)dateFromInternetDateTimeString:(NSString *)dateString formatHint:(DateFormatHint)hint {
	NSDate *date = nil;
	if (hint != DateFormatHintRFC3339) {
		// Try RFC822 first
		date = [NSDate dateFromRFC822String:dateString];
		if (!date) date = [NSDate dateFromRFC3339String:dateString];
	} else {
		// Try RFC3339 first
		date = [NSDate dateFromRFC3339String:dateString];
		if (!date) date = [NSDate dateFromRFC822String:dateString];
	}
	return date;
}

// See http://www.faqs.org/rfcs/rfc822.html
+ (NSDate *)dateFromRFC822String:(NSString *)dateString {

	// Create date formatter
	static NSDateFormatter *dateFormatter = nil;
	if (!dateFormatter) {
		NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLocale:en_US_POSIX];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[en_US_POSIX release];
	}

	// Process
	NSDate *date = nil;
	NSString *RFC822String = [[NSString stringWithString:dateString] uppercaseString];
	if ([RFC822String rangeOfString:@","].location != NSNotFound) {
		if (!date) { // Sun, 19 May 2002 15:21:36 GMT
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		if (!date) { // Sun, 19 May 2002 15:21 GMT
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		if (!date) { // Sun, 19 May 2002 15:21:36
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		if (!date) { // Sun, 19 May 2002 15:21
			[dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
	} else {
		if (!date) { // 19 May 2002 15:21:36 GMT
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		if (!date) { // 19 May 2002 15:21 GMT
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm zzz"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		if (!date) { // 19 May 2002 15:21:36
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm:ss"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
		if (!date) { // 19 May 2002 15:21
			[dateFormatter setDateFormat:@"d MMM yyyy HH:mm"]; 
			date = [dateFormatter dateFromString:RFC822String];
		}
	}
	if (!date) NSLog(@"Could not parse RFC822 date: \"%@\" Possibly invalid format.", dateString);
	return date;
	
}

// See http://www.faqs.org/rfcs/rfc3339.html
+ (NSDate *)dateFromRFC3339String:(NSString *)dateString {
	
	// Create date formatter
	static NSDateFormatter *dateFormatter = nil;
	if (!dateFormatter) {
		NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setLocale:en_US_POSIX];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[en_US_POSIX release];
	}
	
	// Process date
	NSDate *date = nil;
	NSString *RFC3339String = [[NSString stringWithString:dateString] uppercaseString];
	RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
	// Remove colon in timezone as iOS 4+ NSDateFormatter breaks. See https://devforums.apple.com/thread/45837
	if (RFC3339String.length > 20) {
		RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@":" 
																 withString:@"" 
																	options:0
																	  range:NSMakeRange(20, RFC3339String.length-20)];
	}
	if (!date) { // 1996-12-19T16:39:57-0800
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"]; 
		date = [dateFormatter dateFromString:RFC3339String];
	}
	if (!date) { // 1937-01-01T12:00:27.87+0020
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"]; 
		date = [dateFormatter dateFromString:RFC3339String];
	}
	if (!date) { // 1937-01-01T12:00:27
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"]; 
		date = [dateFormatter dateFromString:RFC3339String];
	}
	if (!date) NSLog(@"Could not parse RFC3339 date: \"%@\" Possibly invalid format.", dateString);
	return date;
	
}

@end
