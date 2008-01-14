//
//  WWOffscreenWebView.h
//  WikiWalker
//
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ScreenSaver/ScreenSaver.h>

@class ComYeahRightKeller_WWScreenSaverView;


@interface WWOffscreenWebView : NSObject {
	WebView *_webView;
    
	NSURL *_startingURL;
    NSURL *_nextURL;
	NSString *_pageTitle;
	NSImage *_imageOfContent;
    float _heightOfNextLink;
	
}

- (id)initWithFrame:(NSRect)frame;

- (void)startLoadingNextPage;
- (void)startLoadingPageFromURL:(NSURL *)newURL;


// Accessors
- (NSImage *)imageOfContent;

- (float)heightOfNextLink;  // in pixels, from the top of the page

- (NSURL *)nextURL;
- (void)setNextURL:(NSURL *)newURL;

- (NSString *)pageTitle;
- (void)setPageTitle:(NSString *)newTitle;


// For internal use
- (void)prepareNextPageOnNewThread;
- (void)prepareImage;
- (NSArray *)getWikiLinks;
- (BOOL)checkIfLinkIsGood:(NSString *)link;
- (float)getHeightOfLinkWithURL:(NSURL *)linkURL;


// WebView Delegate Methods
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame;

@end

