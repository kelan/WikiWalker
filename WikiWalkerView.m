//
//  WikiWalkerView.m
//  WikiWalker
//
//  Created by Kelan Champagne on 3/31/07.
//  Copyright (c) 2007, Yeah Right Keller. All rights reserved.
//

#import "WikiWalkerView.h"


@implementation ComYeahRightKeller_WikiWalkerView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/60.0];
		
		webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)
                                       frameName:@"YRKmainFrame"
                                       groupName:@"YRKgroup"];
		[webView setFrameLoadDelegate:self];
		
		startingURL = [[NSString alloc] initWithString:@"http://en.wikipedia.org/wiki/Life_%28disambiguation%29"];
		periodLength = 15.0;	// seconds
		transitionLength = 5.0;	// seconds
		
		currentPageTitle = [[NSString alloc] initWithString:@"Loading..."];
		nextPageTitle = [[NSString alloc] initWithString:@"NextTitle"];
		
		// Create the title attributes dictions
		titleAttributes = [[NSMutableDictionary alloc] init];
		float fontSize = frame.size.height * 0.15;
		[titleAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:fontSize]
							forKey:NSFontAttributeName];
		[titleAttributes setObject:[NSColor colorWithDeviceRed:0.98 green:0.74 blue:0.14 alpha:1.0]
							forKey:NSForegroundColorAttributeName];
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(fontSize*0.025,fontSize*-0.025)];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow setShadowBlurRadius:fontSize*0.15];
		[titleAttributes setObject:shadow forKey:NSShadowAttributeName];
		titleOrigin = NSMakePoint(10,10);
		
		frameCounter = 0;
		
		// Register to see when webview is done loading
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(webViewDidFinishLoading:)
													 name:WebViewProgressFinishedNotification
												   object:nil];
		
		listOfWikiLinks = [[NSMutableArray alloc] init];
		switchTimer = [[NSTimer alloc] init];
    }
    return self;
}

- (void) dealloc {
/*	[currentImage release];
	[nextImage release];
	[webView release];
	[startingURL release];
	[currentPageTitle release];
	[titleAttributes release];
	
	[listOfWikiLinks release];
	[switchTimer release];
	*/
	[super dealloc];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Drawing
//------------------------------------------------------------------------------

- (void)startAnimation {
	[super startAnimation];
	periodStartTime = CFAbsoluteTimeGetCurrent();
	[self startLoadingPageFromURL:[NSURL URLWithString:startingURL]];
}

- (void)stopAnimation {
    [super stopAnimation];
}

- (BOOL)isOpaque {
	return YES;
}

- (void)drawRect:(NSRect)rect {
	float elapsedTime = CFAbsoluteTimeGetCurrent()-periodStartTime;
//	NSLog(@"%s", _cmd);
    [super drawRect:rect];
//	NSLog(@"%s SUPER DONE", _cmd);
	float fraction;
	if(elapsedTime >= periodLength - transitionLength) {
		[nextImage drawInRect:nextToRect fromRect:nextFromRect operation:NSCompositeSourceOver fraction:1.0];
		fraction = (periodLength-elapsedTime)/transitionLength;
	}
	else {
		fraction = 1.0;
	}
	[currentImage drawInRect:currentToRect fromRect:currentFromRect operation:NSCompositeSourceOver fraction:fraction];
//	NSLog(@"%s IMAGE DONE", _cmd);
	[currentPageTitle drawAtPoint:titleOrigin withAttributes:titleAttributes];
//	NSLog(@"%s DONE", _cmd);
}

- (void)animateOneFrame {
	float elapsedTime = CFAbsoluteTimeGetCurrent()-periodStartTime;
//	NSLog(@"%s elapsed time=%0.2f", _cmd, elapsedTime);
	frameCounter++;
	if(currentImage != nil) {
		NSRect bounds = [self bounds];

		// Move and zoom
		float zoomFactor = 1+(bounds.size.width-currentToRect.size.width)/50000;
		if(zoomFactor < 1.005) {
			zoomFactor = 1.005;
		}
//		NSLog(@"%s zoomFactor=%f", _cmd, zoomFactor);
		
		currentToRect.origin.y -= (currentToRect.size.height*currentFocalHeight+currentToRect.origin.y-bounds.size.height/2)/10;
//		NSLog(@"%s current x=%0.2f y=%0.2f", _cmd, currentToRect.origin.x, currentToRect.origin.y);
		currentToRect.size.width *= zoomFactor;
		currentToRect.size.height *= zoomFactor;
		currentToRect.origin.x = (bounds.size.width-currentToRect.size.width)/2; // keep it centered horizontally

		if(elapsedTime >= periodLength - transitionLength) {
			// fade to next page
			float nextZoomFactor = 1+(bounds.size.width-nextToRect.size.width)/50000;
			nextToRect.origin.y -= (nextToRect.size.height*nextFocalHeight+nextToRect.origin.y-bounds.size.height/2)/10;
//			NSLog(@"%s next x=%0.2f y=%0.2f", _cmd, nextToRect.origin.x, nextToRect.origin.y);
			nextToRect.size.width *= nextZoomFactor;
			nextToRect.size.height *= nextZoomFactor;
			nextToRect.origin.x = (bounds.size.width-nextToRect.size.width)/2; // keep it centered horizontally
		}
		
		// Move title text
		titleOrigin.x = (periodLength-transitionLength-elapsedTime)/(periodLength - transitionLength)*(bounds.size.width+currentTitleWidth) - currentTitleWidth;
//		NSLog(@"%s titleOrigin=%0.2f,%0.2f", _cmd, titleOrigin.x, titleOrigin.y);

		[self setNeedsDisplay:YES];		
//		NSLog(@"%s DONE", _cmd);
	}

}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Configure Sheet
//------------------------------------------------------------------------------

- (BOOL)hasConfigureSheet {
    return NO;
}

- (NSWindow*)configureSheet {
    return nil;
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Helper
//------------------------------------------------------------------------------

- (void)startLoadingPageFromURL:(NSURL *)url {
//	NSLog(@"%s %@", _cmd, url);
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	nextURL = [url copy];
}

- (void)webViewDidFinishLoading:(NSNotification *)notification {
//	NSLog(@"%s", _cmd);
	
	// the first time, show  the page immediately, otherwise it will switch when the timer fires
	if(currentImage == nil) {
//	if(true) { // don't try threading yet
//		NSLog(@"%s first time", _cmd);
		[self prepareImageFromView:[[[webView mainFrame] frameView] documentView]];
//		NSLog(@"getWikiLinksFromNodeTree");
		[listOfWikiLinks removeAllObjects];
		[self getWikiLinksFromNodeTree:[[webView mainFrame] DOMDocument]];
//		NSLog(@"   got %u", [listOfWikiLinks count]);
		if(currentImage == nil) {
			[self switchToNextPage:self];
		}
	}
	else {
//		NSLog(@"%s Do separate threads", _cmd);
		[NSThread detachNewThreadSelector:@selector(prepareImageFromViewOnNewThread:)
	                             toTarget:self
	                           withObject:[[[webView mainFrame] frameView] documentView]];
	//	[self prepareImageFromView:[[[webView mainFrame] frameView] documentView]];
//		NSLog(@" preparing image on new thread");

		[listOfWikiLinks removeAllObjects];
		[NSThread detachNewThreadSelector:@selector(getWikiLinksFromNodeTreeOnNewThread:)
	                             toTarget:self
	                           withObject:[[webView mainFrame] DOMDocument]];
	/*/	[self getWikiLinksFromNodeTree:[[webView mainFrame] DOMDocument]];		*/
//		NSLog(@" getting links on separate thread");		
	}
}

- (void)prepareImageFromView:(NSView *)view {
//	NSLog(@"%s", _cmd);
	NSRect viewRect = [view bounds];
	NSBitmapImageRep *imageRep = [view bitmapImageRepForCachingDisplayInRect:viewRect];
	[view cacheDisplayInRect:viewRect toBitmapImageRep:imageRep];
	NSSize repSize = [imageRep size];
	
	if(repSize.width > 0) {
		nextImage = [[NSImage alloc] initWithSize:viewRect.size];
		[nextImage addRepresentation:imageRep];
		[nextImage setScalesWhenResized:NO];
		
		nextFromRect = NSMakeRect(0, 0, [nextImage size].width, [nextImage size].height);
		float toHeight = [self bounds].size.height;
		if([nextImage size].height < toHeight) {
			toHeight = [nextImage size].height;
		}
		float toWidth = nextFromRect.size.width * (toHeight/nextFromRect.size.height);
		nextToRect = NSMakeRect(([self bounds].size.width-toWidth)/2,
							[self bounds].size.height-toHeight,
							toWidth,
							toHeight);

		nextFocalHeight = SSRandomFloatBetween(0,1.0);	
	}
}

- (void)switchToNextPage:(id)sender {
//	NSLog(@"%s %@ -> %@", _cmd, currentPageTitle, nextPageTitle);
	NSImage *lastImage = currentImage;
	NSString *lastPageTitle = currentPageTitle;
	NSURL *lastURL = currentURL;
	
	currentImage = nextImage;
	currentPageTitle = nextPageTitle;
	currentURL = nextURL;
	currentFromRect = nextFromRect;
	currentToRect = nextToRect;
	currentFocalHeight = nextFocalHeight;
	
	titleOrigin = NSMakePoint([self bounds].size.width,[self bounds].size.height*0.05);
	currentTitleWidth = [currentPageTitle sizeWithAttributes:titleAttributes].width;
	float fontSize = [self bounds].size.height * 0.75;
	[titleAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:fontSize]
						forKey:NSFontAttributeName];
	
	
	[lastImage release];
	[lastPageTitle release];
	[lastURL release];
	
	// Mark this time as the start of the period
	periodStartTime = CFAbsoluteTimeGetCurrent();
//	NSLog(@"%s periodStartTime=%f", _cmd, periodStartTime);
	
	// Set the timer to load a new page
	//	[switchTimer release];	// TODO: i think i should need to release this, but if i do, it segfaults
	switchTimer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)periodLength
                                                         target:self
                                                       selector:@selector(switchToNextPage:)
                                                       userInfo:nil
                                                        repeats:NO] retain];
	
	// Start loading the next page
//	NSLog(@"%s start loading next page from: %d", _cmd, [listOfWikiLinks count]);
	if([listOfWikiLinks count]>0) {
		unsigned randomNum = SSRandomIntBetween(0,[listOfWikiLinks count]);
		[self startLoadingPageFromURL:[NSURL URLWithString:[listOfWikiLinks objectAtIndex:randomNum]]];
	}
	else {
//		NSLog(@"%s no next page to load - so start over", _cmd);
		[self startLoadingPageFromURL:[NSURL URLWithString:startingURL]];
	}
}

// Example from the oldest version of DOMCore on cocoadev: http://www.cocoadev.com/index.pl?DOMCore1
- (void)getWikiLinksFromNodeTree:(DOMNode *)parent {
	DOMNodeList *nodeList = [parent childNodes];
	unsigned i, length = [nodeList length];
	NSString *hostName = [@"http://" stringByAppendingString:[nextURL host]];
	
	for (i = 0; i < length; i++) {
		DOMNode *node = [nodeList item:i];
		[self getWikiLinksFromNodeTree:node];
		DOMNamedNodeMap *attributes = [node attributes];
		unsigned a, attCount = [attributes length];
		
		if([[node nodeName] isCaseInsensitiveLike:@"a"]) {
			for (a = 0; a < attCount; a++) {
				DOMNode *att = [attributes item:a];
				if([[att nodeName] isCaseInsensitiveLike:@"href"]) {
					if([[att nodeValue] hasPrefix:@"/wiki/"]) { // get only links that start with wiki
//						NSLog(@"%s foundlink %@", _cmd, [att nodeValue]);
						[listOfWikiLinks addObject:[hostName stringByAppendingString:[att nodeValue]]];
					}
				}
			}
		}
	}
	
	// Do some filtering
	NSEnumerator *enumerator = [listOfWikiLinks objectEnumerator]; 
	id link;
	while( link = [enumerator nextObject] ) {
		if([link rangeOfString:@"/wiki/Special"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/Help"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/Image"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/Wiktionary"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/Wikipedia:"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/Main_Page"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/Portal:"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/profit_organization"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/Charitable_organization"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
		if([link rangeOfString:@"/wiki/501"].location != NSNotFound) {
			[listOfWikiLinks removeObject:link];
		}
	}
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark For Multiple Threads
//------------------------------------------------------------------------------

- (void)prepareImageFromViewOnNewThread:(NSView *)view {
//	NSLog(@"%s start", _cmd);
	NSAutoreleasePool *arp = [[NSAutoreleasePool alloc] init];
	[self prepareImageFromView:view];
	[arp release];
//	NSLog(@"%s done", _cmd);
}

- (void)getWikiLinksFromNodeTreeOnNewThread:(DOMNode *)parent {
//	NSLog(@"%s start", _cmd);
	NSAutoreleasePool *arp = [[NSAutoreleasePool alloc] init];
	[self getWikiLinksFromNodeTree:parent];
	[arp release];
//	NSLog(@"%s done", _cmd);
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark WebView delegate methods
//------------------------------------------------------------------------------

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	if([title length] > 30) {
		// we want to remove the " - Wikipedia, the free encyclopedia" from the end of the title
		NSRange endRange = [title rangeOfString:@" - Wikipedia, the free encyclopedia"];
		// TODO: fix this, cuz there is a point here where it could maybe try to draw nil??
		//	[currentPageTitle release];
		nextPageTitle = [[title substringToIndex:endRange.location] retain];
//		NSLog(@"%s %@", _cmd, nextPageTitle);
	}
}

@end
