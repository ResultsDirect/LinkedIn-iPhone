//
//  DemoAppDelegate.m
//  Demo
//
//  Created by Sixten Otto on 3/31/10.
//  Copyright Results Direct 2010. All rights reserved.
//

#import "DemoAppDelegate.h"
#import "DemoViewController.h"

@implementation DemoAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
