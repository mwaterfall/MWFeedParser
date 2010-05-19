//
//  NSString+XMLEntities.m
//  MWFeedParser
//
//  Created by Michael Waterfall on 11/05/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "NSString+XMLEntities.h"

@implementation NSString (XMLEntities)

#pragma mark -
#pragma mark Class Methods

#pragma mark -
#pragma mark Instance Methods

// Partially adapted and extended from examples at:
// http://stackoverflow.com/questions/1105169/html-character-decoding-in-objective-c-cocoa-touch
- (NSString *)stringByDecodingXMLEntities {
	
	// Find first & and short-cut if we can
	NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;
	if (ampIndex == NSNotFound) {
		return [NSString stringWithString:self]; // return copy of string as no & found
	}

	// Make result string with some extra capacity.
	NSMutableString *result = [[NSMutableString alloc] initWithCapacity:(self.length * 1.25)];
	
	// First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	[scanner setCaseSensitive:YES];
	
	// Boundary characters for scanning unexpected &#... pattern
	NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
	
	// Scan
	do {

		// Scan up to the next entity or the end of the string.
		NSString *nonEntityString;
		if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
			[result appendString:nonEntityString];
		}
		if ([scanner isAtEnd]) break;

		// Common character entity references first
		if ([scanner scanString:@"&amp;" intoString:NULL])
			[result appendString:@"&"];
		else if ([scanner scanString:@"&apos;" intoString:NULL])
			[result appendString:@"'"];
		else if ([scanner scanString:@"&quot;" intoString:NULL])
			[result appendString:@"\""];
		else if ([scanner scanString:@"&lt;" intoString:NULL])
			[result appendString:@"<"];
		else if ([scanner scanString:@"&gt;" intoString:NULL])
			[result appendString:@">"];
		else if ([scanner scanString:@"&nbsp;" intoString:NULL])
			[result appendFormat:@"%C", 160];
		else if ([scanner scanString:@"&laquo;" intoString:NULL])
			[result appendFormat:@"%C", 171];
		else if ([scanner scanString:@"&raquo;" intoString:NULL])
			[result appendFormat:@"%C", 187];
		else if ([scanner scanString:@"&ndash;" intoString:NULL])
			[result appendFormat:@"%C", 8211];
		else if ([scanner scanString:@"&mdash;" intoString:NULL])
			[result appendFormat:@"%C", 8212];
		else if ([scanner scanString:@"&lsquo;" intoString:NULL])
			[result appendFormat:@"%C", 8216];
		else if ([scanner scanString:@"&rsquo;" intoString:NULL])
			[result appendFormat:@"%C", 8217];
		else if ([scanner scanString:@"&ldquo;" intoString:NULL])
			[result appendFormat:@"%C", 8220];
		else if ([scanner scanString:@"&rdquo;" intoString:NULL])
			[result appendFormat:@"%C", 8221];
		else if ([scanner scanString:@"&bull;" intoString:NULL])
			[result appendFormat:@"%C", 8226];
		else if ([scanner scanString:@"&hellip;" intoString:NULL])
			[result appendFormat:@"%C", 8230];

		// Numeric character entity references
		else if ([scanner scanString:@"&#" intoString:NULL]) {
			
			// Entity
			BOOL gotNumber;
			unsigned charCode;
			NSString *xForHex = @"";
			
			// Is it hex or decimal?
			if ([scanner scanString:@"x" intoString:&xForHex]) {
				gotNumber = [scanner scanHexInt:&charCode];
			} else {
				gotNumber = [scanner scanInt:(int*)&charCode];
			}
			
			// Process
			if (gotNumber) {
				
				// Append character
				[result appendFormat:@"%C", charCode];
				[scanner scanString:@";" intoString:NULL];
				
			} else {
				
				// Failed to get a number so append to result and log error
				NSString *unknownEntity = @"";
				[scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
				[result appendFormat:@"&#%@%@", xForHex, unknownEntity]; // Append exact same string
				
			}
			
		// Quick check for isolated & with a space after to speed up checks
		} else if ([scanner scanString:@"& " intoString:NULL])
			[result appendString:@"& "];	
			
		// No so common character entity references
		else if ([scanner scanString:@"&iexcl;" intoString:NULL])
			[result appendFormat:@"%C", 161];
		else if ([scanner scanString:@"&cent;" intoString:NULL])
			[result appendFormat:@"%C", 162];
		else if ([scanner scanString:@"&pound;" intoString:NULL])
			[result appendFormat:@"%C", 163];
		else if ([scanner scanString:@"&curren;" intoString:NULL])
			[result appendFormat:@"%C", 164];
		else if ([scanner scanString:@"&yen;" intoString:NULL])
			[result appendFormat:@"%C", 165];
		else if ([scanner scanString:@"&brvbar;" intoString:NULL])
			[result appendFormat:@"%C", 166];
		else if ([scanner scanString:@"&sect;" intoString:NULL])
			[result appendFormat:@"%C", 167];
		else if ([scanner scanString:@"&uml;" intoString:NULL])
			[result appendFormat:@"%C", 168];
		else if ([scanner scanString:@"&copy;" intoString:NULL])
			[result appendFormat:@"%C", 169];
		else if ([scanner scanString:@"&ordf;" intoString:NULL])
			[result appendFormat:@"%C", 170];
		else if ([scanner scanString:@"&not;" intoString:NULL])
			[result appendFormat:@"%C", 172];
		else if ([scanner scanString:@"&shy;" intoString:NULL])
			[result appendFormat:@"%C", 173];
		else if ([scanner scanString:@"&reg;" intoString:NULL])
			[result appendFormat:@"%C", 174];
		else if ([scanner scanString:@"&macr;" intoString:NULL])
			[result appendFormat:@"%C", 175];
		else if ([scanner scanString:@"&deg;" intoString:NULL])
			[result appendFormat:@"%C", 176];
		else if ([scanner scanString:@"&plusmn;" intoString:NULL])
			[result appendFormat:@"%C", 177];
		else if ([scanner scanString:@"&sup2;" intoString:NULL])
			[result appendFormat:@"%C", 178];
		else if ([scanner scanString:@"&sup3;" intoString:NULL])
			[result appendFormat:@"%C", 179];
		else if ([scanner scanString:@"&acute;" intoString:NULL])
			[result appendFormat:@"%C", 180];
		else if ([scanner scanString:@"&micro;" intoString:NULL])
			[result appendFormat:@"%C", 181];
		else if ([scanner scanString:@"&para;" intoString:NULL])
			[result appendFormat:@"%C", 182];
		else if ([scanner scanString:@"&middot;" intoString:NULL])
			[result appendFormat:@"%C", 183];
		else if ([scanner scanString:@"&cedil;" intoString:NULL])
			[result appendFormat:@"%C", 184];
		else if ([scanner scanString:@"&sup1;" intoString:NULL])
			[result appendFormat:@"%C", 185];
		else if ([scanner scanString:@"&ordm;" intoString:NULL])
			[result appendFormat:@"%C", 186];
		else if ([scanner scanString:@"&frac14;" intoString:NULL])
			[result appendFormat:@"%C", 188];
		else if ([scanner scanString:@"&frac12;" intoString:NULL])
			[result appendFormat:@"%C", 189];
		else if ([scanner scanString:@"&frac34;" intoString:NULL])
			[result appendFormat:@"%C", 190];
		else if ([scanner scanString:@"&iquest;" intoString:NULL])
			[result appendFormat:@"%C", 191];
		else if ([scanner scanString:@"&Agrave;" intoString:NULL])
			[result appendFormat:@"%C", 192];
		else if ([scanner scanString:@"&Aacute;" intoString:NULL])
			[result appendFormat:@"%C", 193];
		else if ([scanner scanString:@"&Acirc;" intoString:NULL])
			[result appendFormat:@"%C", 194];
		else if ([scanner scanString:@"&Atilde;" intoString:NULL])
			[result appendFormat:@"%C", 195];
		else if ([scanner scanString:@"&Auml;" intoString:NULL])
			[result appendFormat:@"%C", 196];
		else if ([scanner scanString:@"&Aring;" intoString:NULL])
			[result appendFormat:@"%C", 197];
		else if ([scanner scanString:@"&AElig;" intoString:NULL])
			[result appendFormat:@"%C", 198];
		else if ([scanner scanString:@"&Ccedil;" intoString:NULL])
			[result appendFormat:@"%C", 199];
		else if ([scanner scanString:@"&Egrave;" intoString:NULL])
			[result appendFormat:@"%C", 200];
		else if ([scanner scanString:@"&Eacute;" intoString:NULL])
			[result appendFormat:@"%C", 201];
		else if ([scanner scanString:@"&Ecirc;" intoString:NULL])
			[result appendFormat:@"%C", 202];
		else if ([scanner scanString:@"&Euml;" intoString:NULL])
			[result appendFormat:@"%C", 203];
		else if ([scanner scanString:@"&Igrave;" intoString:NULL])
			[result appendFormat:@"%C", 204];
		else if ([scanner scanString:@"&Iacute;" intoString:NULL])
			[result appendFormat:@"%C", 205];
		else if ([scanner scanString:@"&Icirc;" intoString:NULL])
			[result appendFormat:@"%C", 206];
		else if ([scanner scanString:@"&Iuml;" intoString:NULL])
			[result appendFormat:@"%C", 207];
		else if ([scanner scanString:@"&ETH;" intoString:NULL])
			[result appendFormat:@"%C", 208];
		else if ([scanner scanString:@"&Ntilde;" intoString:NULL])
			[result appendFormat:@"%C", 209];
		else if ([scanner scanString:@"&Ograve;" intoString:NULL])
			[result appendFormat:@"%C", 210];
		else if ([scanner scanString:@"&Oacute;" intoString:NULL])
			[result appendFormat:@"%C", 211];
		else if ([scanner scanString:@"&Ocirc;" intoString:NULL])
			[result appendFormat:@"%C", 212];
		else if ([scanner scanString:@"&Otilde;" intoString:NULL])
			[result appendFormat:@"%C", 213];
		else if ([scanner scanString:@"&Ouml;" intoString:NULL])
			[result appendFormat:@"%C", 214];
		else if ([scanner scanString:@"&times;" intoString:NULL])
			[result appendFormat:@"%C", 215];
		else if ([scanner scanString:@"&Oslash;" intoString:NULL])
			[result appendFormat:@"%C", 216];
		else if ([scanner scanString:@"&Ugrave;" intoString:NULL])
			[result appendFormat:@"%C", 217];
		else if ([scanner scanString:@"&Uacute;" intoString:NULL])
			[result appendFormat:@"%C", 218];
		else if ([scanner scanString:@"&Ucirc;" intoString:NULL])
			[result appendFormat:@"%C", 219];
		else if ([scanner scanString:@"&Uuml;" intoString:NULL])
			[result appendFormat:@"%C", 220];
		else if ([scanner scanString:@"&Yacute;" intoString:NULL])
			[result appendFormat:@"%C", 221];
		else if ([scanner scanString:@"&THORN;" intoString:NULL])
			[result appendFormat:@"%C", 222];
		else if ([scanner scanString:@"&szlig;" intoString:NULL])
			[result appendFormat:@"%C", 223];
		else if ([scanner scanString:@"&agrave;" intoString:NULL])
			[result appendFormat:@"%C", 224];
		else if ([scanner scanString:@"&aacute;" intoString:NULL])
			[result appendFormat:@"%C", 225];
		else if ([scanner scanString:@"&acirc;" intoString:NULL])
			[result appendFormat:@"%C", 226];
		else if ([scanner scanString:@"&atilde;" intoString:NULL])
			[result appendFormat:@"%C", 227];
		else if ([scanner scanString:@"&auml;" intoString:NULL])
			[result appendFormat:@"%C", 228];
		else if ([scanner scanString:@"&aring;" intoString:NULL])
			[result appendFormat:@"%C", 229];
		else if ([scanner scanString:@"&aelig;" intoString:NULL])
			[result appendFormat:@"%C", 230];
		else if ([scanner scanString:@"&ccedil;" intoString:NULL])
			[result appendFormat:@"%C", 231];
		else if ([scanner scanString:@"&egrave;" intoString:NULL])
			[result appendFormat:@"%C", 232];
		else if ([scanner scanString:@"&eacute;" intoString:NULL])
			[result appendFormat:@"%C", 233];
		else if ([scanner scanString:@"&ecirc;" intoString:NULL])
			[result appendFormat:@"%C", 234];
		else if ([scanner scanString:@"&euml;" intoString:NULL])
			[result appendFormat:@"%C", 235];
		else if ([scanner scanString:@"&igrave;" intoString:NULL])
			[result appendFormat:@"%C", 236];
		else if ([scanner scanString:@"&iacute;" intoString:NULL])
			[result appendFormat:@"%C", 237];
		else if ([scanner scanString:@"&icirc;" intoString:NULL])
			[result appendFormat:@"%C", 238];
		else if ([scanner scanString:@"&iuml;" intoString:NULL])
			[result appendFormat:@"%C", 239];
		else if ([scanner scanString:@"&eth;" intoString:NULL])
			[result appendFormat:@"%C", 240];
		else if ([scanner scanString:@"&ntilde;" intoString:NULL])
			[result appendFormat:@"%C", 241];
		else if ([scanner scanString:@"&ograve;" intoString:NULL])
			[result appendFormat:@"%C", 242];
		else if ([scanner scanString:@"&oacute;" intoString:NULL])
			[result appendFormat:@"%C", 243];
		else if ([scanner scanString:@"&ocirc;" intoString:NULL])
			[result appendFormat:@"%C", 244];
		else if ([scanner scanString:@"&otilde;" intoString:NULL])
			[result appendFormat:@"%C", 245];
		else if ([scanner scanString:@"&ouml;" intoString:NULL])
			[result appendFormat:@"%C", 246];
		else if ([scanner scanString:@"&divide;" intoString:NULL])
			[result appendFormat:@"%C", 247];
		else if ([scanner scanString:@"&oslash;" intoString:NULL])
			[result appendFormat:@"%C", 248];
		else if ([scanner scanString:@"&ugrave;" intoString:NULL])
			[result appendFormat:@"%C", 249];
		else if ([scanner scanString:@"&uacute;" intoString:NULL])
			[result appendFormat:@"%C", 250];
		else if ([scanner scanString:@"&ucirc;" intoString:NULL])
			[result appendFormat:@"%C", 251];
		else if ([scanner scanString:@"&uuml;" intoString:NULL])
			[result appendFormat:@"%C", 252];
		else if ([scanner scanString:@"&yacute;" intoString:NULL])
			[result appendFormat:@"%C", 253];
		else if ([scanner scanString:@"&thorn;" intoString:NULL])
			[result appendFormat:@"%C", 254];
		else if ([scanner scanString:@"&yuml;" intoString:NULL])
			[result appendFormat:@"%C", 255];
		else if ([scanner scanString:@"&OElig;" intoString:NULL])
			[result appendFormat:@"%C", 338];
		else if ([scanner scanString:@"&oelig;" intoString:NULL])
			[result appendFormat:@"%C", 339];
		else if ([scanner scanString:@"&Scaron;" intoString:NULL])
			[result appendFormat:@"%C", 352];
		else if ([scanner scanString:@"&scaron;" intoString:NULL])
			[result appendFormat:@"%C", 353];
		else if ([scanner scanString:@"&Yuml;" intoString:NULL])
			[result appendFormat:@"%C", 376];
		else if ([scanner scanString:@"&fnof;" intoString:NULL])
			[result appendFormat:@"%C", 402];
		else if ([scanner scanString:@"&circ;" intoString:NULL])
			[result appendFormat:@"%C", 710];
		else if ([scanner scanString:@"&tilde;" intoString:NULL])
			[result appendFormat:@"%C", 732];
		else if ([scanner scanString:@"&Alpha;" intoString:NULL])
			[result appendFormat:@"%C", 913];
		else if ([scanner scanString:@"&Beta;" intoString:NULL])
			[result appendFormat:@"%C", 914];
		else if ([scanner scanString:@"&Gamma;" intoString:NULL])
			[result appendFormat:@"%C", 915];
		else if ([scanner scanString:@"&Delta;" intoString:NULL])
			[result appendFormat:@"%C", 916];
		else if ([scanner scanString:@"&Epsilon;" intoString:NULL])
			[result appendFormat:@"%C", 917];
		else if ([scanner scanString:@"&Zeta;" intoString:NULL])
			[result appendFormat:@"%C", 918];
		else if ([scanner scanString:@"&Eta;" intoString:NULL])
			[result appendFormat:@"%C", 919];
		else if ([scanner scanString:@"&Theta;" intoString:NULL])
			[result appendFormat:@"%C", 920];
		else if ([scanner scanString:@"&Iota;" intoString:NULL])
			[result appendFormat:@"%C", 921];
		else if ([scanner scanString:@"&Kappa;" intoString:NULL])
			[result appendFormat:@"%C", 922];
		else if ([scanner scanString:@"&Lambda;" intoString:NULL])
			[result appendFormat:@"%C", 923];
		else if ([scanner scanString:@"&Mu;" intoString:NULL])
			[result appendFormat:@"%C", 924];
		else if ([scanner scanString:@"&Nu;" intoString:NULL])
			[result appendFormat:@"%C", 925];
		else if ([scanner scanString:@"&Xi;" intoString:NULL])
			[result appendFormat:@"%C", 926];
		else if ([scanner scanString:@"&Omicron;" intoString:NULL])
			[result appendFormat:@"%C", 927];
		else if ([scanner scanString:@"&Pi;" intoString:NULL])
			[result appendFormat:@"%C", 928];
		else if ([scanner scanString:@"&Rho;" intoString:NULL])
			[result appendFormat:@"%C", 929];
		else if ([scanner scanString:@"&Sigma;" intoString:NULL])
			[result appendFormat:@"%C", 931];
		else if ([scanner scanString:@"&Tau;" intoString:NULL])
			[result appendFormat:@"%C", 932];
		else if ([scanner scanString:@"&Upsilon;" intoString:NULL])
			[result appendFormat:@"%C", 933];
		else if ([scanner scanString:@"&Phi;" intoString:NULL])
			[result appendFormat:@"%C", 934];
		else if ([scanner scanString:@"&Chi;" intoString:NULL])
			[result appendFormat:@"%C", 935];
		else if ([scanner scanString:@"&Psi;" intoString:NULL])
			[result appendFormat:@"%C", 936];
		else if ([scanner scanString:@"&Omega;" intoString:NULL])
			[result appendFormat:@"%C", 937];
		else if ([scanner scanString:@"&alpha;" intoString:NULL])
			[result appendFormat:@"%C", 945];
		else if ([scanner scanString:@"&beta;" intoString:NULL])
			[result appendFormat:@"%C", 946];
		else if ([scanner scanString:@"&gamma;" intoString:NULL])
			[result appendFormat:@"%C", 947];
		else if ([scanner scanString:@"&delta;" intoString:NULL])
			[result appendFormat:@"%C", 948];
		else if ([scanner scanString:@"&epsilon;" intoString:NULL])
			[result appendFormat:@"%C", 949];
		else if ([scanner scanString:@"&zeta;" intoString:NULL])
			[result appendFormat:@"%C", 950];
		else if ([scanner scanString:@"&eta;" intoString:NULL])
			[result appendFormat:@"%C", 951];
		else if ([scanner scanString:@"&theta;" intoString:NULL])
			[result appendFormat:@"%C", 952];
		else if ([scanner scanString:@"&iota;" intoString:NULL])
			[result appendFormat:@"%C", 953];
		else if ([scanner scanString:@"&kappa;" intoString:NULL])
			[result appendFormat:@"%C", 954];
		else if ([scanner scanString:@"&lambda;" intoString:NULL])
			[result appendFormat:@"%C", 955];
		else if ([scanner scanString:@"&mu;" intoString:NULL])
			[result appendFormat:@"%C", 956];
		else if ([scanner scanString:@"&nu;" intoString:NULL])
			[result appendFormat:@"%C", 957];
		else if ([scanner scanString:@"&xi;" intoString:NULL])
			[result appendFormat:@"%C", 958];
		else if ([scanner scanString:@"&omicron;" intoString:NULL])
			[result appendFormat:@"%C", 959];
		else if ([scanner scanString:@"&pi;" intoString:NULL])
			[result appendFormat:@"%C", 960];
		else if ([scanner scanString:@"&rho;" intoString:NULL])
			[result appendFormat:@"%C", 961];
		else if ([scanner scanString:@"&sigmaf;" intoString:NULL])
			[result appendFormat:@"%C", 962];
		else if ([scanner scanString:@"&sigma;" intoString:NULL])
			[result appendFormat:@"%C", 963];
		else if ([scanner scanString:@"&tau;" intoString:NULL])
			[result appendFormat:@"%C", 964];
		else if ([scanner scanString:@"&upsilon;" intoString:NULL])
			[result appendFormat:@"%C", 965];
		else if ([scanner scanString:@"&phi;" intoString:NULL])
			[result appendFormat:@"%C", 966];
		else if ([scanner scanString:@"&chi;" intoString:NULL])
			[result appendFormat:@"%C", 967];
		else if ([scanner scanString:@"&psi;" intoString:NULL])
			[result appendFormat:@"%C", 968];
		else if ([scanner scanString:@"&omega;" intoString:NULL])
			[result appendFormat:@"%C", 969];
		else if ([scanner scanString:@"&thetasym;" intoString:NULL])
			[result appendFormat:@"%C", 977];
		else if ([scanner scanString:@"&upsih;" intoString:NULL])
			[result appendFormat:@"%C", 978];
		else if ([scanner scanString:@"&piv;" intoString:NULL])
			[result appendFormat:@"%C", 982];
		else if ([scanner scanString:@"&ensp;" intoString:NULL])
			[result appendFormat:@"%C", 8194];
		else if ([scanner scanString:@"&emsp;" intoString:NULL])
			[result appendFormat:@"%C", 8195];
		else if ([scanner scanString:@"&thinsp;" intoString:NULL])
			[result appendFormat:@"%C", 8201];
		else if ([scanner scanString:@"&zwnj;" intoString:NULL])
			[result appendFormat:@"%C", 8204];
		else if ([scanner scanString:@"&zwj;" intoString:NULL])
			[result appendFormat:@"%C", 8205];
		else if ([scanner scanString:@"&lrm;" intoString:NULL])
			[result appendFormat:@"%C", 8206];
		else if ([scanner scanString:@"&rlm;" intoString:NULL])
			[result appendFormat:@"%C", 8207];
		else if ([scanner scanString:@"&sbquo;" intoString:NULL])
			[result appendFormat:@"%C", 8218];
		else if ([scanner scanString:@"&bdquo;" intoString:NULL])
			[result appendFormat:@"%C", 8222];
		else if ([scanner scanString:@"&dagger;" intoString:NULL])
			[result appendFormat:@"%C", 8224];
		else if ([scanner scanString:@"&Dagger;" intoString:NULL])
			[result appendFormat:@"%C", 8225];
		else if ([scanner scanString:@"&permil;" intoString:NULL])
			[result appendFormat:@"%C", 8240];
		else if ([scanner scanString:@"&prime;" intoString:NULL])
			[result appendFormat:@"%C", 8242];
		else if ([scanner scanString:@"&Prime;" intoString:NULL])
			[result appendFormat:@"%C", 8243];
		else if ([scanner scanString:@"&lsaquo;" intoString:NULL])
			[result appendFormat:@"%C", 8249];
		else if ([scanner scanString:@"&rsaquo;" intoString:NULL])
			[result appendFormat:@"%C", 8250];
		else if ([scanner scanString:@"&oline;" intoString:NULL])
			[result appendFormat:@"%C", 8254];
		else if ([scanner scanString:@"&frasl;" intoString:NULL])
			[result appendFormat:@"%C", 8260];
		else if ([scanner scanString:@"&euro;" intoString:NULL])
			[result appendFormat:@"%C", 8364];
		else if ([scanner scanString:@"&image;" intoString:NULL])
			[result appendFormat:@"%C", 8465];
		else if ([scanner scanString:@"&weierp;" intoString:NULL])
			[result appendFormat:@"%C", 8472];
		else if ([scanner scanString:@"&real;" intoString:NULL])
			[result appendFormat:@"%C", 8476];
		else if ([scanner scanString:@"&trade;" intoString:NULL])
			[result appendFormat:@"%C", 8482];
		else if ([scanner scanString:@"&alefsym;" intoString:NULL])
			[result appendFormat:@"%C", 8501];
		else if ([scanner scanString:@"&larr;" intoString:NULL])
			[result appendFormat:@"%C", 8592];
		else if ([scanner scanString:@"&uarr;" intoString:NULL])
			[result appendFormat:@"%C", 8593];
		else if ([scanner scanString:@"&rarr;" intoString:NULL])
			[result appendFormat:@"%C", 8594];
		else if ([scanner scanString:@"&darr;" intoString:NULL])
			[result appendFormat:@"%C", 8595];
		else if ([scanner scanString:@"&harr;" intoString:NULL])
			[result appendFormat:@"%C", 8596];
		else if ([scanner scanString:@"&crarr;" intoString:NULL])
			[result appendFormat:@"%C", 8629];
		else if ([scanner scanString:@"&lArr;" intoString:NULL])
			[result appendFormat:@"%C", 8656];
		else if ([scanner scanString:@"&uArr;" intoString:NULL])
			[result appendFormat:@"%C", 8657];
		else if ([scanner scanString:@"&rArr;" intoString:NULL])
			[result appendFormat:@"%C", 8658];
		else if ([scanner scanString:@"&dArr;" intoString:NULL])
			[result appendFormat:@"%C", 8659];
		else if ([scanner scanString:@"&hArr;" intoString:NULL])
			[result appendFormat:@"%C", 8660];
		else if ([scanner scanString:@"&forall;" intoString:NULL])
			[result appendFormat:@"%C", 8704];
		else if ([scanner scanString:@"&part;" intoString:NULL])
			[result appendFormat:@"%C", 8706];
		else if ([scanner scanString:@"&exist;" intoString:NULL])
			[result appendFormat:@"%C", 8707];
		else if ([scanner scanString:@"&empty;" intoString:NULL])
			[result appendFormat:@"%C", 8709];
		else if ([scanner scanString:@"&nabla;" intoString:NULL])
			[result appendFormat:@"%C", 8711];
		else if ([scanner scanString:@"&isin;" intoString:NULL])
			[result appendFormat:@"%C", 8712];
		else if ([scanner scanString:@"&notin;" intoString:NULL])
			[result appendFormat:@"%C", 8713];
		else if ([scanner scanString:@"&ni;" intoString:NULL])
			[result appendFormat:@"%C", 8715];
		else if ([scanner scanString:@"&prod;" intoString:NULL])
			[result appendFormat:@"%C", 8719];
		else if ([scanner scanString:@"&sum;" intoString:NULL])
			[result appendFormat:@"%C", 8721];
		else if ([scanner scanString:@"&minus;" intoString:NULL])
			[result appendFormat:@"%C", 8722];
		else if ([scanner scanString:@"&lowast;" intoString:NULL])
			[result appendFormat:@"%C", 8727];
		else if ([scanner scanString:@"&radic;" intoString:NULL])
			[result appendFormat:@"%C", 8730];
		else if ([scanner scanString:@"&prop;" intoString:NULL])
			[result appendFormat:@"%C", 8733];
		else if ([scanner scanString:@"&infin;" intoString:NULL])
			[result appendFormat:@"%C", 8734];
		else if ([scanner scanString:@"&ang;" intoString:NULL])
			[result appendFormat:@"%C", 8736];
		else if ([scanner scanString:@"&and;" intoString:NULL])
			[result appendFormat:@"%C", 8743];
		else if ([scanner scanString:@"&or;" intoString:NULL])
			[result appendFormat:@"%C", 8744];
		else if ([scanner scanString:@"&cap;" intoString:NULL])
			[result appendFormat:@"%C", 8745];
		else if ([scanner scanString:@"&cup;" intoString:NULL])
			[result appendFormat:@"%C", 8746];
		else if ([scanner scanString:@"&int;" intoString:NULL])
			[result appendFormat:@"%C", 8747];
		else if ([scanner scanString:@"&there4;" intoString:NULL])
			[result appendFormat:@"%C", 8756];
		else if ([scanner scanString:@"&sim;" intoString:NULL])
			[result appendFormat:@"%C", 8764];
		else if ([scanner scanString:@"&cong;" intoString:NULL])
			[result appendFormat:@"%C", 8773];
		else if ([scanner scanString:@"&asymp;" intoString:NULL])
			[result appendFormat:@"%C", 8776];
		else if ([scanner scanString:@"&ne;" intoString:NULL])
			[result appendFormat:@"%C", 8800];
		else if ([scanner scanString:@"&equiv;" intoString:NULL])
			[result appendFormat:@"%C", 8801];
		else if ([scanner scanString:@"&le;" intoString:NULL])
			[result appendFormat:@"%C", 8804];
		else if ([scanner scanString:@"&ge;" intoString:NULL])
			[result appendFormat:@"%C", 8805];
		else if ([scanner scanString:@"&sub;" intoString:NULL])
			[result appendFormat:@"%C", 8834];
		else if ([scanner scanString:@"&sup;" intoString:NULL])
			[result appendFormat:@"%C", 8835];
		else if ([scanner scanString:@"&nsub;" intoString:NULL])
			[result appendFormat:@"%C", 8836];
		else if ([scanner scanString:@"&sube;" intoString:NULL])
			[result appendFormat:@"%C", 8838];
		else if ([scanner scanString:@"&supe;" intoString:NULL])
			[result appendFormat:@"%C", 8839];
		else if ([scanner scanString:@"&oplus;" intoString:NULL])
			[result appendFormat:@"%C", 8853];
		else if ([scanner scanString:@"&otimes;" intoString:NULL])
			[result appendFormat:@"%C", 8855];
		else if ([scanner scanString:@"&perp;" intoString:NULL])
			[result appendFormat:@"%C", 8869];
		else if ([scanner scanString:@"&sdot;" intoString:NULL])
			[result appendFormat:@"%C", 8901];
		else if ([scanner scanString:@"&lceil;" intoString:NULL])
			[result appendFormat:@"%C", 8968];
		else if ([scanner scanString:@"&rceil;" intoString:NULL])
			[result appendFormat:@"%C", 8969];
		else if ([scanner scanString:@"&lfloor;" intoString:NULL])
			[result appendFormat:@"%C", 8970];
		else if ([scanner scanString:@"&rfloor;" intoString:NULL])
			[result appendFormat:@"%C", 8971];
		else if ([scanner scanString:@"&lang;" intoString:NULL])
			[result appendFormat:@"%C", 9001];
		else if ([scanner scanString:@"&rang;" intoString:NULL])
			[result appendFormat:@"%C", 9002];
		else if ([scanner scanString:@"&loz;" intoString:NULL])
			[result appendFormat:@"%C", 9674];
		else if ([scanner scanString:@"&spades;" intoString:NULL])
			[result appendFormat:@"%C", 9824];
		else if ([scanner scanString:@"&clubs;" intoString:NULL])
			[result appendFormat:@"%C", 9827];
		else if ([scanner scanString:@"&hearts;" intoString:NULL])
			[result appendFormat:@"%C", 9829];
		else if ([scanner scanString:@"&diams;" intoString:NULL])
			[result appendFormat:@"%C", 9830];
		else {

			// Must be an isolated & with no space after
			NSString *amp;
			[scanner scanString:@"&" intoString:&amp]; // isolated & symbol
			[result appendString:amp];

		}
		
    } while (![scanner isAtEnd]);

	// Finish
	NSString *resultingString = [NSString stringWithString:result];
	[result release];
	return resultingString;
	
}

// Needs more work to encode more entities
- (NSString *)stringByEncodingXMLEntities {
	
	// Scanner
	NSScanner *scanner = [[NSScanner alloc] initWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	NSMutableString *result = [[NSMutableString alloc] init];
	NSString *temp;
	NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@"&\"'<>"];
	[scanner setCharactersToBeSkipped:nil];
	
	// Scan
	while (![scanner isAtEnd]) {
		
		// Get non new line or whitespace characters
		temp = nil;
		[scanner scanUpToCharactersFromSet:characters intoString:&temp];
		if (temp) [result appendString:temp];
		
		// Replace with encoded entities
		if ([scanner scanString:@"&" intoString:NULL])
			[result appendString:@"&amp;"];
		else if ([scanner scanString:@"'" intoString:NULL])
			[result appendString:@"&apos;"];
		else if ([scanner scanString:@"\"" intoString:NULL])
			[result appendString:@"&quot;"];
		else if ([scanner scanString:@"<" intoString:NULL])
			[result appendString:@"&lt;"];
		else if ([scanner scanString:@">" intoString:NULL])
			[result appendString:@"&gt;"];

	}
	
	// Cleanup
	[scanner release];
	
	// Return
	NSString *retString = [NSString stringWithString:result];
	[result release];
	return retString;
	
}

- (NSString *)stringByStrippingTags {
	
	// Find first & and short-cut if we can
	NSUInteger ampIndex = [self rangeOfString:@"<" options:NSLiteralSearch].location;
	if (ampIndex == NSNotFound) {
		return [NSString stringWithString:self]; // return copy of string as no tags found
	}
	
	// Scan and find all tags
	NSScanner *scanner = [NSScanner scannerWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	NSMutableSet *tags = [[NSMutableSet alloc] init];
	NSString *tag;
	do {
		
		// Scan up to <
		tag = nil;
		[scanner scanUpToString:@"<" intoString:NULL];
		[scanner scanUpToString:@">" intoString:&tag];
		
		// Add to set
		if (tag) {
			NSString *t = [[NSString alloc] initWithFormat:@"%@>", tag];
			[tags addObject:t];
			[t release];
		}
		
	} while (![scanner isAtEnd]);
	
	// Strings
	NSMutableString *result = [[NSMutableString alloc] initWithString:self];
	NSString *finalString;
	
	// Replace tags
	NSString *replacement;
	for (NSString *t in tags) {
		
		// Replace tag with space unless it's an inline element
		replacement = @" ";
		if ([t isEqualToString:@"<a>"] ||
			[t isEqualToString:@"</a>"] ||
			[t isEqualToString:@"<span>"] ||
			[t isEqualToString:@"</span>"] ||
			[t isEqualToString:@"<strong>"] ||
			[t isEqualToString:@"</strong>"] ||
			[t isEqualToString:@"<em>"] ||
			[t isEqualToString:@"</em>"]) {
			replacement = @"";
		}
		
		// Replace
		[result replaceOccurrencesOfString:t 
								withString:replacement
								   options:NSLiteralSearch 
									 range:NSMakeRange(0, result.length)];
	}
	
	// Remove multi-spaces and line breaks
	finalString = [result stringByRemovingNewLinesAndWhitespace];
	
	// Cleanup & return
	[result release];
	[tags release];
    return finalString;
	
}

- (NSString *)stringWithNewLinesAsBRs {
	
	// Strange New lines:
	//	Next Line, U+0085
	//	Form Feed, U+000C
	//	Line Separator, U+2028
	//	Paragraph Separator, U+2029
	
	// Scanner
	NSScanner *scanner = [[NSScanner alloc] initWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	NSMutableString *result = [[NSMutableString alloc] init];
	NSString *temp;
	NSCharacterSet *newLineCharacters = [NSCharacterSet characterSetWithCharactersInString:
										 [NSString stringWithFormat:@"\n\r%C%C%C%C", 0x0085, 0x000C, 0x2028, 0x2029]];
	// Scan
	do {
		
		// Get non new line characters
		temp = nil;
		[scanner scanUpToCharactersFromSet:newLineCharacters intoString:&temp];
		if (temp) [result appendString:temp];
		temp = nil;
		
		// Add <br /> s
		if ([scanner scanString:@"\r\n" intoString:nil]) {
			
			// Combine \r\n into just 1 <br />
			[result appendString:@"<br />"];
			
		} else if ([scanner scanCharactersFromSet:newLineCharacters intoString:&temp]) {
			
			// Scan other new line characters and add <br /> s
			if (temp) {
				for (int i = 0; i < temp.length; i++) {
					[result appendString:@"<br />"];
				}
			}
			
		}
		
	} while (![scanner isAtEnd]);
	
	// Cleanup & return
	[scanner release];
	NSString *retString = [NSString stringWithString:result];
	[result release];
	return retString;

}

- (NSString *)stringByRemovingNewLinesAndWhitespace {
	
	// Strange New lines:
	//	Next Line, U+0085
	//	Form Feed, U+000C
	//	Line Separator, U+2028
	//	Paragraph Separator, U+2029
	
	// Scanner
	NSScanner *scanner = [[NSScanner alloc] initWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	NSMutableString *result = [[NSMutableString alloc] init];
	NSString *temp;
	NSCharacterSet *newLineAndWhitespaceCharacters = [NSCharacterSet characterSetWithCharactersInString:
													  [NSString stringWithFormat:@" \t\n\r%C%C%C%C", 0x0085, 0x000C, 0x2028, 0x2029]];
	// Scan
	while (![scanner isAtEnd]) {
		
		// Get non new line or whitespace characters
		temp = nil;
		[scanner scanUpToCharactersFromSet:newLineAndWhitespaceCharacters intoString:&temp];
		if (temp) [result appendString:temp];
		
		// Replace with a space
		if ([scanner scanCharactersFromSet:newLineAndWhitespaceCharacters intoString:NULL]) {
			if (result.length > 0 && ![scanner isAtEnd]) // Dont append space to beginning or end of result
				[result appendString:@" "];
		}
		
	}
	
	// Cleanup
	[scanner release];
	
	// Return
	NSString *retString = [NSString stringWithString:result];
	[result release];
	return retString;

}

@end
