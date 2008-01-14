//
//  HarnessController.h
//  TestScreenSaver
//
//  Created by Ben Gottlieb on 3/31/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import "WWScreenSaverView.h"

@interface HarnessController : NSObject {
	IBOutlet ComYeahRightKeller_WWScreenSaverView *_saverView;
	IBOutlet NSWindow *_window;
	
	NSTimer *_animationTimer;
}

- (void)animationTimerFired:(NSTimer *)timer;
- (IBAction)configure: (id)sender;

@end
