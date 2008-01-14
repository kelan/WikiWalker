//
//  WWOfflineImageSource.m
//  WikiWalker
//
//  Copyright 2007 Kelan Champagne. All rights reserved.
//

#import "WWOfflineImageSource.h"

#import "WWScreenSaverView.h"

@implementation WWOfflineImageSource

- (id)initWithFrame:(NSRect)frame {
    self = [super init];
	if (self != nil) {
        NSString *defaultImageDirName = @"yrk default images";
	    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
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
        
        _images = [[NSArray arrayWithArray:images] retain];
        _currentImageNum = SSRandomIntBetween(0, [_images count]-1);
        
        [self setPageTitle:@"Offline Mode"];
	}
	return self;
}

- (void)startLoadingPageFromURL:(NSURL *)newURL {
    
    // Pick a new random image, and make sure it's not the one we're already showing
    int newImageNum = _currentImageNum;
    while(newImageNum == _currentImageNum) {
        newImageNum = SSRandomIntBetween(0, [_images count]-1);
    }
    _currentImageNum = newImageNum;
    _heightOfNextLink = SSRandomFloatBetween(0, [[_images objectAtIndex:_currentImageNum] size].height);
    
	// Post a Notification that the next page is ready so the WWScreenSaverView can pick it up
    [[NSNotificationCenter defaultCenter] postNotificationName:@"YRK_WWNextImageReady"
                                                        object:self];
}


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Accessors
//------------------------------------------------------------------------------

- (NSImage *)imageOfContent {
    return [_images objectAtIndex:_currentImageNum];
}

@end
