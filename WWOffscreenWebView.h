//
//  WWOffscreenWebView.h
//  WikiWalker
//
//  Created by Temp Kelan on 4/4/07.
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ScreenSaver/ScreenSaver.h>

@interface WWOffscreenWebView : NSObject {
	WebView *_webView;
	NSURL *_currentURL, *_startingURL;
	
	BOOL _haveParsedLinks;
	NSMutableArray *_listOfWikiLinks;
	
	NSImage *_imageOfContent;
	NSString *_pageTitle;
	
	id _client;
}

- (id)initWithFrame:(NSRect)frame;

- (void)startLoadingRandomPage;
- (void)startLoadingPageFromURL:(NSURL *)newURL;

// Accessors
- (void)setClient:(id)newClient;
- (NSImage *)imageOfContent;

- (NSString *)pageTitle;
- (void)setPageTitle:(NSString *)newTitle;

// For Mutli-Threading
- (void)prepareImageOnNewThread;
- (void)getWikiLinksFromNodeTreeOnNewThread:(DOMNode *)parent;

// For internal use
- (void)prepareImage;

//- (void)getWikiLinksFromNodeTree:(DOMNode *)parent;
- (void)getWikiLinksWithJS;
- (void)addToListOfLinksIfGood:(NSString *)newLink withLinkNumber:(NSNumber *)linkNumber;


@end
