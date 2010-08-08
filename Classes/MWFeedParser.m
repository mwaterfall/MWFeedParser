//
//  MWFeedParser.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 08/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import "MWFeedParser.h"
#import "MWFeedParser_Private.h"
#import "NSString+HTML.h"

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
	parsingComplete = NO;
	self.currentElementAttributes = nil;
	parseStructureAsContent = NO;
	self.pathOfElementWithXHTMLType = nil;
}

// Begin downloading & parsing of feed
- (void)parse {
	
	// Checks
	if (!url || !delegate) {

		// Error
		[self failWithErrorCode:MWErrorCodeNotInitiated description:@"Delegate or URL not specified"];
		return;
		
	}
	
	// Reset
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
			
			// Create data
			asyncData = [[NSMutableData alloc] init];
			
		} else {
		
			// Error
			[self failWithErrorCode:MWErrorCodeConnectionFailed description:[NSString stringWithFormat:@"Asynchronous connection failed to URL: %@", url]];
			
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
			[self failWithErrorCode:MWErrorCodeConnectionFailed description:[NSString stringWithFormat:@"Synchronous connection failed to URL: %@", url]];
			
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
		[feedParser setShouldProcessNamespaces:YES];
		[feedParser parse];
		
	}
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
		switch (feedType) {
			case FeedTypeRSS: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/rss/channel/item/title"]) { if (currentText.length > 0) item.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/link"]) { if (currentText.length > 0) item.link = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/description"]) { if (currentText.length > 0) item.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/content:encoded"]) { if (currentText.length > 0) item.content = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/pubDate"]) { if (currentText.length > 0) item.date = [self dateFromRFC822String:currentText]; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/item/enclosure"]) { [self createEnclosureFromAttributes:currentElementAttributes andAddToItem:item]; processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/rss/channel/title"]) { if (currentText.length > 0) info.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/description"]) { if (currentText.length > 0) info.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rss/channel/link"]) { if (currentText.length > 0) info.link = currentText; processed = YES; }
				}
				
				break;
			}
			case FeedTypeRSS1: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/rdf:RDF/item/title"]) { if (currentText.length > 0) item.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/link"]) { if (currentText.length > 0) item.link = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/description"]) { if (currentText.length > 0) item.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/content:encoded"]) { if (currentText.length > 0) item.content = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/dc:date"]) { if (currentText.length > 0) item.date = [self dateFromRFC3339String:currentText]; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/item/enc:enclosure"]) { [self createEnclosureFromAttributes:currentElementAttributes andAddToItem:item]; processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/rdf:RDF/channel/title"]) { if (currentText.length > 0) info.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/channel/description"]) { if (currentText.length > 0) info.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/rdf:RDF/channel/link"]) { if (currentText.length > 0) info.link = currentText; processed = YES; }
				}
				
				break;
			}
			case FeedTypeAtom: {
				
				// Item
				if (!processed) {
					if ([currentPath isEqualToString:@"/feed/entry/title"]) { if (currentText.length > 0) item.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/link"]) { [self processAtomLink:currentElementAttributes andAddToMWObject:item]; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/summary"]) { if (currentText.length > 0) item.summary = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/content"]) { if (currentText.length > 0) item.content = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/published"]) { if (currentText.length > 0) item.date = [self dateFromRFC3339String:currentText]; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/entry/updated"]) { if (currentText.length > 0) item.updated = [self dateFromRFC3339String:currentText]; processed = YES; }
				}
				
				// Info
				if (!processed && feedParseType != ParseTypeItemsOnly) {
					if ([currentPath isEqualToString:@"/feed/title"]) { if (currentText.length > 0) info.title = currentText; processed = YES; }
					else if ([currentPath isEqualToString:@"/feed/description"]) { if (currentText.length > 0) info.summary = currentText; processed = YES; }
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
			if (info) [self dispatchFeedInfoToDelegate];
			
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
	parsingComplete = YES;
	if ([delegate respondsToSelector:@selector(feedParserDidFinish:)])
		[delegate feedParserDidFinish:self];
	
}

// Call if parsing error occured or parse was aborted
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	MWXMLLog(@"NSXMLParser: parseErrorOccurred: %@", parseError);
	parsingComplete = YES;
	if (!aborted) {
		
		// Fail with error
		[self failWithErrorCode:MWErrorCodeFeedParsingError description:[parseError localizedDescription]];
		
	}
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {
	MWXMLLog(@"NSXMLParser: validationErrorOccurred: %@", validError);
	parsingComplete = YES;
	
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

- (BOOL)isStopped {
	return stopped;
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

- (NSDate *)dateFromRFC822String:(NSString *)dateString {
	NSDate *date = nil;
	NSString *RFC822String = [[NSString stringWithString:dateString] uppercaseString];
	if (!date) { // Sun, 19 May 02 15:21:36 GMT
		[dateFormatterRFC822 setDateFormat:@"EEE, d MMM yy HH:mm:ss zzz"]; 
		date = [dateFormatterRFC822 dateFromString:RFC822String];
	}
	if (!date) { // Sun, 19 May 2002 15:21:36 GMT
		[dateFormatterRFC822 setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"]; 
		date = [dateFormatterRFC822 dateFromString:RFC822String];
	}
	if (!date) {  // Sun, 19 May 2002 15:21 GMT
		[dateFormatterRFC822 setDateFormat:@"EEE, d MMM yyyy HH:mm zzz"]; 
		date = [dateFormatterRFC822 dateFromString:RFC822String];
	}
	if (!date) {  // 19 May 2002 15:21:36 GMT
		[dateFormatterRFC822 setDateFormat:@"d MMM yyyy HH:mm:ss zzz"]; 
		date = [dateFormatterRFC822 dateFromString:RFC822String];
	}
	if (!date) {  // 19 May 2002 15:21 GMT
		[dateFormatterRFC822 setDateFormat:@"d MMM yyyy HH:mm zzz"]; 
		date = [dateFormatterRFC822 dateFromString:RFC822String];
	}
	if (!date) {  // 19 May 2002 15:21:36
		[dateFormatterRFC822 setDateFormat:@"d MMM yyyy HH:mm:ss"]; 
		date = [dateFormatterRFC822 dateFromString:RFC822String];
	}
	if (!date) {  // 19 May 2002 15:21
		[dateFormatterRFC822 setDateFormat:@"d MMM yyyy HH:mm"]; 
		date = [dateFormatterRFC822 dateFromString:RFC822String];
	}
	if (!date) { // Failed so Debug log
		MWLog(@"MWFeedParser: Could not parse RFC822 date: \"%@\" Possibly invalid format.", dateString);
	}
	return date;
}

- (NSDate *)dateFromRFC3339String:(NSString *)dateString {
	NSDate *date = nil;
	NSString *RFC3339String = [[NSString stringWithString:dateString] uppercaseString];
	RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
	
	// Remove colon in timezone as iOS 4+ NSDateFormatter breaks
	// See https://devforums.apple.com/thread/45837
	if (RFC3339String.length > 20) {
		RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@":" 
																 withString:@"" 
																	options:0
																	  range:NSMakeRange(20, RFC3339String.length-20)];
	}
	
	if (!date) { // 1996-12-19T16:39:57-0800
		[dateFormatterRFC3339 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"]; 
		date = [dateFormatterRFC3339 dateFromString:RFC3339String];
	}
	if (!date) { // 1937-01-01T12:00:27.87+0020
		[dateFormatterRFC3339 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"]; 
		date = [dateFormatterRFC3339 dateFromString:RFC3339String];
	}
	if (!date) { // 1937-01-01T12:00:27
		[dateFormatterRFC3339 setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"]; 
		date = [dateFormatterRFC3339 dateFromString:RFC3339String];
	}
	if (!date) { // Failed so Debug log
		MWLog(@"MWFeedParser: Could not parse RFC3339 date: \"%@\" Possibly invalid format.", dateString);
	}
	return date;
}

@end