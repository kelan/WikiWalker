//
//  WikiWalkerView.h
//  WikiWalker
//
//  Created by Kelan Champagne on 3/31/07.
//  Copyright (c) 2007, Kelan Champagne. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <WebKit/WebKit.h>

#import "WWOffscreenWebView.h"

@interface ComYeahRightKeller_WikiWalkerView : ScreenSaverView {
	NSImage *_currentImage, *_nextImage;
	NSRect _currentFromRect, _currentToRect, _nextFromRect, _nextToRect;
	float _currentFocalHeight, _nextFocalHeight;
	
	double _periodLength, _transitionLength;
	CFAbsoluteTime _periodStartTime;
	
	NSString *_currentPageTitle, *_nextPageTitle;
	NSPoint _titleOrigin;
	float _currentTitleWidth;
	NSMutableDictionary *_titleAttributes;
	
	WWOffscreenWebView *_offscreenWebView;	
	NSString *_startingURL;
	
	NSTimer *_switchTimer;
    
    bool _haveConnectedToInternet;
    NSTimer *_connectionTimer;
    NSArray *_defaultImages;
}

- (void)switchToNextPage:(NSTimer *)timer;

- (void)imageIsReady:(id)sender;
- (void)checkIfHaveConnected:(NSTimer *)timer;

// Configure Sheet
//- (IBAction)cancelClick: (id) sender;
//- (IBAction)okClick: (id) sender;


@end
