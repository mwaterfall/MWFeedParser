//
//  NSString+XMLEntities.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 11/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import "NSString+XMLEntities.h"

@implementation NSString (XMLEntities)

- (NSString *)stringByDecodingXMLEntities {
	return [self stringByDecodingHTMLEntities];
}

- (NSString *)stringByEncodingXMLEntities {
	return [self stringByEncodingHTMLEntities];
}

@end
