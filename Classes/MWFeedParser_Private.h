//
//  MWFeedParser_Private.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 19/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWFeedParser ()

#pragma mark Private Properties

// Feed Downloading Properties
@property (nonatomic, copy) NSString *url;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, retain) NSMutableData *asyncData;

// Parsing Properties
@property (nonatomic, retain) NSXMLParser *feedParser;
@property (nonatomic, retain) NSString *currentPath;
@property (nonatomic, retain) NSMutableString *currentText;
@property (nonatomic, retain) NSDictionary *currentElementAttributes;
@property (nonatomic, retain) MWFeedItem *item;
@property (nonatomic, retain) MWFeedInfo *info;
@property (nonatomic, copy) NSString *pathOfElementWithXHTMLType;

#pragma mark Private Methods

// Parsing Methods
- (void)reset;
- (void)startParsingData:(NSData *)data;
- (void)abortParsing;

// Dispatching to Delegate
- (void)dispatchFeedInfoToDelegate;
- (void)dispatchFeedItemToDelegate;

// Error Handling
- (void)failWithErrorCode:(int)code description:(NSString *)description;

// Misc
- (BOOL)createEnclosureFromAttributes:(NSDictionary *)attributes andAddToItem:(MWFeedItem *)currentItem;
- (BOOL)processAtomLink:(NSDictionary *)attributes andAddToMWObject:(id)MWObject;
- (NSDate *)dateFromRFC822String:(NSString *)dateString;
- (NSDate *)dateFromRFC3339String:(NSString *)dateString;

@end