//
//  MWFeedParser.m
//  XML
//
//  Created by Michael Waterfall on 08/05/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "MWFeedParser.h"
#import "NSString+XMLEntities.h"

@implementation MWFeedParser

// Properties
@synthesize delegate, url;
@synthesize urlConnection, asyncData, connectionType;
@synthesize feedParseType, feedParser, currentPath, currentText, currentElementAttributes, item, info;

#pragma mark -
#pragma mark NSObject

- (id)initWithFeedURL:(NSString *)feedURL {
	if (self = [super init]) {
		
		// URL
		self.url = [feedURL stringByReplacingOccurrencesOfString:@"feed://" withString:@"http://"];
		
		// Defaults
		feedParseType = ParseTypeFull;
		connectionType = ConnectionTypeSynchronously;

		// Date Formatters
		NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		dateFormatterRFC822 = [[NSDateFormatter alloc] init];
		dateFormatterRFC3339 = [[NSDateFormatter alloc] init];
        [dateFormatterRFC822 setLocale:en_US_POSIX];
        [dateFormatterRFC3339 setLocale:en_US_POSIX];
        [dateFormatterRFC822 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatterRFC3339 setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[en_US_POSIX release];
		
	}
	return self;
}

- (void)dealloc {
	[urlConnection release];
	[url release];
	[feedParser release];
	[dateFormatterRFC822 release];
	[dateFormatterRFC3339 release];
	[currentPath release];
	[currentText release];
	[currentElementAttributes release];
	[item release];
	[info release];
	[super dealloc];
}

#pragma mark -
#pragma mark Parsing

// Reset data variables before processing
- (void)reset {
	self.asyncData = nil;
	self.feedParser = nil;
	self.urlConnection = nil;
	feedType = FeedTypeUnknown;
	self.currentPath = @"/";
	self.currentText = [[NSMutableString alloc] init];
	self.item = nil;
	self.info = nil;
	hasEncounteredItems = NO;
	aborted = NO;
	self.currentElementAttributes = nil;
}

// Begin downloading & parsing of feed
- (void)parse {
	
	// Checks
	if (!url || !delegate) {
	
		// Error
		return;
		
	}
	
	// Reset
	[self reset];
	
	// Request
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] 
												  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
											  timeoutInterval:180];
	[request setValue:@"MWFeedParser" forHTTPHeaderField:@"User-Agent"];
	
	// Connection
	if (connectionType == ConnectionTypeAsynchronously) {
		
		// Async
		urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		if (urlConnection) {
			
			// Create data
			asyncData = [[NSMutableData alloc] init];
			
		} else {
		
			// Error
			
			
		}
		
	} else {
	
		// Sync
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (data && !error) {
			
			// Process
			[self startParsingData:data];
			
		} else {
			
			// Error

			
		}
		
	}
	
	// Cleanup
	[request release];
	
}

// Begin XML parsing
- (void)startParsingData:(NSData *)data {
	if (data && !feedParser) {
		
		// Create feed info
		MWFeedInfo *i = [[MWFeedInfo alloc] init];
		self.info = i;
		[i release];

		// Parse!
		feedParser = [[NSXMLParser alloc] initWithData:data];
		feedParser.delegate = self;
		[feedParser parse];
		
	}
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[asyncData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[asyncData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	// Failed
	[urlConnection release];
    [asyncData release];
	
    // inform the user
    MWLog(@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// Succeed
    MWLog(@"Succeeded! Received %d bytes of data", [asyncData length]);
	[self startParsingData:asyncData];
	
    // Cleanup
    [urlConnection release];
    [asyncData autorelease];

}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil; // Don't cache
}

#pragma mark -
#pragma mark XML Parsing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	MWLog(@"XMLParser: didStartElement: %@", elementName);
	
	// Adjust path
	self.currentPath = [currentPath stringByAppendingPathComponent:elementName];
	self.currentElementAttributes = attributeDict;
	[self.currentText setString:@""];
	
	// Determine feed type
	if (feedType == FeedTypeUnknown) {
		if ([elementName isEqualToString:@"rss"]) feedType = FeedTypeRSS; 
		else if ([elementName isEqualToString:@"feed"]) feedType = FeedTypeAtom;
		return;
	}
	
	// Entering new feed element
	if (feedParseType != ParseTypeItemsOnly) { // Check whether to ignore feed info
		if ((feedType == FeedTypeRSS  && [currentPath isEqualToString:@"/rss/channel"]) ||
			(feedType == FeedTypeAtom && [currentPath isEqualToString:@"/feed"])) {
			return;
		}
	}
			
	// Entering new item element
	if ((feedType == FeedTypeRSS  && [currentPath isEqualToString:@"/rss/channel/item"]) ||
		(feedType == FeedTypeAtom && [currentPath isEqualToString:@"/feed/entry"])) {

		// Send off feed info to delegate
		if (feedParseType != ParseTypeItemsOnly) { // Check whether to ignore feed info
			if (!hasEncounteredItems) {
				
				// Inform delegate
				if ([delegate respondsToSelector:@selector(feedParser:didParseFeedInfo:)])
					[delegate feedParser:self didParseFeedInfo:[[info retain] autorelease]];
				
				// Finish
				self.info = nil;
				hasEncounteredItems = YES;
				
				// Stop parsing if only requiring meta data
				if (feedParseType == ParseTypeInfoOnly) {
					
					// Finish
					[self finishParsing];
					
				}
				
			}
		}
		
		// New item
		self.item = [[MWFeedItem alloc] init];
		return;
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	MWLog(@"XMLParser: didEndElement: %@", elementName);
	
	// Store data
	BOOL processed = NO;
	if (currentText) {
		
		// Decode entities
		//[currentText setString:[currentText stringByDecodingXMLEntities]];
		
		// Use
		switch (feedType) {
			case FeedTypeRSS: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/rss/channel/item/title"]) { if (currentText.length > 0) item.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/link"]) { if (currentText.length > 0) item.link = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/description"]) { if (currentText.length > 0) item.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/content:encoded"]) { if (currentText.length > 0) item.content = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/pubDate"]) { 
						if (currentText.length > 0) 
							item.date = [self dateFromRFC822String:currentText]; 
						processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/rss/channel/title"]) { if (currentText.length > 0) info.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/description"]) { if (currentText.length > 0) info.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/link"]) { if (currentText.length > 0) info.link = currentText; processed = YES; }
				}
				
				break;
			}
			case FeedTypeAtom: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/feed/entry/title"]) { if (currentText.length > 0) item.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/link"]) { 
						NSString *link = [self linkFromAtomLinkAttributes:currentElementAttributes];
						if (link) item.link = link;
						processed = YES;
					}
					else if ([currentPath isEqualToString:@"/feed/entry/summary"]) { if (currentText.length > 0) item.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/content"]) { if (currentText.length > 0) item.content = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/published"]) { if (currentText.length > 0) item.date = [self dateFromRFC3339String:currentText]; processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/feed/title"]) { if (currentText.length > 0) info.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/description"]) { if (currentText.length > 0) info.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/link"]) { 
						NSString *link = [self linkFromAtomLinkAttributes:currentElementAttributes];
						if (link) info.link = link;
						processed = YES;
					}
				}
				
				break;
			}
		}
	}
	
	// Adjust path
	self.currentPath = [currentPath stringByDeletingLastPathComponent];
	
	// If end of an item then tell delegate
	if (!processed) {
		if ((feedType == FeedTypeRSS && [elementName isEqualToString:@"item"]) ||
			(feedType == FeedTypeAtom && [elementName isEqualToString:@"entry"])) {
			
			// Ensure summary always contains data if available
			if (!item.summary) { item.summary = item.content; item.content = nil; }
			
			// Inform delegate
			if ([delegate respondsToSelector:@selector(feedParser:didParseFeedItem:)])
				[delegate feedParser:self didParseFeedItem:[[item retain] autorelease]];
			
			// Finish
			self.item = nil;			
			
		}
	}
	
}

- (void)parser:(NSXMLParser *)parser foundAttributeDeclarationWithName:(NSString *)attributeName forElement:(NSString *)elementName type:(NSString *)type defaultValue:(NSString *)defaultValue {
	MWLog(@"XMLParser: foundAttributeDeclarationWithName: %@", attributeName);
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	MWLog(@"XMLParser: foundCDATA: [DATA]");
	
	// Remember characters
	NSString *string = nil;
	@try {
		string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
		if (!string) string = [[NSString alloc] initWithData:CDATABlock encoding:NSISOLatin1StringEncoding];
		if (string) [currentText appendString:string];
	}
	@catch (NSException * e) {
	}
	@finally {
		[string release];
	}
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	MWLog(@"XMLParser: foundCharacters: %@", string);
	
	// Remember characters
	[currentText appendString:string];
	
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	MWLog(@"XMLParser: parseErrorOccurred: %@", parseError);
	
	// Called if failed or aborted (legally)
	if (!aborted) {
	
		// Inform delegate
		if ([delegate respondsToSelector:@selector(feedParser:didFailWithError:)])
			[delegate feedParser:self didFailWithError:parseError];
		
	}
	
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {
	MWLog(@"XMLParser: validationErrorOccurred: %@", validError);
	
	// Inform delegate
	if ([delegate respondsToSelector:@selector(feedParser:didFailWithError:)])
		[delegate feedParser:self didFailWithError:validError];
	
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	MWLog(@"XMLParser: parserDidEndDocument");
	
	// Inform delegate
	if ([delegate respondsToSelector:@selector(feedParserDidFinish:)])
		[delegate feedParserDidFinish:self];
	
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	MWLog(@"XMLParser: parserDidStartDocument");
	
	// Inform delegate
	if ([delegate respondsToSelector:@selector(feedParserDidStart:)])
		[delegate feedParserDidStart:self];
	
}

#pragma mark -
#pragma mark Misc

- (void)finishParsing {
	
	// Abort
	aborted = YES;
	[feedParser abortParsing];	
	
	// Inform delegate of finish
	if ([delegate respondsToSelector:@selector(feedParserDidFinish:)])
		[delegate feedParserDidFinish:self];
	
}

// Determine whether to use the link from atom feed (where rel is not set to "self" etc...)
- (NSString *)linkFromAtomLinkAttributes:(NSDictionary *)attributes {
	if (attributes && [attributes objectForKey:@"rel"] && [[attributes objectForKey:@"rel"] isEqualToString:@"alternate"]) {
		return [attributes objectForKey:@"href"];
	}
	return nil;
}

- (NSDate *)dateFromRFC822String:(NSString *)dateString {
	NSDate *date = nil;
	if (!date) { // Sun, 19 May 02 15:21:36 GMT
		[dateFormatterRFC822 setDateFormat:@"EEE, d MMM yy HH:mm:ss zzz"]; 
		date = [dateFormatterRFC822 dateFromString:dateString];
	}
	if (!date) { // Sun, 19 May 2002 15:21:36 GMT
		[dateFormatterRFC822 setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"]; 
		date = [dateFormatterRFC822 dateFromString:dateString];
	}
	if (!date) {  // Sun, 19 May 2002 15:21 GMT
		[dateFormatterRFC822 setDateFormat:@"EEE, d MMM yyyy HH:mm zzz"]; 
		date = [dateFormatterRFC822 dateFromString:dateString];
	}
	return date;
}

- (NSDate *)dateFromRFC3339String:(NSString *)dateString {
	NSDate *date = nil;
	dateString = [dateString stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
	if (!date) { // 1996-12-19T16:39:57-08:00
		[dateFormatterRFC3339 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"]; 
		date = [dateFormatterRFC3339 dateFromString:dateString];
	}
	if (!date) { // 1937-01-01T12:00:27.87+00:20
		[dateFormatterRFC3339 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"]; 
		date = [dateFormatterRFC3339 dateFromString:dateString];
	}
	return date;
}

@end