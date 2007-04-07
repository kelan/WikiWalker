//
//  WikiWalkerView.m
//  WikiWalker
//
//  Created by Kelan Champagne on 3/31/07.
//  Copyright (c) 2007, Yeah Right Keller. All rights reserved.
//

#import "WikiWalkerView.h"

@class WWOffscreenWebView;

@implementation ComYeahRightKeller_WikiWalkerView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/60.0];
		
		offscreenWebView = [[WWOffscreenWebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
		
		startingURL = [[NSString alloc] initWithString:@"http://en.wikipedia.org/wiki/Life_%28disambiguation%29"];
		periodLength = 15.0;	// seconds
		transitionLength = 5.0;	// seconds
		
		currentPageTitle = [[NSString alloc] initWithString:@"Loading..."];
		
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
				
//		switchTimer = [[NSTimer alloc] init];
				
		// Register to see when an image is read
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(webImageIsReady:)
													 name:@"WWWebImageIsReady"
												   object:nil];

		[offscreenWebView startLoadingPageFromURL:[NSURL URLWithString:startingURL]];
    }
    return self;
}

- (void) dealloc {
/*	[currentImage release];
	[nextImage release];
	[webView release];
	[startingURL release];
	[currentPageTitle release];
	[nextPageTitle release]
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
}

- (void)stopAnimation {
    [super stopAnimation];
}

- (BOOL)isOpaque {
	return YES;
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
	
	float elapsedTime = CFAbsoluteTimeGetCurrent()-periodStartTime;
//	NSLog(@"%s imagesize=%0.2f,%0.2f", _cmd, [currentImage size].width, [currentImage size].height);
//	NSLog(@"%s torect=%0.2f,%0.2f,%0.2f,%0.2f", _cmd, currentToRect.origin.x, currentToRect.origin.y, currentToRect.size.width, currentToRect.size.height);
//	NSLog(@"%s fromrect=%0.2f,%0.2f,%0.2f,%0.2f", _cmd, currentFromRect.origin.x, currentFromRect.origin.y, currentFromRect.size.width, currentFromRect.size.height);
//	NSLog(@"%s SUPER DONE", _cmd);
	
	float fraction;
	if(elapsedTime >= periodLength - transitionLength) {
		NSLog(@"%s next image", _cmd);
//		[nextImage drawInRect:nextToRect fromRect:nextFromRect operation:NSCompositeSourceOver fraction:1.0];
		fraction = (periodLength-elapsedTime)/transitionLength;
	}
	else {
		fraction = 1.0;
	}
//	NSLog(@"%s current image", _cmd);
//	[currentImage drawInRect:currentToRect fromRect:currentFromRect operation:NSCompositeSourceOver fraction:fraction];
//	NSLog(@"%s page title", _cmd);
	[currentPageTitle drawAtPoint:titleOrigin withAttributes:titleAttributes];
//	NSLog(@"%s DONE", _cmd);
}

- (void)animateOneFrame {
	float elapsedTime = CFAbsoluteTimeGetCurrent()-periodStartTime;
//	NSLog(@"%s elapsed time=%0.2f", _cmd, elapsedTime);
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

- (void)webImageIsReady:(NSNotification *)notification {
	if([notification object] == offscreenWebView) {
		NSLog(@"%s getting next image", _cmd);
		// Immediately put the first image to screen.  The rest will be pushed by the switchTimer
		BOOL updateImmediately = NO;
		if(nextImage == nil) {
			NSLog(@"%s will update immediatly", _cmd);
			updateImmediately = YES;
		}
		
//		[nextImage release];
		nextImage = [[offscreenWebView imageOfContent] retain];
		nextPageTitle = [[offscreenWebView pageTitle] retain];
		NSLog(@"%s nextimageheight=%0.2f, title=%@", _cmd, [nextImage size].height, nextPageTitle);
		
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
		
		// TODO: remove this test
//		updateImmediately = YES;
		if(updateImmediately) {
			[self switchToNextPage:self];
		}
	}
}

- (void)switchToNextPage:(id)sender {
	NSLog(@"%s %@ -> %@", _cmd, currentPageTitle, nextPageTitle);
	NSImage *lastImage = currentImage;
	NSString *lastPageTitle = currentPageTitle;
	
	currentImage = nextImage;
	currentPageTitle = nextPageTitle;
	currentFromRect = nextFromRect;
	currentToRect = nextToRect;
	currentFocalHeight = nextFocalHeight;
	
	titleOrigin = NSMakePoint([self bounds].size.width,[self bounds].size.height*0.25);
	currentTitleWidth = [currentPageTitle sizeWithAttributes:titleAttributes].width;
	float fontSize = [self bounds].size.height * 0.50;
	[titleAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:fontSize]
						forKey:NSFontAttributeName];

	// TODO: release these
/*	[lastImage release];
	[lastPageTitle release];*/
	
	// Mark this time as the start of the period
	periodStartTime = CFAbsoluteTimeGetCurrent();
	
	// Set the timer to load a new page
	//	[switchTimer release];	// TODO: i think i should need to release this, but if i do, it segfaults
	// TODO: just make 1 switchTimer, and have it repeats:YES
	switchTimer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)periodLength
                                                         target:self
                                                       selector:@selector(switchToNextPage:)
                                                       userInfo:nil
                                                        repeats:NO] retain];
	
	// Start loading the next page
	[offscreenWebView startLoadingRandomPage];
}

@end
