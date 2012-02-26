//
//  MWFeedParserTests.m
//  MWFeedParserTests
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


#import "MWFeedParserTests.h"

#import "MWFeedParser.h"

@interface DummyDelegate : NSObject<MWFeedParserDelegate>

@property(retain) NSMutableArray *items;

@end

@implementation DummyDelegate

@synthesize items;

- (void) feedParserDidStart:(MWFeedParser *)parser {
    self.items = [NSMutableArray array];
}

- (void) feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    [self.items addObject:item];
}

@end

@implementation MWFeedParserTests


- (void)testImagesAtUrl:(NSURL *)url {
    DummyDelegate *delegate = [[DummyDelegate new] autorelease];
    MWFeedParser *feedParser = [[[MWFeedParser alloc] initWithFeedURL:url] autorelease];
    feedParser.delegate = delegate;
    feedParser.connectionType = ConnectionTypeSynchronously;
    [feedParser parse];

    STAssertTrue([delegate.items count] > 0, @"Should parse items");
    for (MWFeedItem *item in delegate.items) {
        STAssertTrue(!!item.title, @"Item should have title");
        STAssertTrue([item.images count] > 0, @"Item should have images: %@", item.summary);
    }
}

/*
- (void)testAdmeImages {
    [self testImagesAtUrl:
     [NSURL fileURLWithPath:
      [[NSBundle bundleForClass:[self class]] pathForResource:@"adme-rss"
                                                       ofType:@"xml"
                                                  inDirectory:@"samples"]]];
}*/

- (void)testPhotobucketImages {
    [self testImagesAtUrl:
     [NSURL fileURLWithPath:
      [[NSBundle bundleForClass:[self class]] pathForResource:@"photobucket-rss"
                                                       ofType:@"xml"
                                                  inDirectory:@"samples"]]];
}


@end
