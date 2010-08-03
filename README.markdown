MWFeedParser
===============

MWFeedParser is an RSS and Atom web feed parser for iOS. It is a very simple implementation and only parses the bare essential information about a feed and it's items, such as titles, links, dates, and descriptions / content.

If you use MWFeedParser on your iPhone/iPad app then please do let me know, I'd love to check it out :)


Demo / Example App
===============

There is an example iPhone application within the project which demonstrates how to use the parser to display the title of a feed, list all of the feed items, and display an item in more detail when tapped.


Setting up the parser
===============

Create parser:

	// Create feed parser and pass the URL of the feed
	feedParser = [[MWFeedParser alloc] initWithFeedURL:@"http://www.shoutfilm.com/rss/staff-blog/"];

Set delegate:

	// Delegate must conform to `MWFeedParserDelegate`
	feedParser.delegate = self;
	
Set the parsing type. Options are `ParseTypeFull`, `ParseTypeInfoOnly`, `ParseTypeItemsOnly`. Info refers to the information about the feed, such as it's title and description. Items are the individual items or stories.

	// Parse the feeds info (title, link) and all feed items
	feedParser.feedParseType = ParseTypeFull;
	
Set whether the parser should connect and download the feed data synchronously or asynchronously:

	// Connection type
	feedParser.connectionType = ConnectionTypeSynchronously;
	
Initiate parsing:

	// Begin parsing
	[feedParser parse];
	
The parser will then download and parse the feed. If at any time you wish to stop the parsing, you can call:

	// Stop feed download / parsing
	[feedParser stopParsing];
	
The `stopParsing` method will stop the downloading and parsing of the feed immediately.
	

Reading the feed data
===============

Once parsing has been initiated, the delegate will receive the feed data as it is parsed.

	- (void)feedParserDidStart:(MWFeedParser *)parser; // Called when data has downloaded and parsing has begun
	- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info; // Provides info about the feed
	- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item; // Provides info about a feed item
	- (void)feedParserDidFinish:(MWFeedParser *)parser; // Parsing complete or stopped at any time by `stopParsing`
	- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error; // Parsing failed

`MWFeedInfo` and `MWFeedItem` contains properties (title, link, summary, etc.) that will hold the parsed data.

*Important* There are some occasions where feeds do not contain some information, such as titles, links or summaries. Before using any data, you should check to see if that data exists:

	NSString *title = item.title ? item.title : @"[No Title]";
	NSString *link = item.link ? item.link : @"[No Link]";
	NSString *summary = item.summary ? item.summary : @"[No Summary]";

The method `feedParserDidFinish:` will only be called when the feed has successfully parsed, or has been stopped by a call to `stopParsing`. To determine whether the parsing completed successfully, or was stopped, you can call `isStopped`.

For a usage example, please see `RootViewController.m` in the demo project.


Using the data
===============

The data returned, specifically in the `summary` and `content` properties, may contain HTML elements and encoded characters. An NSString category (NSString+HTML) has been provided which will allow you to manipulate this data. The methods available for your convenience are:

	- (NSString *)stringByStrippingTags;
	- (NSString *)stringWithNewLinesAsBRs;
	- (NSString *)stringByRemovingNewLinesAndWhitespace;
	- (NSString *)stringByDecodingHTMLEntities;
	- (NSString *)stringByEncodingHTMLEntities;

An example of this would be:

	NSString *summary = [[[item.summary stringByStrippingTags] stringByRemovingNewLinesAndWhitespace] stringByDecodingHTMLEntities];


Debugging problems
===============

If for some reason the parser doesn't seem to be working, try enabling Debug Logging in `MWFeedParser.h`. This will log error messages to the console and help you diagnose the problem. Error codes and their descriptions can be found at the top of `MWFeedParser.h`.


Other information
===============

MWFeedParser is not currently thread-safe.


Adding to your project
===============

1. Open `MWFeedParser.xcodeproj`.
2. Drag the `MWFeedParser` & `Categories` groups into your project, ensuring you check **Copy items into destination group's folder**.
3. Import `MWFeedParser.h` into your source as required.


Outstanding tasks
===============

* Create optimised single-pass NSString method that encapsulates `stringByStrippingTags`, `stringByRemovingNewLinesAndWhitespace` and `stringByDecodingHTMLEntities` as they sit together perfectly in that order and are commonly used together.
* Parsing of more feed data and elements if required.
* Provide functionality to list available feeds when given the URL to a webpage with one or more web feeds associated with it.
* Open to suggestions!


License
===============

Copyright (c) 2010 Michael Waterfall

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


Contact
===============

Twitter: 	<http://twitter.com/mwaterfall>