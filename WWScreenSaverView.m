//
//  WWScreenSaverView.m
//  WikiWalker
//
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import "WWScreenSaverView.h"

#import "WWOffscreenWebView.h"
#import "WWOfflineImageSource.h"


@implementation ComYeahRightKeller_WWScreenSaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        // Seed the random number generator
        srandom(time(0));
        
        
        [self setAnimationTimeInterval:1/60.0];
		
		_offscreenWebView = [[WWOffscreenWebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];		
		_startingURL = [[NSString alloc] initWithString:@"http://en.wikipedia.org/wiki/Life_%28disambiguation%29"];
		_periodLength = 15.0;	// seconds
		_transitionLength = 5.0;	// seconds
		
		_currentPageTitle = [[NSString alloc] initWithString:@"Loading..."];
		
		// Create the title attributes dictionary
		_titleAttributes = [[NSMutableDictionary alloc] init];
		float fontSize = frame.size.height * 0.15;
		[_titleAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:fontSize]
							forKey:NSFontAttributeName];
		[_titleAttributes setObject:[NSColor colorWithDeviceRed:0.98 green:0.74 blue:0.14 alpha:1.0]
							forKey:NSForegroundColorAttributeName];
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(fontSize*0.025,fontSize*-0.025)];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow setShadowBlurRadius:fontSize*0.15];
		[_titleAttributes setObject:shadow forKey:NSShadowAttributeName];

		_titleOrigin = NSMakePoint(10,10);
        
        // For Threaded Notification Support
        [self setUpThreadingSupport];
        
        // Register to receive notifcations when the next image is ready
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processNotification:)
                                                     name:@"YRK_WWNextImageReady"
                                                   object:_offscreenWebView];
        

		// Start loading the first page
        // the offscreenWebView will spawn a new thread to do this, so its ok to call it directly from here
		[_offscreenWebView startLoadingPageFromURL:[NSURL URLWithString:_startingURL]];
        
        // Schedule a timer to check in 10 seconds if we have connected to the internet by then
        _haveConnectedToInternet = NO;
        _connectionTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)5.0
                                                   target:self
                                                 selector:@selector(checkIfHaveConnected:)
                                                 userInfo:nil
                                                  repeats:NO];
    }
    return self;
}

- (void) dealloc {
	[_offscreenWebView release];
	[_startingURL release];
	
	[_currentImage release];
	[_nextImage release];
	[_currentPageTitle release];
	[_nextPageTitle release];
	[_titleAttributes release];

	[super dealloc];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Drawing
//------------------------------------------------------------------------------

- (BOOL)isOpaque {
	return YES;
}

// This draws the iamges and the title at their current coordinates.  These coordinates are animated in animateOneFrame
- (void)drawRect:(NSRect)rect {
	[super drawRect:rect]; // to draw the black background

	float elapsedTime = CFAbsoluteTimeGetCurrent()-_periodStartTime;
	
	float currentAlpha;
	if(elapsedTime >= _periodLength - _transitionLength) {
		[_nextImage drawInRect:_nextToRect fromRect:_nextFromRect operation:NSCompositeSourceOver fraction:1.0];
		currentAlpha = (_periodLength-elapsedTime)/_transitionLength;
	}
	else {
		currentAlpha = 1.0;
	}
	[_currentImage drawInRect:_currentToRect fromRect:_currentFromRect operation:NSCompositeSourceOver fraction:currentAlpha];
	[_currentPageTitle drawAtPoint:_titleOrigin withAttributes:_titleAttributes];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Screen Saver
//------------------------------------------------------------------------------

- (void)startAnimation {
	[super startAnimation];
	_periodStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)stopAnimation {
    [super stopAnimation];
}

- (void)animateOneFrame {
	float elapsedTime = CFAbsoluteTimeGetCurrent()-_periodStartTime;
	if(_currentImage != nil) {
		NSRect bounds = [self bounds];

		// Move and zoom
		float zoomFactor = 1+(bounds.size.width-_currentToRect.size.width)/1000000;
		if(zoomFactor < 1.005) {
			zoomFactor = 1.005;
		}
		
        // move the front image
		_currentToRect.origin.y -= (_currentToRect.size.height*_currentFocalHeight+_currentToRect.origin.y-bounds.size.height/2)/50;
		_currentToRect.size.width *= zoomFactor;
		_currentToRect.size.height *= zoomFactor;
		_currentToRect.origin.x = (bounds.size.width-_currentToRect.size.width)/2; // keep it centered horizontally

		if(elapsedTime >= _periodLength - _transitionLength) {
			// fade to next page
			float nextZoomFactor = 1+(bounds.size.width-_nextToRect.size.width)/1000000;
			_nextToRect.origin.y -= (_nextToRect.size.height*_nextFocalHeight+_nextToRect.origin.y-bounds.size.height/2)/50;
			_nextToRect.size.width *= nextZoomFactor;
			_nextToRect.size.height *= nextZoomFactor;
			_nextToRect.origin.x = (bounds.size.width-_nextToRect.size.width)/2; // keep it centered horizontally
		}
		
		// Scroll title text
		_titleOrigin.x = (_periodLength-_transitionLength-elapsedTime)/(_periodLength - _transitionLength)*(bounds.size.width+_currentTitleWidth) - _currentTitleWidth;

		[self setNeedsDisplay:YES];		
	}
}

- (BOOL)hasConfigureSheet {
    return NO;
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Helper
//------------------------------------------------------------------------------

- (void)nextPageIsReady {
    // Mark that we have successfully connected to the internet
    if(_haveConnectedToInternet == NO) {
        _haveConnectedToInternet = YES;
    }
    
    // Immediately put the first image to screen.  The rest will be pushed by the switchTimer
    BOOL updateImmediately = NO;
    if(_nextImage == nil) {
        updateImmediately = YES;
    }
    
    _nextImage = [[_offscreenWebView imageOfContent] retain]; // the corresponding release is in switchToNextPage:
    _nextFromRect = NSMakeRect(0, 0, [_nextImage size].width, [_nextImage size].height);
    _nextFocalHeight = 1.0 - ([_offscreenWebView heightOfNextLink] / _nextFromRect.size.height);
    _nextPageTitle = [[_offscreenWebView pageTitle] retain]; // the corresponding release is in switchToNextPage:
    
    float toHeight = [self bounds].size.height;
    if([_nextImage size].height < toHeight) {
        toHeight = [_nextImage size].height;
    }
    float toWidth = _nextFromRect.size.width * (toHeight/_nextFromRect.size.height);
    _nextToRect = NSMakeRect(([self bounds].size.width-toWidth)/2,
                        [self bounds].size.height-toHeight,
                        toWidth,
                        toHeight);
    
    // If we aren't showing an image yet, we want to update now instead of waiting for the timer to fire
    if(updateImmediately) {
        [self switchToNextPage:nil];
    }
}

- (void)switchToNextPage:(NSTimer *)timer {
	NSImage *lastImage = _currentImage;
	NSString *lastPageTitle = _currentPageTitle;
	
    _currentImage = _nextImage;
	_currentPageTitle = _nextPageTitle;
	_currentFromRect = _nextFromRect;
	_currentToRect = _nextToRect;
	_currentFocalHeight = _nextFocalHeight;
    
    float linkYPos = [_offscreenWebView heightOfNextLink];
    _nextFocalHeight = 1.0 - (linkYPos / _nextToRect.size.height);
    _nextFocalHeight = 1.0;
	
	_titleOrigin = NSMakePoint([self bounds].size.width,[self bounds].size.height*0.25);
	_currentTitleWidth = [_currentPageTitle sizeWithAttributes:_titleAttributes].width;
	float fontSize = [self bounds].size.height * 0.20;
	[_titleAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:fontSize]
						forKey:NSFontAttributeName];

	// TODO: release these
	[lastImage release];
	[lastPageTitle release];
	
	// Mark this time as the start of the period
	_periodStartTime = CFAbsoluteTimeGetCurrent();
	
	// Set the timer to load a new page
    // We have to specifically set it on the main thread's run loop
    _switchTimer = [NSTimer timerWithTimeInterval:(NSTimeInterval)_periodLength
                                           target:self
                                         selector:@selector(switchToNextPage:)
                                         userInfo:nil
                                          repeats:NO];
    
    // TODO: NSRunLoop -mainRunLoop is Leopard-only.  Find a solution for Tiger
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:_switchTimer forMode:[runLoop currentMode]];
    
	// Start loading the next page
	[_offscreenWebView startLoadingNextPage];
}


- (void)checkIfHaveConnected:(NSTimer *)timer {
    if(! _haveConnectedToInternet) {
        // We haven't had a successful internet connect yet, so replace the WWOffscreenWebView with a "fake" one
        [_offscreenWebView release];
        _offscreenWebView = [[WWOfflineImageSource alloc] initWithFrame:[self bounds]];
        
        // Register to receive notifcations from this view (instead of the original WWOffscreenWebView
        NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
        [defaultNotificationCenter removeObserver:self];
        [defaultNotificationCenter addObserver:self
                                      selector:@selector(processNotification:)
                                          name:@"YRK_WWNextImageReady"
                                        object:_offscreenWebView];
        
        // Load the default images
        [_offscreenWebView startLoadingPageFromURL:nil];
    }
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Threaded Notification Support
//------------------------------------------------------------------------------

- (void)setUpThreadingSupport {
    if (_notifications) return;
    
    _notifications = [[NSMutableArray alloc] init];
    _notificationLock = [[NSLock alloc] init];
    _notificationThread = [[NSThread currentThread] retain];
    
    _notificationPort = [[NSMachPort alloc] init];
    [_notificationPort setDelegate:self];
    [[NSRunLoop currentRunLoop] addPort:_notificationPort
                                forMode:(NSString *)kCFRunLoopCommonModes];
}

- (void)handleMachMessage:(void *)msg {
    [_notificationLock lock];
    while ([_notifications count]) {
        NSNotification *notification = [[_notifications objectAtIndex:0] retain];
        [_notifications removeObjectAtIndex:0];
        [_notificationLock unlock];
        [self processNotification:notification];
        [notification release];
        [_notificationLock lock];
    };
    [_notificationLock unlock];
}

- (void)processNotification:(NSNotification *)notification {
    if( [NSThread currentThread] != _notificationThread ) {
        // Forward the notification to the correct thread
        [_notificationLock lock];
        [_notifications addObject:notification];
        [_notificationLock unlock];
        [_notificationPort sendBeforeDate:[NSDate date]
                               components:nil
                                     from:nil
                                 reserved:0];
    }
    else {
        // Process the notification here;
        if([[notification name] isEqualToString:@"YRK_WWNextImageReady"]) {
            [self nextPageIsReady];
        }
    }
}

@end
