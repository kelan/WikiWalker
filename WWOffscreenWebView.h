//
//  WWOffscreenWebView.h
//  WikiWalker
//
//  Created by Temp Kelan on 4/4/07.
//  Copyright 2007 Yeah Right Keller. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ScreenSaver/ScreenSaver.h>

@interface WWOffscreenWebView : NSObject {
	WebView *webView;
	NSURL *currentURL, *startingURL;
	
	NSMutableArray *listOfWikiLinks;
	
	NSImage *imageOfContent;
	NSString *pageTitle;
}

- (id)initWithFrame:(NSRect)frame;
- (void)startLoadingRandomPage;
- (void)startLoadingPageFromURL:(NSURL *)newURL;

// Accessors
- (NSImage *)imageOfContent;
- (NSString *)pageTitle;

// Private
- (void)webViewDidFinishLoading:(NSNotification *)notification;

- (void)prepareImage;

- (void)getWikiLinksFromNodeTree:(DOMNode *)parent;
- (void)addToListOfLinksIfGood:(NSString *)newLink;

// For Mutli-Threading
- (void)prepareImageOnNewThread;
- (void)getWikiLinksFromNodeTreeOnNewThread:(DOMNode *)parent;

// REMOVE Test
- (void)walkNodeTree:(DOMNode *)parent;

@end
