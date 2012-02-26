//
//  MWImageParser.m
//  MWFeedParser
//
//  Copyright (c) 2012 Vladimir Grichina
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

#import "MWImageParser.h"

#include "tidy.h"
#include "buffio.h"

@implementation MWImageParser

@synthesize xmlParser, images;

+ (NSArray *)parseImagesFromXHTMLString:(NSString *)html {
    // HTML may be malformed and needs to be run through Tidy

    TidyBuffer output = {0};
    TidyBuffer errbuf = {0};

    TidyDoc tdoc = tidyCreate();

    // Stup Tidy to convert into XML
    if (!tidyOptSetBool(tdoc, TidyXmlOut, yes)) {
        return nil;
    }
    // Capture diagnostics
    if (tidySetErrorBuffer(tdoc, &errbuf) < 0) {
        return nil;
    }
    // Parse the input
    if (tidyParseString(tdoc, [html UTF8String]) < 0) {
        return nil;
    }
    // Tidy it up!
    if (tidyCleanAndRepair(tdoc) < 0) {
        return nil;
    }
    // Pretty Print
    if (tidySaveBuffer(tdoc, &output) < 0) {
        return nil;
    }

    html = [NSString stringWithUTF8String:(char *)output.bp];

    MWImageParser *parser = [[MWImageParser new] autorelease];
    parser.images = [NSMutableArray array];
    parser.xmlParser = [[[NSXMLParser alloc] initWithData:[html dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
    parser.xmlParser.delegate = parser;
    [parser.xmlParser parse];
    return parser.images;
}

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    if ([elementName isEqual:@"img"]) {
        NSString *src = [attributeDict objectForKey:@"src"];
        if (src) {
            [self.images addObject:src];
        }
    }
}

@end
