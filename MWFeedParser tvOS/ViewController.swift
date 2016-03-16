import UIKit

class ViewController: UIViewController, MWFeedParserDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let URL = NSURL(string: "http://techcrunch.com/feed/")
        let feedParser = MWFeedParser(feedURL: URL)
        feedParser.delegate = self
        feedParser.parse()
    }
    
    func feedParserDidStart(parser: MWFeedParser) {
        
    }
    
    func feedParser(parser: MWFeedParser, didParseFeedItem item: MWFeedItem) {
        
    }
    
    func feedParserDidFinish(parser: MWFeedParser) {
        
    }
    
    func feedParser(parser: MWFeedParser!, didFailWithError error: NSError!) {
        
    }
}