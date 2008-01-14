//
//  WWScreenSaverView.h
//  WikiWalker
//
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <WebKit/WebKit.h>

@class WWOffscreenWebView;
@class WWOfflineImageSource;


@interface ComYeahRightKeller_WWScreenSaverView : ScreenSaverView {
	WWOffscreenWebView *_offscreenWebView;	
	NSString *_startingURL;
	
	NSImage *_currentImage, *_nextImage;
	NSRect _currentFromRect, _currentToRect, _nextFromRect, _nextToRect;
	float _currentFocalHeight, _nextFocalHeight; // from 0.0 to 1.0, with 0.0 at the bottom of the page
	
	double _periodLength, _transitionLength;
	CFAbsoluteTime _periodStartTime;
	
	NSString *_currentPageTitle, *_nextPageTitle;
	NSPoint _titleOrigin;
	float _currentTitleWidth;
	NSMutableDictionary *_titleAttributes;
	
	NSTimer *_switchTimer;
    
    BOOL _haveConnectedToInternet;
    NSTimer *_connectionTimer;
    
    // Threaded notification support, see comments below
    NSMutableArray *_notifications;
    NSThread *_notificationThread;
    NSLock *_notificationLock;
    NSMachPort *_notificationPort;
}

- (void)switchToNextPage:(NSTimer *)timer;
- (void)nextPageIsReady;

// To see if we need to do offline mode
- (void)checkIfHaveConnected:(NSTimer *)timer;


// Threaded Notification Support, from the "Notifications Programming Topics" guide ("Delivering Notifications To Particular Threads")
// We need this so that we can make sure to process the notifications on the main thread.
// We need to do that because, otherwise we'll try to schedule timers on secondary run loops, which doesn't work
// LEOPARD: In Leopard, you can get the main run loop with [NSRunLoop mainRunLoop], but I'm not sure how to do the equivilent in Tiger
- (void)setUpThreadingSupport;
- (void)handleMachMessage:(void *)msg;
- (void)processNotification:(NSNotification *)notification;

@end
