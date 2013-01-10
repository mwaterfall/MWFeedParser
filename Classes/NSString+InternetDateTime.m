//
//  NSString+InternetDateTime.m
//
//  Copyright (c) 2013 xolaware.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of this
//	software and associated documentation files (the "Software"), to deal in the Software
//	without restriction, including without limitation the rights to use, copy, modify, merge,
//	publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//	to whom the Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all copies or
//	substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
//	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
//	FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//	OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//	DEALINGS IN THE SOFTWARE.

// source derived from https://github.com/mwaterfall/MWFeedParser .  MIT based copyright chain:
//
//	Copyright (c) 2010 Michael Waterfall
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of this
//	software and associated documentation files (the "Software"), to deal in the Software
//	without restriction, including without limitation the rights to use, copy, modify, merge,
//	publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//	to whom the Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all copies or
//	substantial portions of the Software.
//
//	This Software cannot be used to archive or collect data such as (but not limited to) that
//	of events, news, experiences and activities, for the purpose of any concept relating to
//	diary/journal keeping.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
//	PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
//	FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//	OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//	DEALINGS IN THE SOFTWARE.

#import "NSString+InternetDateTime.h"
#import "NSDateFormatter+InternetDateTime.h"

@implementation NSString (InternetDateTime)

- (NSString*)readableMediumLocalizedDateString {
	return [NSDateFormatter localizedStringFromDate:[self dateFromRFC3339String]
										  dateStyle:NSDateFormatterMediumStyle
										  timeStyle:NSDateFormatterNoStyle];
}

// See http://www.faqs.org/rfcs/rfc822.html
- (NSDate *)dateFromRFC822String {
    NSDate *date = nil;
	NSDateFormatter *dateFormatter = [NSDateFormatter internetDateTimeFormatter];
	@synchronized(dateFormatter) {

		// Process
		NSString *RFC822String = [self uppercaseString];
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
		if (!date) NSLog(@"Could not parse RFC822 date: \"%@\" Possible invalid format.", self);

	}
    return date;
}

// See http://www.faqs.org/rfcs/rfc3339.html
- (NSDate *)dateFromRFC3339String {
    NSDate *date = nil;

	NSDateFormatter *dateFormatter = [NSDateFormatter internetDateTimeFormatter];
	@synchronized(dateFormatter) {

		// Process date
		NSString *RFC3339String = [self uppercaseString];
		RFC3339String
		  = [RFC3339String stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
		// Remove colon in timezone as it breaks NSDateFormatter in iOS 4+.
		// - see https://devforums.apple.com/thread/45837
		NSRange range = NSMakeRange(20, RFC3339String.length-20);
		if (RFC3339String.length > 20) {
			RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@":"
																	 withString:@""
																		options:0
																		  range:range];
		}
		// 1996-12-19T16:39:57-0800
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"];
		date = [dateFormatter dateFromString:RFC3339String];

		if (!date) { // 1937-01-01T12:00:27.87+0020
			[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"];
			date = [dateFormatter dateFromString:RFC3339String];
		}
		if (!date) { // 1937-01-01T12:00:27
			[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
			date = [dateFormatter dateFromString:RFC3339String];
		}
		if (!date) NSLog(@"Could not parse RFC3339 date: \"%@\" Possible invalid format.", self);

	}

	return date;
}

@end
