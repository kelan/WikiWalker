//
//  WWOffscreenWebView.m
//  WikiWalker
//
//  Created by Temp Kelan on 4/4/07.
//  Copyright 2007 Yeah Right Keller. All rights reserved.
//

#import "WWOffscreenWebView.h"


@implementation WWOffscreenWebView

- (id)initWithFrame:(NSRect)frame {
	self = [super init];
	if (self != nil) {
		
		webView = [[WebView alloc] initWithFrame:frame
                                       frameName:@"YRKmainFrame"
                                       groupName:@"YRKgroup"];
		[webView setFrameLoadDelegate:self];
		
		// Register to see when webview is done loading
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(webViewDidFinishLoading:)
													 name:WebViewProgressFinishedNotification
												   object:nil];
		
		listOfWikiLinks = [[NSMutableArray alloc] init];
		pageTitle = [[NSString alloc] initWithString:@"Title"];
	}
	return self;
}

- (void)dealloc {
	[webView release];
    [listOfWikiLinks release];
	[pageTitle release];
	[startingURL release];
	
    [super dealloc];
}

- (void)startLoadingRandomPage {
	NSLog(@"%s", _cmd);
	if([listOfWikiLinks count]>0) {
		unsigned randomNum = SSRandomIntBetween(0,[listOfWikiLinks count]-1);
		NSURL *randomURL = [listOfWikiLinks objectAtIndex:randomNum];
		[self startLoadingPageFromURL:randomURL];
	}
	else {
		NSLog(@"%s LOADING STARING PAGE BY DEFAULT", _cmd);
		[self startLoadingPageFromURL:startingURL];
	}
}

- (void)startLoadingPageFromURL:(NSURL *)newURL {
	NSLog(@"%s %@", _cmd, [newURL absoluteURL]);
	if(![[newURL absoluteString] isEqualTo:currentURL]) {
		currentURL = [[newURL standardizedURL] retain];
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:currentURL]];
		
		// If this is the first URL, save it
		if(startingURL == nil) {
			NSLog(@"%s first url, save it", _cmd);
			startingURL = [newURL retain];
		}
	}
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Accessors
//------------------------------------------------------------------------------

- (NSImage *)imageOfContent {
	NSLog(@"%s", _cmd);
	return imageOfContent;
}

- (NSString *)pageTitle {
	NSLog(@"%s", _cmd);
	return pageTitle;
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private
//------------------------------------------------------------------------------

- (void)webViewDidFinishLoading:(NSNotification *)notification {
	NSLog(@"%s %@", _cmd, [currentURL absoluteURL]);
//	DOMNode *node = [[[[[[[[[notification object] mainFrame] DOMDocument] childNodes] item:0] childNodes] item:0] childNodes] item:3];
//	NSLog(@"%s DOMDoc has child: %@ - %@", _cmd, [node nodeName], [node nodeValue]);
	// check to make sure its our webview that posted the notification, because there can be more than 1 for this process, if we're running multiple monitors, or even when you press "Test" from in System Prefs (this is what was causing my super crashiness earlier)
	// the notification object is the webview
	if([notification object] == webView) {
		if(imageOfContent == nil) {
			NSLog(@"%s first time, not threaded", _cmd);
			[listOfWikiLinks removeAllObjects];
			[self getWikiLinksFromNodeTree:[[webView mainFrame] DOMDocument]];
			[self prepareImage];
		}
		else {
			NSLog(@"%s 2nd time, threaded", _cmd);
			[NSThread detachNewThreadSelector:@selector(prepareImageOnNewThread)
		                             toTarget:self
		                           withObject:nil];

			[listOfWikiLinks removeAllObjects];
			[NSThread detachNewThreadSelector:@selector(getWikiLinksFromNodeTreeOnNewThread:)
		                             toTarget:self
		                           withObject:[[webView mainFrame] DOMDocument]];
		}
	}
}

- (void)prepareImage {
	NSLog(@"%s", _cmd);
	NSView *view = [[[webView mainFrame] frameView] documentView];
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
		oldImage = imageOfContent;
		imageOfContent = newImage;
		
		[oldImage release];
	}
	
	// Post a notification that the image is ready
	if([imageOfContent size].height > 0.0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"WWWebImageIsReady" object:self];		
	}
}


// Example from the oldest version of DOMCore on cocoadev: http://www.cocoadev.com/index.pl?DOMCore1
- (void)getWikiLinksFromNodeTree:(DOMNode *)parent {
//	NSLog(@"%s", _cmd);
	DOMNodeList *nodeList = [parent childNodes];
	unsigned i, length = [nodeList length];
	
	for (i = 0; i < length; i++) {
		DOMNode *node = [nodeList item:i];
		[self getWikiLinksFromNodeTree:node];
		
		if([[node nodeName] isCaseInsensitiveLike:@"a"]) {
			DOMNamedNodeMap *attributes = [node attributes];
			unsigned a, attCount = [attributes length];
			for (a = 0; a < attCount; a++) {
				DOMNode *att = [attributes item:a];
				if([[att nodeName] isCaseInsensitiveLike:@"href"]) {
					[self addToListOfLinksIfGood:[att nodeValue]];
				}
			}
		}
	}
}

- (void)addToListOfLinksIfGood:(NSString *)newLink {
	// Do some filtering
	
	if(![newLink hasPrefix:@"/wiki/"]) { // get only links that start with wiki
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
	
	// If we made it this far, its a keeper
	[listOfWikiLinks addObject:[NSURL URLWithString:newLink relativeToURL:currentURL]];
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self getWikiLinksFromNodeTree:parent];
	[pool release];
	NSLog(@"%s done", _cmd);
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark WebView delegate methods
//------------------------------------------------------------------------------

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	if(sender != webView) {
		NSLog(@"%s WEBVIEWS DON'T MATCH", _cmd);
	}
	NSRange endRange = [title rangeOfString:@" - Wikipedia, the free encyclopedia"];
	if(endRange.location != NSNotFound) {
		// Rmove the " - Wikipedia, the free encyclopedia" from the end of the title
		title = [[title substringToIndex:endRange.location] retain];
	}

	NSLog(@"%s Got tile=%@", _cmd, title);
	
	NSString *oldTitle = pageTitle;
	pageTitle = [title copy];
	[oldTitle release];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	NSLog(@"%s DELEGATE", _cmd);
//	WebDataSource *dataSource = [frame dataSource];
//	NSArray *subresources = [dataSource subresources];
//	DOMDocument *doc = [frame DOMDocument];
	
//	[self walkNodeTree:[frame DOMDocument]];
	[self walkNodeTree:[[frame DOMDocument] documentElement]];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark test
//------------------------------------------------------------------------------
// REMOVE
- (void)walkNodeTree:(DOMNode *)parent {
	DOMNodeList *nodeList = [parent childNodes];
	unsigned i, length = [nodeList length];
	for (i = 0; i < length; i++) {
		DOMNode *node = [nodeList item:i];
		[self walkNodeTree:node];
		DOMNamedNodeMap *attributes = [node attributes];
		unsigned a, attCount = [attributes length];
		NSMutableString *nodeInfo = [NSMutableString stringWithCapacity:0];
		NSString *nodeName = [node nodeName];
		NSString *nodeValue = [node nodeValue];
		[nodeInfo appendFormat:@"node[%i]:\nname: %@\nvalue: %@\nattributes:\n", 
								i, nodeName, nodeValue];
		for (a = 0; a < attCount; a++) {
			DOMNode *att = [attributes item:a];
			NSString *attName = [att nodeName];
			NSString *attValue = [att nodeValue];
			[nodeInfo appendFormat:@"\tatt[%i] name: %@ value: %@\n", a, attName, attValue];
		}
//		if([[node nodeName] isCaseInsensitiveLike:@"TITLE"]) {
//			NSLog(nodeInfo);
//		}
	}
}

@end
