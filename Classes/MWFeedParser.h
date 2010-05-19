//
//  MWFeedParser.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 08/05/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWFeedInfo.h"
#import "MWFeedItem.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

// Errors & codes
#define MWErrorDomain @"MWFeedParser"
#define MWErrorCodeNotInitiated				1		/* MWFeedParser not initialised correctly */
#define MWErrorCodeConnectionFailed			2		/* Connection to the URL failed */
#define MWErrorCodeFeedParsingError			3		/* NSXMLParser encountered a parsing error */
#define MWErrorCodeFeedValidationError		4		/* NSXMLParser encountered a validation error */

// Class
@class MWFeedParser;

// Types
typedef enum { ConnectionTypeAsynchronously, ConnectionTypeSynchronously } ConnectionType;
typedef enum { ParseTypeFull, ParseTypeItemsOnly, ParseTypeInfoOnly } ParseType;
typedef enum { FeedTypeUnknown, FeedTypeRSS, FeedTypeAtom } FeedType;

// Delegate
@protocol MWFeedParserDelegate <NSObject>
@optional
- (void)feedParserDidStart:(MWFeedParser *)parser;
- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info;
- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item;
- (void)feedParserDidFinish:(MWFeedParser *)parser;
- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error;
@end

// MWFeedParser
@interface MWFeedParser : NSObject {

@private
	
	// Required
	id <MWFeedParserDelegate> delegate;
	NSString *url;
	
	// Connection
	NSURLConnection *urlConnection;
	NSMutableData *asyncData;
	ConnectionType connectionType;
	
	// Parsing
	ParseType feedParseType;
	NSXMLParser *feedParser;
	FeedType feedType;
	NSDateFormatter *dateFormatterRFC822, *dateFormatterRFC3339;
	BOOL hasEncounteredItems; // Whether the parser has started parsing items
	BOOL aborted; // Whether parse stopped due to abort
	BOOL stopped; // Whether the parse was stopped
	BOOL parsingComplete; // Whether NSXMLParser parsing has completed
	
	// Parsing Data
	NSString *currentPath;
	NSMutableString *currentText;
	NSDictionary *currentElementAttributes;
	MWFeedItem *item;
	MWFeedInfo *info;
	
}

#pragma mark Public Properties

// Delegate to recieve data as it is parsed
@property (nonatomic, assign) id <MWFeedParserDelegate> delegate;

// Whether to parse feed info & all items, just feed info, or just feed items
@property (nonatomic) ParseType feedParseType;

// Set whether to download asynchronously or synchronously
@property (nonatomic) ConnectionType connectionType;

#pragma mark Public Methods

// Init MWFeedParser with a URL string
- (id)initWithFeedURL:(NSString *)feedURL;

// Begin parsing
- (void)parse;

// Stop parsing
- (void)stopParsing;

// Returns the URL
- (NSString *)url;

// Returns whether the parsing was stopped by calling `stopParsing`
- (BOOL)isStopped;

@end