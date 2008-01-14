//
//  WWOfflineImageSource.h
//  WikiWalker
//
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WWOffscreenWebView.h"


@interface WWOfflineImageSource : WWOffscreenWebView {
    int _currentImageNum;
    NSArray *_images;
}


@end
