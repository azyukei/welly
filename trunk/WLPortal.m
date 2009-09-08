//
//  WLPortal.m
//  Welly
//
//  Created by boost on 9/6/09.
//  Copyright 2009 Xi Wang. All rights reserved.
//

#import "WLPortal.h"
#import "WLPortalImage.h"
#import "CommonType.h"
#import "YLApplication.h"
#import "YLController.h"

const float xscale = 1, yscale = 0.8;

// hack
@interface IKImageFlowView : NSOpenGLView
- (void)reloadData;
- (void)setSelectedIndex:(NSUInteger)index;
- (NSUInteger)selectedIndex;
- (NSUInteger)focusedIndex;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
@end

@interface BackgroundColorView : NSView {
    NSColor *_color;
}
- (void)setBackgroundColor:(NSColor *)color;
@end

@implementation BackgroundColorView
- (void)dealloc {
    [_color release];
    [super dealloc];
}
- (void)drawRect:(NSRect)rect {
    [_color set];
    NSRectFill(rect);
}
- (void)setBackgroundColor:(NSColor *)color {
    _color = [color copy];
}
@end


@implementation WLPortal

@synthesize view = _view;

- (void)dealloc {
    [_data release];
    [super dealloc];
}

- (id)initWithView:(NSView *)superview {
    if (self != [super init])
        return nil;
    _data = [[NSMutableArray alloc] init];
    _contentView = [[BackgroundColorView alloc] init];
    _view = [[NSClassFromString(@"IKImageFlowView") alloc] initWithFrame:NSZeroRect];
	[_view setDataSource:self];
    [_view setDelegate:self];
	//[self setDraggingDestinationDelegate:self];
    [_contentView addSubview:_view];
    [superview addSubview:_contentView];
    return self;
}

- (void)loadCovers {
    [_data removeAllObjects];
    // cover directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"~/Library/Application Support");
    NSString *dir = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Welly"] stringByAppendingPathComponent:@"Covers"];
    // load sites
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *sites = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Sites"];
    for (NSDictionary *d in sites) {
        NSString *key = [d objectForKey:@"name"];
        if ([key length] == 0)
            continue;
        // guess the image file name
        NSString *path = nil;
        [[[dir stringByAppendingPathComponent:key] stringByAppendingString:@"."]
            completePathIntoString:&path caseSensitive:NO matchesIntoArray:nil filterTypes:nil];
        WLPortalImage *item = [[WLPortalImage alloc] initWithPath:path title:key];
        [_data addObject:item];
    }
    [pool release];
}

- (void)show {
    NSView *superview = [_contentView superview];
    NSRect frame = [superview frame];
    [_contentView setFrame:frame];
    frame.origin.x += frame.size.width * (1 - xscale) / 2;
    frame.origin.y += frame.size.height * (1 - yscale) / 2;
    frame.size.width *= xscale;
    frame.size.height *= yscale;
    [_view setFrame:frame];
    // background
    NSColor *color = [[YLLGlobalConfig sharedInstance] colorBG];
    // cover flow doesn't support alpha
    color = [color colorWithAlphaComponent:1.0];
    [_contentView setBackgroundColor:color];
    [_view setBackgroundColor:color];
    // event hanlding
    NSResponder *next = [superview nextResponder];
    if (_view != next) {
        [_view setNextResponder:next];
        [superview setNextResponder:_view];
    }
    // fresh
    [_view reloadData];
}

- (void)hide {
    [_contentView setFrame:NSZeroRect];
    NSView *superview = [_contentView superview];
    [superview setNextResponder:[_view nextResponder]];
    [_view setNextResponder:nil];
}

- (void)select {
    [self hide];
    YLController *controller = [((YLApplication *)NSApp) controller];
    YLSite *site = [controller objectInSitesAtIndex:[_view selectedIndex]];
    [controller newConnectionWithSite:site];
}

#pragma mark - 
#pragma mark IKImageFlowDataSource protocol

- (NSUInteger)numberOfItemsInImageFlow:(id)aFlow {
	return [_data count];
}

- (id)imageFlow:(id)aFlow itemAtIndex:(NSUInteger)index {
	return [_data objectAtIndex:index];
}

#pragma mark -
#pragma mark IKImageFlowDelegate protocol

- (void)imageFlow:(id)aFlow cellWasDoubleClickedAtIndex:(NSInteger)index {
    [self select];
}

#pragma mark -
#pragma mark Event Handler

- (void)keyDown:(NSEvent *)theEvent {
	switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0]) {
        case WLWhitespaceCharacter:
        case WLReturnCharacter: {
            [self select];
            return;
        }
    }
    [_view keyDown:theEvent];
}

@end
