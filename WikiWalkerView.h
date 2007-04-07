//
//  WikiWalkerView.h
//  WikiWalker
//
//  Created by Kelan Champagne on 3/31/07.
//  Copyright (c) 2007, Yeah Right Keller. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <WebKit/WebKit.h>

#import "WWOffscreenWebView.h"

@interface ComYeahRightKeller_WikiWalkerView : ScreenSaverView {
	NSImage *currentImage, *nextImage;
	NSRect currentFromRect, currentToRect, nextFromRect, nextToRect;
	float currentFocalHeight, nextFocalHeight;
	
	float periodLength, transitionLength;
	CFAbsoluteTime periodStartTime;
	
	NSString *currentPageTitle, *nextPageTitle;
	NSPoint titleOrigin;
	float currentTitleWidth;
	NSMutableDictionary *titleAttributes;
	
	WWOffscreenWebView *offscreenWebView;	
	NSString *startingURL;
	
	NSTimer *switchTimer;
	
}

- (void)switchToNextPage:(id)sender;

- (void)webImageIsReady:(NSNotification *)notification;


@end
