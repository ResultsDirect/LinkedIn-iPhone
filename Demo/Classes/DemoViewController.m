//
//  DemoViewController.m
//  Demo
//
//  Created by Sixten Otto on 3/31/10.
//  Copyright Results Direct 2010. All rights reserved.
//

#import "DemoViewController.h"

#import "RDLinkedIn.h"


// !!!: replace these empty values with your actual LinkedIn tokens
static NSString *const kOAuthConsumerKey     = @"";
static NSString *const kOAuthConsumerSecret  = @"";


@interface DemoViewController ()

@property (nonatomic, retain) RDLinkedInEngine* engine;
@property (nonatomic, retain) RDLinkedInConnectionID* fetchConnection;

- (void)updateUI:(NSString *)status;
- (void)fetchProfile;

@end


@implementation DemoViewController

@synthesize statusLabel;
@synthesize logInButton;
@synthesize logOutButton;
@synthesize engine;
@synthesize fetchConnection;


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
  if( self.engine.isAuthorized ) {
    [self.engine requestTokenInvalidation];
  }
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

- (void)fetchProfile {
  self.fetchConnection = [self.engine profileForCurrentUser];
  [self updateUI:[@"fetching profile on " stringByAppendingString:[self.fetchConnection description]]];
}


#pragma mark - view lifecycle

- (void)awakeFromNib {
  [super awakeFromNib];
  
  self.engine = [RDLinkedInEngine engineWithConsumerKey:kOAuthConsumerKey consumerSecret:kOAuthConsumerSecret delegate:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self updateUI:nil];
  if( self.engine.isAuthorized ) {
    [self fetchProfile];
  }
}

- (void)viewDidUnload {
  [super viewDidUnload];
  [self setStatusLabel:nil];
  [self setLogInButton:nil];
  [self setLogOutButton:nil];
}

- (void)dealloc {
  if( fetchConnection ) [engine closeConnectionWithID:fetchConnection];
  
  [fetchConnection release];
  [engine release];
  [statusLabel release];
  [logInButton release];
  [logOutButton release];
  [super dealloc];
}


#pragma mark - RDLinkedInEngineDelegate

- (void)linkedInEngineAccessToken:(RDLinkedInEngine *)engine setAccessToken:(OAToken *)token {
  if( token ) {
    [token rd_storeInUserDefaultsWithServiceProviderName:@"LinkedIn" prefix:@"Demo"];
  }
  else {
    [OAToken rd_clearUserDefaultsUsingServiceProviderName:@"LinkedIn" prefix:@"Demo"];
    [self updateUI:@"logged out"];
  }
}

- (OAToken *)linkedInEngineAccessToken:(RDLinkedInEngine *)engine {
  return [OAToken rd_tokenWithUserDefaultsUsingServiceProviderName:@"LinkedIn" prefix:@"Demo"];
}

- (void)linkedInEngine:(RDLinkedInEngine *)engine requestSucceeded:(RDLinkedInConnectionID *)identifier withResults:(id)results {
  NSLog(@"++ LinkedIn engine reports success for connection %@\n%@", identifier, results);
  if( identifier == self.fetchConnection ) {
    NSDictionary* profile = results;
    [self updateUI:[NSString stringWithFormat:@"got profile for %@ %@", [profile objectForKey:@"first-name"], [profile objectForKey:@"last-name"]]];
  }
}

- (void)linkedInEngine:(RDLinkedInEngine *)engine requestFailed:(RDLinkedInConnectionID *)identifier withError:(NSError *)error {
  NSLog(@"++ LinkedIn engine reports failure for connection %@\n%@", identifier, [error localizedDescription]);
}


#pragma mark - RDLinkedInAuthorizationControllerDelegate

- (void)linkedInAuthorizationControllerSucceeded:(RDLinkedInAuthorizationController *)controller {
  [self fetchProfile];
}

- (void)linkedInAuthorizationControllerFailed:(RDLinkedInAuthorizationController *)controller {
  [self updateUI:@"failed!"];
}

- (void)linkedInAuthorizationControllerCanceled:(RDLinkedInAuthorizationController *)controller {
  [self updateUI:@"cancelled"];
}

@end
