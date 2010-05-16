//
//  MWFeedParser.h
//  XML
//
//  Created by Michael Waterfall on 08/05/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWFeedInfo.h"
#import "MWFeedItem.h"

// Debug Logging
#if 0
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

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

// Class
@interface MWFeedParser : NSObject {
	
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
	
	// Parsing Data
	NSString *currentPath;
	NSMutableString *currentText;
	NSDictionary *currentElementAttributes;
	MWFeedItem *item;
	MWFeedInfo *info;
	
}

// Properties
@property (nonatomic, assign) id <MWFeedParserDelegate> delegate;
@property (nonatomic, copy) NSString *url;

// Feed Downloading Properties
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, retain) NSMutableData *asyncData;
@property (nonatomic) ConnectionType connectionType;

// Parsing Properties
@property (nonatomic) ParseType feedParseType;
@property (nonatomic, retain) NSXMLParser *feedParser;
@property (nonatomic, retain) NSString *currentPath;
@property (nonatomic, retain) NSMutableString *currentText;
@property (nonatomic, retain) NSDictionary *currentElementAttributes;
@property (nonatomic, retain) MWFeedItem *item;
@property (nonatomic, retain) MWFeedInfo *info;

// NSObject Methods
- (id)initWithFeedURL:(NSString *)feedURL;

// Parsing Methods
- (void)reset;
- (void)parse;
- (void)startParsingData:(NSData *)data;

// Misc
- (void)finishParsing;
- (NSString *)linkFromAtomLinkAttributes:(NSDictionary *)attributes;

// Dates
- (NSDate *)dateFromRFC822String:(NSString *)dateString;
- (NSDate *)dateFromRFC3339String:(NSString *)dateString;

@end