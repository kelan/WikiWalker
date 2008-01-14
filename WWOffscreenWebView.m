//
//  WWOffscreenWebView.m
//  WikiWalker
//
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import "WWOffscreenWebView.h"

#import "WWScreenSaverView.h"


@implementation WWOffscreenWebView

- (id)initWithFrame:(NSRect)frame {
	self = [super init];
	if (self != nil) {
		
		_webView = [[WebView alloc] initWithFrame:frame
                                       frameName:@"YRKmainFrame"
                                       groupName:@"YRKgroup"];
		[_webView setFrameLoadDelegate:self];
        
		_imageOfContent = [[NSImage alloc] init];
        [self setPageTitle:@"No Title"];
	}
	return self;
}

- (void)dealloc {
	[_webView release];
    [_pageTitle release];
	[_startingURL release];
    [_nextURL release];
    [_imageOfContent release];
	
    [super dealloc];
}

- (void)startLoadingNextPage {
    
	// Don't want to try to pick a random link until we've loaded all the links.  Normally this isn't an issues with the 15 second interval, but the first time it is.  So, if we haven't parsed links yet, just try again in 1 second.
	
	if(_nextURL != nil) {
        [self startLoadingPageFromURL:_nextURL];
    }
    else {
        // we didn't get any links, so start over
        [self startLoadingPageFromURL:_startingURL];
    }
}

- (void)startLoadingPageFromURL:(NSURL *)newURL {
    [[_webView mainFrame] loadRequest:[NSURLRequest requestWithURL:newURL]];
    
    // If this is the first URL, save it
    if(_startingURL == nil) {
        _startingURL = [newURL retain];
    }
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Accessors
//------------------------------------------------------------------------------

- (NSImage *)imageOfContent {
	return _imageOfContent;
}

- (float)heightOfNextLink {
    return _heightOfNextLink;
}

- (NSURL *)nextURL {
    return [_nextURL autorelease];
}
- (void)setNextURL:(NSURL *)newURL {
    NSURL *oldNextURL = _nextURL;
	_nextURL = [newURL retain];
	[oldNextURL release];    
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
#pragma mark For internal use
//------------------------------------------------------------------------------

- (void)prepareNextPageOnNewThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // create an image from the content
	[self prepareImage];
    
    // pick a random link to go to next
    NSArray *links = [self getWikiLinks];
    
    // pick a random one to go to
    unsigned nextLinkNum = SSRandomIntBetween(0, [links count]-1);
    
    [self setNextURL:[NSURL URLWithString:[links objectAtIndex:nextLinkNum]]];
    _heightOfNextLink = [self getHeightOfLinkWithURL:_nextURL];
    
	// Post a Notification that the next page is ready so the WWScreenSaverView can pick it up
    [[NSNotificationCenter defaultCenter] postNotificationName:@"YRK_WWNextImageReady"
                                                        object:self];
	[pool release];
}

- (void)prepareImage {
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
}

- (NSArray *)getWikiLinks {
	int i, numLinks = [[_webView stringByEvaluatingJavaScriptFromString: @"document.links.length"] intValue];
	NSMutableArray *goodLinks = [NSMutableArray arrayWithCapacity:numLinks];
    
	for (i = 0; i < numLinks; i++) {
		NSString *link = [_webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.links[%d].href", i]];
        if([self checkIfLinkIsGood:link]) {
            [goodLinks addObject:link];
        }
	}
    
    return goodLinks;
}

- (BOOL)checkIfLinkIsGood:(NSString *)link {
    // We only want links to wiki pages (that start with /wiki/)
	if([link rangeOfString:@"en.wikipedia.org/wiki/"].location == NSNotFound) return NO;
    
    // But don't want any of the following "special" links
	if([link rangeOfString:@"/wiki/Talk:"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Special"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Help"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Image"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Wiktionary"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Wikipedia:"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Main_Page"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Portal:"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/profit_organization"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/Charitable_organization"].location != NSNotFound) return NO;
	if([link rangeOfString:@"/wiki/501"].location != NSNotFound) return NO;
    
    // Also reject the link if it's to the page we're currently on
    if(_nextURL != nil) {
        if([[_nextURL absoluteString] rangeOfString:link].location != NSNotFound) return NO;
    }
	
	// If we made it this far, its a keeper
    return YES;
}

// To get the height of the link on the page, we use the following Javascript function, from: http://blog.firetree.net/2005/07/04/javascript-find-position/
// returns the height of the given link num, in pixels, increasing downward with the top of the page = 0
// Original Version from the site:
//function findPosY(obj)
//{
//    var curtop = 0;
//    if(obj.offsetParent)
//        while(1)
//        {
//            curtop += obj.offsetTop;
//            if(!obj.offsetParent)
//                break;
//            obj = obj.offsetParent;
//        }
//    else if(obj.y)
//        curtop += obj.y;
//    return curtop;
//}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// But this won't work because we don't keep all links (we discard a bunch in checkIfLinkIsGood())
// So, lets go through the links until we get the right URL
// My Version:
//function findPosY() {
//    var targetURL = "http://thetargeturl.com/with/full/path/"
//    var foundLink = false;
//    var i = 0;
//    var linkNum = 0;
//    while(!foundLink) {
//        var thisLinkURL = document.links[i].href
//        if(thisLinkURL == targetURL) {
//            linkNum = i;
//            foundLink = true;
//        }
//        if(i >= document.links.size) {
//            foundLink = true;
//        }
//        else {
//            i++;
//        }
//    }
//    if(i == document.links.size) {
//        return 0.0;
//    }
//    var y_pos = 0;
//    var obj = document.links[linkNum];
//    if(obj.offsetParent)
//        while(1) {
//            y_pos += obj.offsetTop;
//            if(!obj.offsetParent)
//		        break;
//            obj = obj.offsetParent;
//        }
//    else if(obj.y)
//        y_pos += obj.y;
//    var targetURL = "http://thetargeturl.com/with/full/path/"
//    var foundLink = false;
//    var i = 0;
//    var linkNum = 0;
//    while(!foundLink) {
//        var thisLinkURL = document.links[i].href
//        if(thisLinkURL == targetURL) {
//            linkNum = i;
//            foundLink = true;
//        }
//        if(i >= document.links.size) {
//            foundLink = true;
//        }
//        else {
//            i++;
//        }
//    }
//    if(i == document.links.size) {
//        return 0.0;
//    }
//    var y_pos = 0;
//    var obj = document.links[linkNum];
//    if(obj.offsetParent)
//        while(1) {
//            y_pos += obj.offsetTop;
//            if(!obj.offsetParent)
//		        break;
//            obj = obj.offsetParent;
//        }
//    else if(obj.y)
//        y_pos += obj.y;
//    return y_pos;
// }

- (float)getHeightOfLinkWithURL:(NSURL *)linkURL {
    if(_webView) {
        NSString *jsCommand = [NSString stringWithFormat:@"var targetURL = '%s'; var foundLink = false; var i = 0; var linkNum = 0; while(!foundLink) { var thisLinkURL = document.links[i].href if(thisLinkURL == targetURL) { linkNum = i; foundLink = true; } if(i >= document.links.size) { foundLink = true; } else { i++; } } if(i == document.links.size) { return 0.0; } var y_pos = 0; var obj = document.links[linkNum]; if(obj.offsetParent) while(1) { y_pos += obj.offsetTop; if(!obj.offsetParent) break; obj = obj.offsetParent; } else if(obj.y) y_pos += obj.y; return y_pos;", [linkURL absoluteString]];

        NSString *jsResult = [_webView stringByEvaluatingJavaScriptFromString:jsCommand];
        if(jsResult == nil) {
            NSLog(@"%s ERROR: didn't didn't find link: %@", _cmd, [linkURL absoluteString]);
            return 0.0;
        }
        else {
            return [jsResult floatValue];
        }
    }
    else {
        return 0.0;
    }
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
	
    // check to make sure its the main frame and no a sub-frame
	if(frame != [sender mainFrame]) {
		return;
	}
	
	[NSThread detachNewThreadSelector:@selector(prepareNextPageOnNewThread)
                             toTarget:self
                           withObject:nil];
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

