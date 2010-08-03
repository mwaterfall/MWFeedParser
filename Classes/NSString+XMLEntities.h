//
//  NSString+XMLEntities.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 11/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import <Foundation/Foundation.h>

// Import new HTML category
#import "NSString+HTML.h"

// DEPRECIATED 03/08/2010
// Replaced with NSString+HTML
@interface NSString (XMLEntities)

// Old Instance Methods
- (NSString *)stringByDecodingXMLEntities;
- (NSString *)stringByEncodingXMLEntities;

@end
