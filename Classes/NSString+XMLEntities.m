//
//  NSString+XMLEntities.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 11/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import "NSString+XMLEntities.h"

// THIS CLASS IS DEPRECIATED 03/08/2010
// REPLACED BY NSString+HTML

@implementation NSString (XMLEntities)

- (NSString *)stringByDecodingXMLEntities {
	return [self stringByDecodingHTMLEntities];
}

- (NSString *)stringByEncodingXMLEntities {
	return [self stringByEncodingHTMLEntities];
}

@end
