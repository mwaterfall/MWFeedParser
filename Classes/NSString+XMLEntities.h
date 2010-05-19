//
//  NSString+XMLEntities.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 11/05/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (XMLEntities)

// Instance Methods
- (NSString *)stringByStrippingTags;
- (NSString *)stringByDecodingXMLEntities;
- (NSString *)stringByEncodingXMLEntities;
- (NSString *)stringWithNewLinesAsBRs;
- (NSString *)stringByRemovingNewLinesAndWhitespace;

@end
