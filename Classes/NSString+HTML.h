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
- (NSString *)stringByConvertingHTMLToPlainText;
- (NSString *)stringByDecodingHTMLEntities;
- (NSString *)stringByEncodingHTMLEntities;
- (NSString *)stringWithNewLinesAsBRs;
- (NSString *)stringByRemovingNewLinesAndWhitespace;

// DEPRECIATED - Please use NSString stringByConvertingHTMLToPlainText
- (NSString *)stringByStrippingTags; 

@end
