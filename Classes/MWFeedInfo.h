//
//  MWFeedInfo.h
//  MWFeedParser
//
//  Created by Michael Waterfall on 10/05/2010.
//  Copyright 2010 Michael Waterfall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWFeedInfo : NSObject <NSCoding> {
	
	NSString *title; // Feed title
	NSString *link; // Feed link
	NSString *summary; // Feed summary / description
	
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *link;
@property (nonatomic, copy) NSString *summary;

@end
