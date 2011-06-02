//
//  DemoViewController.m
//  Demo
//
//  Created by Sixten Otto on 3/31/10.
//  Copyright Results Direct 2010. All rights reserved.
//

#import <OAuthConsumer/OAToken.h>

#import "DemoViewController.h"

#import "RDLinkedInEngine.h"
#import "RDLinkedInAuthorizationController.h"


// !!!: replace these empty values with your actual LinkedIn tokens
static NSString *const kOAuthConsumerKey     = @"";
static NSString *const kOAuthConsumerSecret  = @"";


@interface DemoViewController ()

@property (nonatomic, retain) RDLinkedInEngine* engine;

- (void)updateUI:(NSString *)status;

@end


@implementation DemoViewController

@synthesize statusLabel;
@synthesize logInButton;
@synthesize logOutButton;
@synthesize engine;


#pragma mark - public API

- (IBAction)logIn:(id)sender {
  RDLinkedInAuthorizationController* controller = [RDLinkedInAuthorizationController authorizationControllerWithEngine:self.engine delegate:self];
  if( controller ) {
    [self presentModalViewController:controller animated:YES];
  }
  else {
    NSLog(@"Already authenticated");
  }
}

- (IBAction)logOut:(id)sender {
}


#pragma mark - private API

- (void)updateUI:(NSString *)status {
  if( self.engine.isAuthorized ) {
    self.statusLabel.text = @"Authorized";
    self.logInButton.enabled = NO;
    self.logOutButton.enabled = YES;
  }
  else {
    self.statusLabel.text = @"Not authorized";
    self.logInButton.enabled = YES;
    self.logOutButton.enabled = NO;
  }
  
  if( status ) {
    self.statusLabel.text = [NSString stringWithFormat:@"%@: %@", self.statusLabel.text, status];
  }
}


#pragma mark - view lifecycle

- (void)awakeFromNib {
  [super awakeFromNib];
  
  self.engine = [RDLinkedInEngine engineWithConsumerKey:kOAuthConsumerKey consumerSecret:kOAuthConsumerSecret delegate:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self updateUI:nil];
}

- (void)viewDidUnload {
  [super viewDidUnload];
  [self setStatusLabel:nil];
  [self setLogInButton:nil];
  [self setLogOutButton:nil];
}

- (void)dealloc {
  [engine release];
  [statusLabel release];
  [logInButton release];
  [logOutButton release];
  [super dealloc];
}


#pragma mark - RDLinkedInEngineDelegate

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


#pragma mark - RDLinkedInAuthorizationControllerDelegate

- (void)linkedInAuthorizationControllerSucceeded:(RDLinkedInAuthorizationController *)controller {
  [self updateUI:nil];
  NSLog(@"Fetching current user's profile on connection %@", [controller.engine profileForCurrentUser]);
}

- (void)linkedInAuthorizationControllerFailed:(RDLinkedInAuthorizationController *)controller {
  [self updateUI:@"failed!"];
}

- (void)linkedInAuthorizationControllerCanceled:(RDLinkedInAuthorizationController *)controller {
  [self updateUI:@"cancelled"];
}

@end
