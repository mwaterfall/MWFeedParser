//
//  MWFeedParser_Private.h
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

@interface MWFeedParser ()

#pragma mark Private Properties

// Feed Downloading Properties
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *asyncData;
@property (nonatomic, strong) NSString *asyncTextEncodingName;

// Parsing Properties
@property (nonatomic, strong) NSXMLParser *feedParser;
@property (nonatomic, strong) NSString *currentPath;
@property (nonatomic, strong) NSMutableString *currentText;
@property (nonatomic, strong) NSDictionary *currentElementAttributes;
@property (nonatomic, strong) MWFeedItem *item;
@property (nonatomic, strong) MWFeedInfo *info;
@property (nonatomic, copy) NSString *pathOfElementWithXHTMLType;

#pragma mark Private Methods

// Parsing Methods
- (void)reset;
- (void)abortParsingEarly;
- (void)parsingFinished;
- (void)parsingFailedWithErrorCode:(int)code andDescription:(NSString *)description;
- (void)startParsingData:(NSData *)data textEncodingName:(NSString *)textEncodingName;

// Dispatching to Delegate
- (void)dispatchFeedInfoToDelegate;
- (void)dispatchFeedItemToDelegate;

// Error Handling

// Misc
- (BOOL)createEnclosureFromAttributes:(NSDictionary *)attributes andAddToItem:(MWFeedItem *)currentItem;
- (BOOL)processAtomLink:(NSDictionary *)attributes andAddToMWObject:(id)MWObject;

@end