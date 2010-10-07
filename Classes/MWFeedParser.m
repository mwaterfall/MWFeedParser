//
//  MWFeedParser.m
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

#import "MWFeedParser.h"
#import "MWFeedParser_Private.h"
#import "NSString+HTML.h"
#import "NSDate+InternetDateTime.h"

// NSXMLParser Logging
#if 0 // Set to 1 to enable XML parsing logs
#define MWXMLLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWXMLLog(x, ...)
#endif

// Empty XHTML elements ( <!ELEMENT br EMPTY> in http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd )
#define ELEMENT_IS_EMPTY(e) ([e isEqualToString:@"br"] || [e isEqualToString:@"img"] || [e isEqualToString:@"input"] || [e isEqualToString:@"hr"] || [e isEqualToString:@"link"] || [e isEqualToString:@"base"] || [e isEqualToString:@"basefont"] || [e isEqualToString:@"frame"] || [e isEqualToString:@"meta"] || [e isEqualToString:@"area"] || [e isEqualToString:@"col"] || [e isEqualToString:@"param"])

// Implementation
@implementation MWFeedParser

// Properties
@synthesize delegate, url;
@synthesize urlConnection, asyncData, connectionType;
@synthesize feedParseType, feedParser, currentPath, currentText, currentElementAttributes, item, info;
@synthesize pathOfElementWithXHTMLType;
@synthesize stopped, failed, parsing;

#pragma mark -
#pragma mark NSObject

- (id)initWithFeedURL:(NSString *)feedURL {
	if (self = [super init]) {
		
		// URI Scheme
		// http://en.wikipedia.org/wiki/Feed:_URI_scheme
		self.url = feedURL;
		if ([url hasPrefix:@"feed://"]) self.url = [NSString stringWithFormat:@"http://%@", [url substringFromIndex:7]];
		if ([url hasPrefix:@"feed:"]) self.url = [url substringFromIndex:5];

		// Defaults
		feedParseType = ParseTypeFull;
		connectionType = ConnectionTypeSynchronously;

		// Date Formatters
		// Good info on internet dates here: http://developer.apple.com/iphone/library/qa/qa2010/qa1480.html
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
	[pathOfElementWithXHTMLType release];
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
	self.currentText = [[[NSMutableString alloc] init] autorelease];
	self.item = nil;
	self.info = nil;
	hasEncounteredItems = NO;
	aborted = NO;
	stopped = NO;
	failed = NO;
	parsingComplete = NO;
	self.currentElementAttributes = nil;
	parseStructureAsContent = NO;
	self.pathOfElementWithXHTMLType = nil;
}

// Begin downloading & parsing of feed
- (BOOL)parse {
	
	// Perform checks before parsing
	if (!url || !delegate) { [self failWithErrorCode:MWErrorCodeNotInitiated description:@"Delegate or URL not specified"]; return NO; }
	if (parsing) { [self failWithErrorCode:MWErrorCodeGeneral description:@"Cannot start parsing as parsing is already in progress"]; return NO; }
	
	// Start
	BOOL success = YES;
	parsing = YES;
	[self reset];
	
	// Request
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] 
												  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
											  timeoutInterval:180];
	[request setValue:@"MWFeedParser" forHTTPHeaderField:@"User-Agent"];
	
	// Debug Log
	MWLog(@"MWFeedParser: Connecting & downloading feed data");
	
	// Connection
	if (connectionType == ConnectionTypeAsynchronously) {
		
		// Async
		urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		if (urlConnection) {
			asyncData = [[NSMutableData alloc] init];// Create data
		} else {
			[self failWithErrorCode:MWErrorCodeConnectionFailed description:[NSString stringWithFormat:@"Asynchronous connection failed to URL: %@", url]];
			success = NO;
		}
		
	} else {
	
		// Sync
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (data && !error) {
			[self startParsingData:data]; // Process
		} else {
			[self failWithErrorCode:MWErrorCodeConnectionFailed description:[NSString stringWithFormat:@"Synchronous connection failed to URL: %@", url]];
			success = NO;
		}
		
	}
	
	// Cleanup & return
	[request release];
	return success;
	
}

// Stop parsing
- (void)stopParsing {
	
	// Stop
	stopped = YES;
	
	// Stop downloading
	[urlConnection cancel];
	self.urlConnection = nil;
	self.asyncData = nil;
	
	// Abort parsing
	aborted = YES;
	[feedParser abortParsing];
	
	// Debug Log
	MWLog(@"MWFeedParser: Parsing stopped");
	
	// Inform delegate of stop only if it hasn't already finished
	if (!parsingComplete) {
		if ([delegate respondsToSelector:@selector(feedParserDidFinish:)])
			[delegate feedParserDidFinish:self];
	}
	
}

// Abort parsing
- (void)abortParsing {
	
	// Abort
	aborted = YES;
	[feedParser abortParsing];	
	
	// Inform delegate of succesful finish
	if ([delegate respondsToSelector:@selector(feedParserDidFinish:)])
		[delegate feedParserDidFinish:self];
		
}

// Finished
- (void)parsingFinished {
	parsingComplete = YES;
	parsing = NO;
}

// Begin XML parsing
- (void)startParsingData:(NSData *)data {
	if (data && !feedParser) {
		
		// Create feed info
		MWFeedInfo *i = [[MWFeedInfo alloc] init];
		self.info = i;
		[i release];
		
		// Create NSXMLParser
		NSXMLParser *newFeedParser = [[NSXMLParser alloc] initWithData:data];
		self.feedParser = newFeedParser;
		[newFeedParser release];
		if (feedParser) { 
			
			// Parse!
			feedParser.delegate = self;
			[feedParser setShouldProcessNamespaces:YES];
			[feedParser parse];
			[feedParser release], feedParser = nil; // Release after parse
			
		} else {
			
			// Error
			[self failWithErrorCode:MWErrorCodeFeedParsingError description:[NSString stringWithFormat:@"Feed not a valid XML document (URL: %@)", url]];

		}
		
	}
}

#pragma mark -
#pragma mark Error Handling

// If an error occurs, create NSError and inform delegate
- (void)failWithErrorCode:(int)code description:(NSString *)description {
	
	// Create error
	NSError *error = [NSError errorWithDomain:MWErrorDomain 
										 code:code 
									 userInfo:[NSDictionary dictionaryWithObject:description
																		  forKey:NSLocalizedDescriptionKey]];
	MWLog(@"%@", error);

	// Inform delegate
	failed = YES;
	if ([delegate respondsToSelector:@selector(feedParser:didFailWithError:)])
		[delegate feedParser:self didFailWithError:error];
	
}

#pragma mark -
#pragma mark NSURLConnection Delegate (Async)

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[asyncData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[asyncData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	// Failed
	self.urlConnection = nil;
	self.asyncData = nil;
	
    // Error
	[self failWithErrorCode:MWErrorCodeConnectionFailed description:[error localizedDescription]];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// Succeed
	MWLog(@"MWFeedParser: Connection successful... received %d bytes of data", [asyncData length]);
	
	// Parse
	if (!stopped) [self startParsingData:asyncData];
	
    // Cleanup
    self.urlConnection = nil;
    self.asyncData = nil;

}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil; // Don't cache
}

#pragma mark -
#pragma mark XML Parsing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	MWXMLLog(@"NSXMLParser: didStartElement: %@", qualifiedName);
	
	// Adjust path
	self.currentPath = [currentPath stringByAppendingPathComponent:qualifiedName];
	self.currentElementAttributes = attributeDict;
	
	// Parse content as structure (Atom feeds with element type="xhtml")
	// - Use elementName not qualifiedName to ignore XML namespaces for XHTML entities
	if (parseStructureAsContent) {
		
		// Open XHTML tag
		[currentText appendFormat:@"<%@", elementName];
		
		// Add attributes
		for (NSString *key in attributeDict) {
			[currentText appendFormat:@" %@=\"%@\"", key, [[attributeDict objectForKey:key] stringByEncodingHTMLEntities]];
		}
		
		// End tag or close
		if (ELEMENT_IS_EMPTY(elementName)) {
			[currentText appendFormat:@" />", elementName];
		} else {
			[currentText appendFormat:@">", elementName];
		}
		
		// Dont continue
		return;
		
	}
	
	// Reset
	[self.currentText setString:@""];
	
	// Determine feed type
	if (feedType == FeedTypeUnknown) {
		if ([qualifiedName isEqualToString:@"rss"]) feedType = FeedTypeRSS; 
		else if ([qualifiedName isEqualToString:@"rdf:RDF"]) feedType = FeedTypeRSS1;
		else if ([qualifiedName isEqualToString:@"feed"]) feedType = FeedTypeAtom;
		return;
	}
	
	// Entering new feed element
	if (feedParseType != ParseTypeItemsOnly) {
		if ((feedType == FeedTypeRSS  && [currentPath isEqualToString:@"/rss/channel"]) ||
			(feedType == FeedTypeRSS1 && [currentPath isEqualToString:@"/rdf:RDF/channel"]) ||
			(feedType == FeedTypeAtom && [currentPath isEqualToString:@"/feed"])) {
			return;
		}
	}
			
	// Entering new item element
	if ((feedType == FeedTypeRSS  && [currentPath isEqualToString:@"/rss/channel/item"]) ||
		(feedType == FeedTypeRSS1 && [currentPath isEqualToString:@"/rdf:RDF/item"]) ||
		(feedType == FeedTypeAtom && [currentPath isEqualToString:@"/feed/entry"])) {

		// Send off feed info to delegate
		if (!hasEncounteredItems) {
			hasEncounteredItems = YES;
			if (feedParseType != ParseTypeItemsOnly) { // Check whether to ignore feed info
				
				// Dispatch feed info to delegate
				[self dispatchFeedInfoToDelegate];

				// Stop parsing if only requiring meta data
				if (feedParseType == ParseTypeInfoOnly) {
					
					// Debug log
					MWLog(@"MWFeedParser: Parse type is ParseTypeInfoOnly so finishing here");
					
					// Finish
					[self abortParsing];
					return;
					
				}
				
			} else {
				
				// Ignoring feed info so debug log
				MWLog(@"MWFeedParser: Parse type is ParseTypeItemsOnly so ignoring feed info");
				
			}
		}
		
		// New item
		MWFeedItem *newItem = [[MWFeedItem alloc] init];
		self.item = newItem;
		[newItem release];

		return;
	}
	
	// Check if entering into an Atom content tag with type "xhtml"
	// If type is "xhtml" then it can contain child elements and structure needs
	// to be parsed as content
	// See: http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.3.1.1
	if (feedType == FeedTypeAtom) {
		
		// Check type attribute
		NSString *typeAttribute = [attributeDict objectForKey:@"type"];
		if (typeAttribute && [typeAttribute isEqualToString:@"xhtml"]) {
			
			// Start parsing structure as content
			parseStructureAsContent = YES;
			
			// Remember path so we can stop parsing structure when element ends
			self.pathOfElementWithXHTMLType = currentPath;
			
		}
		
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	MWXMLLog(@"NSXMLParser: didEndElement: %@", qName);
	
	// Parse content as structure (Atom feeds with element type="xhtml")
	// - Use elementName not qualifiedName to ignore XML namespaces for XHTML entities
	if (parseStructureAsContent) {
		
		// Check for finishing parsing structure as content
		if (currentPath.length > pathOfElementWithXHTMLType.length) {

			// Close XHTML tag unless it is an empty element
			if (!ELEMENT_IS_EMPTY(elementName)) [currentText appendFormat:@"</%@>", elementName];
			
			// Adjust path & don't continue
			self.currentPath = [currentPath stringByDeletingLastPathComponent];
			
			// Return
			return;
			
		}

		// Finish
		parseStructureAsContent = NO;
		self.pathOfElementWithXHTMLType = nil;
		
		// Continue...
		
	}
	
	// Store data
	BOOL processed = NO;
	if (currentText) {
		
		// Remove newlines and whitespace from currentText
		NSString *processedText = [currentText stringByRemovingNewLinesAndWhitespace];

		// Process
		switch (feedType) {
			case FeedTypeRSS: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/rss/channel/item/title"]) { if (processedText.length > 0) item.title = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/link"]) { if (processedText.length > 0) item.link = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/guid"]) { if (processedText.length > 0) item.identifier = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/description"]) { if (processedText.length > 0) item.summary = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/content:encoded"]) { if (processedText.length > 0) item.content = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/pubDate"]) { if (processedText.length > 0) item.date = [NSDate dateFromInternetDateTimeString:processedText formatHint:DateFormatHintRFC822]; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/enclosure"]) { [self createEnclosureFromAttributes:currentElementAttributes andAddToItem:item]; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/dc:date"]) { if (processedText.length > 0) item.date = [NSDate dateFromInternetDateTimeString:processedText formatHint:DateFormatHintRFC3339]; processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/rss/channel/title"]) { if (processedText.length > 0) info.title = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/description"]) { if (processedText.length > 0) info.summary = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/link"]) { if (processedText.length > 0) info.link = processedText; processed = YES; }
				}
				
				break;
			}
			case FeedTypeRSS1: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/rdf:RDF/item/title"]) { if (processedText.length > 0) item.title = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/link"]) { if (processedText.length > 0) item.link = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/dc:identifier"]) { if (processedText.length > 0) item.identifier = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/description"]) { if (processedText.length > 0) item.summary = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/content:encoded"]) { if (processedText.length > 0) item.content = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/dc:date"]) { if (processedText.length > 0) item.date = [NSDate dateFromInternetDateTimeString:processedText formatHint:DateFormatHintRFC3339]; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/enc:enclosure"]) { [self createEnclosureFromAttributes:currentElementAttributes andAddToItem:item]; processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/rdf:RDF/channel/title"]) { if (processedText.length > 0) info.title = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/channel/description"]) { if (processedText.length > 0) info.summary = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/channel/link"]) { if (processedText.length > 0) info.link = processedText; processed = YES; }
				}
				
				break;
			}
			case FeedTypeAtom: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/feed/entry/title"]) { if (processedText.length > 0) item.title = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/link"]) { [self processAtomLink:currentElementAttributes andAddToMWObject:item]; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/id"]) { if (processedText.length > 0) item.identifier = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/summary"]) { if (processedText.length > 0) item.summary = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/content"]) { if (processedText.length > 0) item.content = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/published"]) { if (processedText.length > 0) item.date = [NSDate dateFromInternetDateTimeString:processedText formatHint:DateFormatHintRFC3339]; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/updated"]) { if (processedText.length > 0) item.updated = [NSDate dateFromInternetDateTimeString:processedText formatHint:DateFormatHintRFC3339]; processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/feed/title"]) { if (processedText.length > 0) info.title = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/description"]) { if (processedText.length > 0) info.summary = processedText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/link"]) { [self processAtomLink:currentElementAttributes andAddToMWObject:info]; processed = YES;}
				}
				
				break;
			}
		}
	}
	
	// Adjust path
	self.currentPath = [currentPath stringByDeletingLastPathComponent];
	
	// If end of an item then tell delegate
	if (!processed) {
		if (((feedType == FeedTypeRSS || feedType == FeedTypeRSS1) && [qName isEqualToString:@"item"]) ||
			(feedType == FeedTypeAtom && [qName isEqualToString:@"entry"])) {
			
			// Dispatch item to delegate
			[self dispatchFeedItemToDelegate];
			
		}
	}
	
	// Check if the document has finished parsing and send off info if needed (i.e. there were no items)
	if (!processed) {
		if ((feedType == FeedTypeRSS && [qName isEqualToString:@"rss"]) ||
			(feedType == FeedTypeRSS1 && [qName isEqualToString:@"rdf:RDF"]) ||
			(feedType == FeedTypeAtom && [qName isEqualToString:@"feed"])) {
			
			// Document ending so if we havent sent off feed info yet, do so
			if (info && feedParseType != ParseTypeItemsOnly) [self dispatchFeedInfoToDelegate];
			
		}	
	}
	
}

//- (void)parser:(NSXMLParser *)parser foundAttributeDeclarationWithName:(NSString *)attributeName forElement:(NSString *)elementName type:(NSString *)type defaultValue:(NSString *)defaultValue {
//	MWXMLLog(@"NSXMLParser: foundAttributeDeclarationWithName: %@", attributeName);
//}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	MWXMLLog(@"NSXMLParser: foundCDATA (%d bytes)", CDATABlock.length);
	
	// Remember characters
	NSString *string = nil;
	@try {
		
		// Try decoding with NSUTF8StringEncoding & NSISOLatin1StringEncoding
		string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
		if (!string) string = [[NSString alloc] initWithData:CDATABlock encoding:NSISOLatin1StringEncoding];
		
		// Add - No need to encode as CDATA should not be encoded as it's ignored by the parser
		if (string) [currentText appendString:string];
		
	} @catch (NSException * e) { 
	} @finally {
		[string release];
	}
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	MWXMLLog(@"NSXMLParser: foundCharacters: %@", string);
	
	// Remember characters
	if (!parseStructureAsContent) {
		
		// Add characters normally
		[currentText appendString:string];
		
	} else {
		
		// If parsing structure as content then we should encode characters
		[currentText appendString:[string stringByEncodingHTMLEntities]];
		
	}
	
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	MWXMLLog(@"NSXMLParser: parserDidStartDocument");
	
	// Debug Log
	MWLog(@"MWFeedParser: Parsing started");
	
	// Inform delegate
	if ([delegate respondsToSelector:@selector(feedParserDidStart:)])
		[delegate feedParserDidStart:self];
	
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	MWXMLLog(@"NSXMLParser: parserDidEndDocument");

	// Debug Log
	MWLog(@"MWFeedParser: Parsing finished");
	
	// Inform delegate
	[self parsingFinished]; // Cleanup
	if ([delegate respondsToSelector:@selector(feedParserDidFinish:)])
		[delegate feedParserDidFinish:self];
	
}

// Call if parsing error occured or parse was aborted
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	MWXMLLog(@"NSXMLParser: parseErrorOccurred: %@", parseError);
	
	// Finished
	[self parsingFinished]; // Cleanup
	if (!aborted) {
		
		// Fail with error
		[self failWithErrorCode:MWErrorCodeFeedParsingError description:[parseError localizedDescription]];
		
	}
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {
	MWXMLLog(@"NSXMLParser: validationErrorOccurred: %@", validError);
	
	// Finished
	[self parsingFinished]; // Cleanup
	
	// Fail with error
	[self failWithErrorCode:MWErrorCodeFeedValidationError description:[validError localizedDescription]];
	
}

#pragma mark -
#pragma mark Send Items to Delegate

- (void)dispatchFeedInfoToDelegate {
	if (info) {
	
		// Inform delegate
		if ([delegate respondsToSelector:@selector(feedParser:didParseFeedInfo:)])
			[delegate feedParser:self didParseFeedInfo:[[info retain] autorelease]];
		
		// Debug log
		MWLog(@"MWFeedParser: Feed info for \"%@\" successfully parsed", info.title);
		
		// Finish
		self.info = nil;
		
	}
}

- (void)dispatchFeedItemToDelegate {
	if (item) {

		// Ensure summary always contains data if available
		if (!item.summary) { item.summary = item.content; item.content = nil; }
		
		// Debug log
		MWLog(@"MWFeedParser: Feed item \"%@\" successfully parsed", item.title);
		
		// Inform delegate
		if ([delegate respondsToSelector:@selector(feedParser:didParseFeedItem:)])
			[delegate feedParser:self didParseFeedItem:[[item retain] autorelease]];
		
		// Finish
		self.item = nil;
		
	}
}

#pragma mark -
#pragma mark Helpers

- (NSString *)url {
	return [NSString stringWithString:url];
}

#pragma mark -
#pragma mark Misc

// Create an enclosure NSDictionary from enclosure (or link) attributes
- (BOOL)createEnclosureFromAttributes:(NSDictionary *)attributes andAddToItem:(MWFeedItem *)currentItem {
	
	// Create enclosure
	NSDictionary *enclosure = nil;
	NSString *encURL, *encType;
	NSNumber *encLength;
	if (attributes) {
		switch (feedType) {
			case FeedTypeRSS: { // http://cyber.law.harvard.edu/rss/rss.html#ltenclosuregtSubelementOfLtitemgt
				// <enclosure>
				encURL = [attributes objectForKey:@"url"];
				encType = [attributes objectForKey:@"type"];
				encLength = [NSNumber numberWithLongLong:[((NSString *)[attributes objectForKey:@"length"]) longLongValue]];
				break;
			}
			case FeedTypeRSS1: { // http://www.xs4all.nl/~foz/mod_enclosure.html
				// <enc:enclosure>
				encURL = [attributes objectForKey:@"rdf:resource"];
				encType = [attributes objectForKey:@"enc:type"];
				encLength = [NSNumber numberWithLongLong:[((NSString *)[attributes objectForKey:@"enc:length"]) longLongValue]];
				break;
			}
			case FeedTypeAtom: { // http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rel_attribute
				// <link rel="enclosure" href=...
				if ([[attributes objectForKey:@"rel"] isEqualToString:@"enclosure"]) {
					encURL = [attributes objectForKey:@"href"];
					encType = [attributes objectForKey:@"type"];
					encLength = [NSNumber numberWithLongLong:[((NSString *)[attributes objectForKey:@"length"]) longLongValue]];
				}
				break;
			}
		}
	}
	if (encURL) {
		NSMutableDictionary *e = [[NSMutableDictionary alloc] initWithCapacity:3];
		[e setObject:encURL forKey:@"url"];
		if (encType) [e setObject:encType forKey:@"type"];
		if (encLength) [e setObject:encLength forKey:@"length"];
		enclosure = [NSDictionary dictionaryWithDictionary:e];
		[e release];
	}
					 
	// Add to item		 
	if (enclosure) {
		if (currentItem.enclosures) {
			currentItem.enclosures = [currentItem.enclosures arrayByAddingObject:enclosure];
		} else {
			currentItem.enclosures = [NSArray arrayWithObject:enclosure];
		}
		return YES;
	} else {
		return NO;
	}
	
}

// Process ATOM link and determine whether to ignore it, add it as the link element or add as enclosure
// Links can be added to MWObject (info or item)
- (BOOL)processAtomLink:(NSDictionary *)attributes andAddToMWObject:(id)MWObject {
	if (attributes && [attributes objectForKey:@"rel"]) {
		
		// Use as link if rel == alternate
		if ([[attributes objectForKey:@"rel"] isEqualToString:@"alternate"]) {
			[MWObject setLink:[attributes objectForKey:@"href"]]; // Can be added to MWFeedItem or MWFeedInfo
			return YES;
		}
		
		// Use as enclosure if rel == enclosure
		if ([[attributes objectForKey:@"rel"] isEqualToString:@"enclosure"]) {
			if ([MWObject isMemberOfClass:[MWFeedItem class]]) { // Enclosures can only be added to MWFeedItem
				[self createEnclosureFromAttributes:attributes andAddToItem:(MWFeedItem *)MWObject];
				return YES;
			}
		}
		
	}
	return NO;
}

@end