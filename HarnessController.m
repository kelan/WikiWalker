//
//  HarnessController.m
//  TestScreenSaver
//
//  Created by Ben Gottlieb on 3/31/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import "HarnessController.h"

@implementation HarnessController

- (void)awakeFromNib {
	NSTimeInterval interval = [_saverView animationTimeInterval];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:interval
                                              target:self
                                            selector:@selector(animationTimerFired:)
                                            userInfo:nil
                                             repeats:YES] retain];
	[_saverView startAnimation];
}

- (void)animationTimerFired:(NSTimer *)timer {
	[_saverView animateOneFrame];
}

- (IBAction)configure:(id)sender {
	[NSApp beginSheet:[_saverView configureSheet]
       modalForWindow:_window
        modalDelegate:_saverView
       didEndSelector:nil
          contextInfo:nil];
}

@end
