//
//  WWOffscreenWebView.m
//  WikiWalker
//
//  Created by Temp Kelan on 4/4/07.
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import "WWOffscreenWebView.h"


@implementation WWOffscreenWebView

- (id)initWithFrame:(NSRect)frame {
	self = [super init];
	if (self != nil) {
		
		_webView = [[WebView alloc] initWithFrame:frame
                                       frameName:@"YRKmainFrame"
                                       groupName:@"YRKgroup"];
		[_webView setFrameLoadDelegate:self];
		
		_listOfWikiLinks = [[NSMutableArray alloc] init];
		_haveParsedLinks = NO;
		_imageOfContent = [[NSImage alloc] init];
        [self setPageTitle:@"No Title"];
		_pageTitle = [[NSString alloc] initWithString:@"Title"];
	}
	return self;
}

- (void)dealloc {
	[_webView release];
    [_listOfWikiLinks release];
    [self setPageTitle:nil];
	[_startingURL release];
	
    [super dealloc];
}

- (void)startLoadingRandomPage {
	NSLog(@"%s", _cmd);
	
	// Don't want to try to pick a random link until we've loaded all the links.  Normally this isn't an issues with the 15 second interval, but the first time it is.  So, if we haven't parsed links yet, just try again in 1 second.
	
	if(_haveParsedLinks) {
		if([_listOfWikiLinks count]>0) {
			unsigned randomNum = SSRandomIntBetween(0,[_listOfWikiLinks count]-1);
			NSURL *randomURL = [[_listOfWikiLinks objectAtIndex:randomNum] objectForKey:@"url"];
			[self startLoadingPageFromURL:randomURL];
		}
		else {
			NSLog(@"%s LOADING STARING PAGE BY DEFAULT", _cmd);
			[self startLoadingPageFromURL:_startingURL];
		}
	}
	else {
		NSLog(@"%s haven't parsed links yet.  wait 1 second...", _cmd);
		[self performSelector:@selector(startLoadingRandomPage) withObject:nil afterDelay:(NSTimeInterval)1];
	}
}

- (void)startLoadingPageFromURL:(NSURL *)newURL {
	NSLog(@"%s %@", _cmd, [newURL absoluteURL]);
	if(![[newURL absoluteString] isEqualTo:_currentURL]) {
		_currentURL = [[newURL standardizedURL] retain];
		[[_webView mainFrame] loadRequest:[NSURLRequest requestWithURL:_currentURL]];
		
		// If this is the first URL, save it
		if(_startingURL == nil) {
			_startingURL = [newURL retain];
		}
	}
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Accessors
//------------------------------------------------------------------------------

- (void)setClient:(id)newClient {
	_client = newClient;
}

- (NSImage *)imageOfContent {
	return _imageOfContent;
}

- (NSString *)pageTitle {
	return _pageTitle;
}
- (void)setPageTitle:(NSString *)newTitle {
    NSString *oldPageTitle = _pageTitle;
	_pageTitle = [newTitle retain];
	[oldPageTitle release];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark For Multiple Threads
//------------------------------------------------------------------------------

- (void)prepareImageOnNewThread {
	NSLog(@"%s start", _cmd);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self prepareImage];
	[pool release];
	NSLog(@"%s done", _cmd);
}

- (void)getWikiLinksFromNodeTreeOnNewThread:(DOMNode *)parent {
	NSLog(@"%s start", _cmd);
	[_listOfWikiLinks removeAllObjects];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	[self getWikiLinksFromNodeTree:parent];
	[self getWikiLinksWithJS];
	_haveParsedLinks = YES;
	[pool release];
	NSLog(@"%s done, got %d links", _cmd, [_listOfWikiLinks count]);
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark For internal use
//------------------------------------------------------------------------------

- (void)prepareImage {
	NSLog(@"%s", _cmd);
	NSView *view = [[[_webView mainFrame] frameView] documentView];
	NSRect viewRect = [view bounds];
	NSBitmapImageRep *imageRep = [view bitmapImageRepForCachingDisplayInRect:viewRect];
	
	[view cacheDisplayInRect:viewRect toBitmapImageRep:imageRep];
	
	NSSize repSize = [imageRep size];
	
	if(repSize.width > 0) {
		NSImage *oldImage, *newImage;
		
		// Make the new image
		newImage = [[NSImage alloc] initWithSize:viewRect.size];
		[newImage addRepresentation:imageRep];
		[newImage setScalesWhenResized:NO];
		
		// Do the switch
		oldImage = _imageOfContent;
		_imageOfContent = newImage;
		
		[oldImage release];
	}
		
	// Tell our client that the image is ready
	if([_client respondsToSelector:@selector(imageIsReady:)]) {
		[_client imageIsReady:self];
	}
}


- (void)getWikiLinksWithJS {
	int i, numLinks;
	
	numLinks = [[_webView stringByEvaluatingJavaScriptFromString: @"document.links.length"] intValue];
	
	for (i = 0; i < numLinks; i++) {
		NSString *link = [_webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.links[%d].href", i]];
		[self addToListOfLinksIfGood: link withLinkNumber:[NSNumber numberWithInt:i]];
	}
}


- (void)addToListOfLinksIfGood:(NSString *)newLink withLinkNumber:(NSNumber *)linkNumber {
    
    // Only want links to wiki pages
	if([newLink rangeOfString:@"en.wikipedia.org/wiki/"].location == NSNotFound) { // get only links that start with wiki
		return;
	}

    // But don't want any of the following "special" links
	if([newLink rangeOfString:@"/wiki/Talk:"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Special"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Help"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Image"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Wiktionary"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Wikipedia:"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Main_Page"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Portal:"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/profit_organization"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/Charitable_organization"].location != NSNotFound) {
		return;
	}
	if([newLink rangeOfString:@"/wiki/501"].location != NSNotFound) {
		return;
	}
    
    // TODO: also reject the link if it's to the page we're currently on
	
	// If we made it this far, its a keeper
	NSDictionary *linkInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSURL URLWithString:newLink relativeToURL:_currentURL], @"url",
		linkNumber, @"index",
		nil];
	[_listOfWikiLinks addObject:linkInfo];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark WebView delegate methods
//------------------------------------------------------------------------------

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    
	// Check to make sure its our webview that the notification came from.  This is because if 2 instances of the screensaver are running (ie. on multiple monitors, or even when it's showing the preview in the sys prefs, and you press the "Test" button)
	if(sender != _webView) {
        return;
	}
	
	if(frame != [sender mainFrame]) {
		return;
	}
    
	_haveParsedLinks = NO;
	
	[NSThread detachNewThreadSelector:@selector(prepareImageOnNewThread)
                             toTarget:self
                           withObject:nil];

	[NSThread detachNewThreadSelector:@selector(getWikiLinksFromNodeTreeOnNewThread:)
                             toTarget:self
                           withObject:[[_webView mainFrame] DOMDocument]];
}


- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
	if(sender != _webView) {
        return;
	}
    
    // Get the displayable title of the page by removing " - Wikipedia, the free encyclopedia" from the end of the original page title
	NSRange endRange = [title rangeOfString:@" - Wikipedia, the free encyclopedia"];
	if(endRange.location != NSNotFound) {
		title = [[title substringToIndex:endRange.location] retain];
	}
    
    [self setPageTitle:title];
}


@end
