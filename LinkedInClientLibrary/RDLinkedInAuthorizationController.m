//
//  RDLinkedInAuthorizationController.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import <OAuthConsumer/OAuthConsumer.h>

#import "RDLinkedInAuthorizationController.h"
#import "RDLinkedInEngine.h"
#import "RDLogging.h"


@interface RDLinkedInAuthorizationController ()

- (void)displayAuthorization;

@end


@implementation RDLinkedInAuthorizationController

@synthesize delegate = rdDelegate, engine = rdEngine, navigationBar = rdNavBar;

+ (id)authorizationControllerWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationControllerDelegate>)delegate {
	if( engine.isAuthorized ) return nil;
	return [[[self alloc] initWithEngine:engine delegate:delegate] autorelease];
}

- (id)initWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationControllerDelegate>)delegate {
  self = [super initWithNibName:nil bundle:nil];
  if( self != nil ) {
    rdDelegate = delegate;
    rdEngine = [engine retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRequestToken:) name:RDLinkedInEngineRequestTokenNotification object:rdEngine];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAccessToken:) name:RDLinkedInEngineAccessTokenNotification object:rdEngine];
    
    [rdEngine requestRequestToken];
  }
  return self;
}

- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInAuthorizationControllerDelegate>)delegate {
  return [self initWithEngine:[RDLinkedInEngine engineWithConsumerKey:consumerKey consumerSecret:consumerSecret delegate:nil] delegate:delegate];
}

- (void)dealloc {
  rdDelegate = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  rdWebView.delegate = nil;
  [rdWebView stopLoading];
  
  [rdWebView release];
  [rdNavBar release];
  [rdEngine release];
  [super dealloc];
}


- (void)loadView {
  [super loadView];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  rdNavBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
  [rdNavBar setItems:[NSArray arrayWithObject:[[[UINavigationItem alloc] initWithTitle:@"LinkedIn Authorization"] autorelease]]];
  rdNavBar.topItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
  [rdNavBar sizeToFit];
  rdNavBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, rdNavBar.frame.size.height);
  rdNavBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:rdNavBar];
  
  rdWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, rdNavBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - rdNavBar.frame.size.height)];
  rdWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  rdWebView.delegate = self;
  rdWebView.scalesPageToFit = NO;
  rdWebView.dataDetectorTypes = UIDataDetectorTypeNone;
  [self.view addSubview:rdWebView];
  
  [self displayAuthorization];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (void)viewDidUnload {
  rdWebView.delegate = nil;
  [rdWebView stopLoading];
  [rdWebView release];
  rdWebView = nil;
  
  [rdNavBar release];
  rdNavBar = nil;
}


#pragma mark private

- (void)cancel {
  if( [rdDelegate respondsToSelector:@selector(linkedInAuthorizationControllerCanceled:)] ) {
    [rdDelegate linkedInAuthorizationControllerCanceled:self];
  }
  [self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:0.0];
}

- (void)denied {
  if( [rdDelegate respondsToSelector:@selector(linkedInAuthorizationControllerFailed:)] ) {
    [rdDelegate linkedInAuthorizationControllerFailed:self];
  }
  [self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:0.0];
}

- (void)success {
  if( [rdDelegate respondsToSelector:@selector(linkedInAuthorizationControllerSucceeded:)] ) {
    [rdDelegate linkedInAuthorizationControllerSucceeded:self];
  }
  [self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:(id)kCFBooleanTrue afterDelay:1.0];
}

- (void)displayAuthorization {
  if( rdEngine.hasRequestToken ) {
    [rdWebView loadRequest:[rdEngine authorizationFormURLRequest]];
  }
}

- (void)didReceiveRequestToken:(NSNotification *)notification {
  [self displayAuthorization];
}

- (void)didReceiveAccessToken:(NSNotification *)notification {
  [self success];
}

- (BOOL)extractInfoFromHTTPRequest:(NSURLRequest *)request {
  if( !request ) return NO;
  
  NSArray* tuples = [[request.URL query] componentsSeparatedByString: @"&"];
  for( NSString *tuple in tuples ) {
    NSArray *keyValueArray = [tuple componentsSeparatedByString: @"="];
    
    if( keyValueArray.count == 2 ) {
      NSString* key   = [keyValueArray objectAtIndex: 0];
      NSString* value = [keyValueArray objectAtIndex: 1];
      
      if( [key isEqualToString:@"oauth_verifier"] ) {
        rdEngine.verifier = value;
        return YES;
      }
    }
  }
  
  return NO;
}


#pragma mark UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  RDLOG(@"Failed to load page %@", error);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  NSString* host = [[request.URL host] lowercaseString];
  if( [@"linkedin_oauth" isEqualToString:host] ) {
    if( [[request.URL path] isEqualToString:@"/success"] ) {
      // cancel button will redirect to callback URL with an argument, so check that first
      if( [[[[request.URL query] lowercaseString] componentsSeparatedByString:@"&"] containsObject:@"oauth_problem=user_refused"] ) {
        [self cancel];
      }
      else if( [self extractInfoFromHTTPRequest:request] ) {
        [rdEngine requestAccessToken];
      }
      else {
        NSAssert1(NO, @"Trying to load callback page, but insufficient information: %@", request);
      }
    }
    else if( [[request.URL path] isEqualToString:@"/deny"] ) {
      // leaving this path in for backwards-compatibility
      [self denied];
    }
    else {
      NSAssert1(NO, @"Unknown callback URL variant: %@", request);
    }
    return NO;
  }
  else if( [@"www.linkedin.com" isEqualToString:host] ) {
    if( ![[request.URL path] hasPrefix:@"/uas/"] ) {
      [[UIApplication sharedApplication] openURL:request.URL];
    }
  }
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  //RDLOG(@"web view started loading");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  //RDLOG(@"web view finished loading");
}

@end
