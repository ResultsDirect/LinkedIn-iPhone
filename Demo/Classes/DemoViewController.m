//
//  DemoViewController.m
//  Demo
//
//  Created by Sixten Otto on 3/31/10.
//  Copyright Results Direct 2010. All rights reserved.
//

#import "DemoViewController.h"

// !!!: replace these empty values with your actual LinkedIn tokens
static NSString *const kOAuthConsumerKey     = @"";
static NSString *const kOAuthConsumerSecret  = @"";


@implementation DemoViewController

- (void)loadView {
  [super loadView];
  
  rdEngine = [[RDLinkedInEngine engineWithConsumerKey:kOAuthConsumerKey consumerSecret:kOAuthConsumerSecret delegate:self] retain];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  
  if( !rdHasAppeared ) {
    RDLinkedInAuthorizationController* controller = [RDLinkedInAuthorizationController authorizationControllerWithEngine:rdEngine delegate:self];
    if( controller ) {
      [self presentModalViewController:controller animated:YES];
      rdHasAppeared = YES;
    }
    else {
      NSLog(@"Already authenticated");
    }
  }
}

- (void)viewDidUnload {
  [super viewDidUnload];
  [rdEngine release];
  rdEngine = nil;
}

- (void)dealloc {
  [rdEngine release];
  [super dealloc];
}


#pragma mark -
#pragma mark RDLinkedInEngineDelegate

- (void)linkedInEngineAccessToken:(RDLinkedInEngine *)engine setAccessToken:(OAToken *)token {
	[token storeInUserDefaultsWithServiceProviderName:@"LinkedIn" prefix:@"Demo"];
}

- (OAToken *)linkedInEngineAccessToken:(RDLinkedInEngine *)engine {
  return [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"LinkedIn" prefix:@"Demo"] autorelease];
}

- (void)linkedInEngine:(RDLinkedInEngine *)engine requestSucceeded:(RDLinkedInConnectionID *)identifier withResults:(id)results {
  NSLog(@"++ LinkedIn engine reports success for connection %@\n%@", identifier, results);
}

- (void)linkedInEngine:(RDLinkedInEngine *)engine requestFailed:(RDLinkedInConnectionID *)identifier withError:(NSError *)error {
  NSLog(@"++ LinkedIn engine reports failure for connection %@\n%@", identifier, [error localizedDescription]);
}


#pragma mark -
#pragma mark RDLinkedInAuthorizationControllerDelegate

- (void)linkedInAuthorizationControllerSucceeded:(RDLinkedInAuthorizationController *)controller {
  NSLog(@"Authentication succeeded.");
  NSLog(@"Fetching current user's profile on connection %@", [controller.engine profileForCurrentUser]);
}

- (void)linkedInAuthorizationControllerFailed:(RDLinkedInAuthorizationController *)controller {
  NSLog(@"Authentication failed!");
}

- (void)linkedInAuthorizationControllerCanceled:(RDLinkedInAuthorizationController *)controller {
  NSLog(@"Authentication was cancelled.");
}

@end
