//
//  NSString+HTML.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 03/08/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (HTML)

// Instance Methods
- (NSString *)stringByStrippingTags;
- (NSString *)stringWithNewLinesAsBRs;
- (NSString *)stringByRemovingNewLinesAndWhitespace;
- (NSString *)stringByDecodingHTMLEntities;
- (NSString *)stringByEncodingHTMLEntities;

@end
