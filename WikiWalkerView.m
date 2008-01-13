//
//  WikiWalkerView.m
//  WikiWalker
//
//  Created by Kelan Champagne on 3/31/07.
//  Copyright (c) 2007, Kelan Champagne. All rights reserved.
//

#import "WikiWalkerView.h"

@class WWOffscreenWebView;


@implementation ComYeahRightKeller_WikiWalkerView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/60.0];
		
		_offscreenWebView = [[WWOffscreenWebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
		[_offscreenWebView setClient:self];
		
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

		// Start loading the first page
		[_offscreenWebView startLoadingPageFromURL:[NSURL URLWithString:_startingURL]];
        
        // Schedule a timer to check in 10 seconds if we have connected to the internet by then
        _haveConnectedToInternet = NO;
        _connectionTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)10.0
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
    
    [_defaultImages release];

	[super dealloc];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Drawing
//------------------------------------------------------------------------------

- (void)startAnimation {
	[super startAnimation];
	_periodStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)stopAnimation {
    [super stopAnimation];
}

- (BOOL)isOpaque {
	return YES;
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];

	float elapsedTime = CFAbsoluteTimeGetCurrent()-_periodStartTime;
//	NSLog(@"%s imagesize=%0.2f,%0.2f", _cmd, [currentImage size].width, [currentImage size].height);
//	NSLog(@"%s torect=%0.2f,%0.2f,%0.2f,%0.2f", _cmd, currentToRect.origin.x, currentToRect.origin.y, currentToRect.size.width, currentToRect.size.height);
//	NSLog(@"%s fromrect=%0.2f,%0.2f,%0.2f,%0.2f", _cmd, currentFromRect.origin.x, currentFromRect.origin.y, currentFromRect.size.width, currentFromRect.size.height);
	
	float fraction;
	if(elapsedTime >= _periodLength - _transitionLength) {
		[_nextImage drawInRect:_nextToRect fromRect:_nextFromRect operation:NSCompositeSourceOver fraction:1.0];
		fraction = (_periodLength-elapsedTime)/_transitionLength;
	}
	else {
		fraction = 1.0;
	}
	[_currentImage drawInRect:_currentToRect fromRect:_currentFromRect operation:NSCompositeSourceOver fraction:fraction];
	[_currentPageTitle drawAtPoint:_titleOrigin withAttributes:_titleAttributes];
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
		
		_currentToRect.origin.y -= (_currentToRect.size.height*_currentFocalHeight+_currentToRect.origin.y-bounds.size.height/2)/10;
		_currentToRect.size.width *= zoomFactor;
		_currentToRect.size.height *= zoomFactor;
		_currentToRect.origin.x = (bounds.size.width-_currentToRect.size.width)/2; // keep it centered horizontally

		if(elapsedTime >= _periodLength - _transitionLength) {
			// fade to next page
			float nextZoomFactor = 1+(bounds.size.width-_nextToRect.size.width)/50000;
			_nextToRect.origin.y -= (_nextToRect.size.height*_nextFocalHeight+_nextToRect.origin.y-bounds.size.height/2)/10;
			_nextToRect.size.width *= nextZoomFactor;
			_nextToRect.size.height *= nextZoomFactor;
			_nextToRect.origin.x = (bounds.size.width-_nextToRect.size.width)/2; // keep it centered horizontally
		}
		
		// Scroll title text
		_titleOrigin.x = (_periodLength-_transitionLength-elapsedTime)/(_periodLength - _transitionLength)*(bounds.size.width+_currentTitleWidth) - _currentTitleWidth;

		[self setNeedsDisplay:YES];		
	}
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Configure Sheet
//------------------------------------------------------------------------------

- (BOOL)hasConfigureSheet {
    return NO;
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Helper
//------------------------------------------------------------------------------

- (void)imageIsReady:(id)sender {
	if(sender == _offscreenWebView) {
        
        // Mark that we have successfully connected to the internet
        _haveConnectedToInternet = YES;
        
		NSLog(@"%s getting next image", _cmd);
		// Immediately put the first image to screen.  The rest will be pushed by the switchTimer
		BOOL updateImmediately = NO;
		if(_nextImage == nil) {
			updateImmediately = YES;
		}
		
        // TODO: uncomment this?
//		[nextImage release];
		_nextImage = [[_offscreenWebView imageOfContent] retain];
		_nextPageTitle = [[_offscreenWebView pageTitle] retain];
		NSLog(@"%s nextimageheight=%0.2f, title=%@", _cmd, [_nextImage size].height, _nextPageTitle);
		
		_nextFromRect = NSMakeRect(0, 0, [_nextImage size].width, [_nextImage size].height);
		float toHeight = [self bounds].size.height;
		if([_nextImage size].height < toHeight) {
			toHeight = [_nextImage size].height;
		}
		float toWidth = _nextFromRect.size.width * (toHeight/_nextFromRect.size.height);
		_nextToRect = NSMakeRect(([self bounds].size.width-toWidth)/2,
							[self bounds].size.height-toHeight,
							toWidth,
							toHeight);
		
		if(updateImmediately) {
			[self switchToNextPage:nil];
		}
        
	}
}

- (void)switchToNextPage:(NSTimer *)timer {
	NSLog(@"%s %@ -> %@", _cmd, _currentPageTitle, _nextPageTitle);
//	NSImage *lastImage = _currentImage;
//	NSString *lastPageTitle = _currentPageTitle;
	
    if(_haveConnectedToInternet) {
        _currentImage = _nextImage;   
    }
    else {
        _currentImage = [_defaultImages objectAtIndex:4];
    }
	_currentPageTitle = _nextPageTitle;
	_currentFromRect = _nextFromRect;
	_currentToRect = _nextToRect;
	_currentFocalHeight = _nextFocalHeight;
    _currentFocalHeight = 0.8;
	
	_titleOrigin = NSMakePoint([self bounds].size.width,[self bounds].size.height*0.25);
	_currentTitleWidth = [_currentPageTitle sizeWithAttributes:_titleAttributes].width;
	float fontSize = [self bounds].size.height * 0.20;
	[_titleAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:fontSize]
						forKey:NSFontAttributeName];

	// TODO: release these
//	[lastImage release];
//	[lastPageTitle release];
	
	// Mark this time as the start of the period
	_periodStartTime = CFAbsoluteTimeGetCurrent();
	
	// Set the timer to load a new page
    _switchTimer = [NSTimer timerWithTimeInterval:(NSTimeInterval)_periodLength
                                     target:self
                                   selector:@selector(switchToNextPage:)
                                   userInfo:nil
                                              repeats:NO];
    
    // TODO: NSRunLoop -mainRunLoop is Leopard-only.  Find a solution for Tiger
    NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
    [mainRunLoop addTimer:_switchTimer forMode:[mainRunLoop currentMode]];
    
	// Start loading the next page
	[_offscreenWebView startLoadingRandomPage];
}


- (void)checkIfHaveConnected:(NSTimer *)timer {
    
    if(! _haveConnectedToInternet) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *defaultImageDirName = @"yrk default images";
        NSString *defaultImagesDirPath = [bundle pathForResource:defaultImageDirName ofType:nil];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *defaultImagePaths = [fm directoryContentsAtPath:defaultImagesDirPath];
        int i, numImages = [defaultImagePaths count];
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:numImages];
        NSString *dirPath = [defaultImagesDirPath stringByAppendingString:@"/"];
        for(i=0; i<numImages; i++) {
            NSString *thisImagePath = [dirPath stringByAppendingString:[defaultImagePaths objectAtIndex:i]];
            NSData *thisImageData = [fm contentsAtPath:thisImagePath];
            NSImage *thisImage = [[NSImage alloc] initWithData:thisImageData];
            [images addObject:thisImage];
        }
        
        _defaultImages = [[NSArray arrayWithArray:images] retain];
    }
    
}

@end
