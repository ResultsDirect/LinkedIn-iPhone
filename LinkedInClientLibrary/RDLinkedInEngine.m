//
//  RDLinkedInEngine.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import <OAuthConsumer/OAuthConsumer.h>

#import "RDLinkedInEngine.h"
#import "RDLinkedInHTTPURLConnection.h"
#import "RDLinkedInRequestBuilder.h"
#import "RDLinkedInResponseParser.h"
#import "RDLogging.h"

static NSString *const kAPIBaseURL           = @"http://api.linkedin.com";
static NSString *const kOAuthRequestTokenURL = @"https://api.linkedin.com/uas/oauth/requestToken";
static NSString *const kOAuthAccessTokenURL  = @"https://api.linkedin.com/uas/oauth/accessToken";
static NSString *const kOAuthAuthorizeURL    = @"https://www.linkedin.com/uas/oauth/authorize";
static NSString *const kOAuthInvalidateURL   = @"https://api.linkedin.com/uas/oauth/invalidateToken";

static const unsigned char kRDLinkedInDebugLevel = 0;

NSString *const RDLinkedInEngineRequestTokenNotification = @"RDLinkedInEngineRequestTokenNotification";
NSString *const RDLinkedInEngineAccessTokenNotification  = @"RDLinkedInEngineAccessTokenNotification";
NSString *const RDLinkedInEngineTokenInvalidationNotification  = @"RDLinkedInEngineTokenInvalidationNotification";
NSString *const RDLinkedInEngineAuthFailureNotification  = @"RDLinkedInEngineAuthFailureNotification";
NSString *const RDLinkedInEngineTokenKey                 = @"RDLinkedInEngineTokenKey";

const NSUInteger kRDLinkedInMaxStatusLength = 140;


@interface RDLinkedInEngine ()

- (RDLinkedInConnectionID *)sendAPIRequestWithURL:(NSURL *)url HTTPMethod:(NSString *)method body:(NSData *)body;
- (void)sendTokenRequestWithURL:(NSURL *)url token:(OAToken *)token onSuccess:(SEL)successSel onFail:(SEL)failSel;

@end


@implementation RDLinkedInEngine

@synthesize verifier = rdOAuthVerifier;

+ (id)engineWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInEngineDelegate>)delegate {
  return [[[self alloc] initWithConsumerKey:consumerKey consumerSecret:consumerSecret delegate:delegate] autorelease];
}

- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInEngineDelegate>)delegate {
  self = [super init];
  if( self != nil ) {
    rdDelegate = delegate;
    rdOAuthConsumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret];
    rdConnections = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  rdDelegate = nil;
  [rdOAuthConsumer release];
  [rdOAuthRequestToken release];
  [rdOAuthAccessToken release];
  [rdOAuthVerifier release];
  [rdConnections release];
  [super dealloc];
}


#pragma mark connection methods

- (NSUInteger)numberOfConnections {
  return [rdConnections count];
}

- (NSArray *)connectionIdentifiers {
  return [rdConnections allKeys];
}

- (void)closeConnection:(RDLinkedInHTTPURLConnection *)connection {
  if( connection ) {
    [connection cancel];
    [rdConnections removeObjectForKey:connection.identifier];
  }
}

- (void)closeConnectionWithID:(RDLinkedInConnectionID *)identifier {
  [self closeConnection:[rdConnections objectForKey:identifier]];
}

- (void)closeAllConnections {
  [[rdConnections allValues] makeObjectsPerformSelector:@selector(cancel)];
  [rdConnections removeAllObjects];
}


#pragma mark authorization methods

- (BOOL)isAuthorized {
  if( rdOAuthAccessToken.key && rdOAuthAccessToken.secret ) return YES;
  
  // check for cached creds
  if( [rdDelegate respondsToSelector:@selector(linkedInEngineAccessToken:)] ) {
    [rdOAuthAccessToken release];
    rdOAuthAccessToken = [[rdDelegate linkedInEngineAccessToken:self] retain];
    if( rdOAuthAccessToken.key && rdOAuthAccessToken.secret ) return YES;
  }
  
  // no valid access token found
  [rdOAuthAccessToken release];
  rdOAuthAccessToken = nil;
  return NO;
}

- (BOOL)hasRequestToken {
  return (rdOAuthRequestToken.key && rdOAuthRequestToken.secret);
}

- (void)requestRequestToken {
  [self sendTokenRequestWithURL:[NSURL URLWithString:kOAuthRequestTokenURL]
                          token:nil
                      onSuccess:@selector(setRequestTokenFromTicket:data:)
                         onFail:@selector(oauthTicketFailed:data:)];
}

- (void)requestAccessToken {
  [self sendTokenRequestWithURL:[NSURL URLWithString:kOAuthAccessTokenURL]
                          token:rdOAuthRequestToken
                      onSuccess:@selector(setAccessTokenFromTicket:data:)
                         onFail:@selector(oauthTicketFailed:data:)];
}

- (void)requestTokenInvalidation {
  [self sendTokenRequestWithURL:[NSURL URLWithString:kOAuthInvalidateURL]
                          token:rdOAuthRequestToken
                      onSuccess:@selector(tokenInvalidationSucceeded:data:)
                         onFail:@selector(oauthTicketFailed:data:)];
}

- (NSURLRequest *)authorizationFormURLRequest {
  OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kOAuthAuthorizeURL] consumer:nil token:rdOAuthRequestToken realm:nil signatureProvider:nil] autorelease];
  [request setParameters: [NSArray arrayWithObject: [[[OARequestParameter alloc] initWithName:@"oauth_token" value:rdOAuthRequestToken.key] autorelease]]];	
  return request;
}


#pragma mark profile methods

- (RDLinkedInConnectionID *)profileForCurrentUser {
  NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingString:@"/v1/people/~"]];
  return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (RDLinkedInConnectionID *)profileForPersonWithID:(NSString *)memberID {
  NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingFormat:@"/v1/people/id=%@", [memberID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
  return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (RDLinkedInConnectionID *)updateStatus:(NSString *)newStatus {
  NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingString:@"/v1/people/~/current-status"]];
  newStatus = [newStatus length] > kRDLinkedInMaxStatusLength ? [newStatus substringToIndex:kRDLinkedInMaxStatusLength] : newStatus;
  NSData* body = [RDLinkedInRequestBuilder buildSimpleRequestWithRootNode:@"current-status" content:newStatus];
  return [self sendAPIRequestWithURL:url HTTPMethod:@"PUT" body:body];
}

- (RDLinkedInConnectionID *)shareUrl:(NSString *)submittedUrl imageUrl:(NSString *)submittedImageUrl title:(NSString*)title comment:(NSString*)comment {
  NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingString:@"/v1/people/~/shares"]];

  comment = [comment length] > kRDLinkedInMaxStatusLength ? [comment substringToIndex:kRDLinkedInMaxStatusLength] : comment;

  NSString *xml = [[NSString alloc] initWithFormat:@"			\
				   <share>										\
				   <comment>%@</comment>						\
				   <content>									\
				   <title>%@</title>							\
				   <submitted-url>%@</submitted-url>			\
				   <submitted-image-url>%@</submitted-image-url>\
				   </content>									\
				   <visibility>									\
				   <code>anyone</code>							\
				   </visibility>								\
				   </share>",
				   comment,
				   title,
				   submittedUrl,
				   submittedImageUrl];
	
  // Cleaning the XML content
  xml = [xml stringByReplacingOccurrencesOfString:@"\n" withString:@""];
  xml = [xml stringByReplacingOccurrencesOfString:@"	" withString:@""];
	 
  xml = [[NSString alloc]
		   initWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n%@",xml];
	
  NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
	
  //NSLog(@"xml=%@", xml);
  //NSLog(@"data=%@", data);
	
  return [self sendAPIRequestWithURL:url HTTPMethod:@"POST" body:data];
}

#pragma mark private

- (RDLinkedInConnectionID *)sendAPIRequestWithURL:(NSURL *)url HTTPMethod:(NSString *)method body:(NSData *)body {
  if( !self.isAuthorized ) return nil;
  RDLOG(@"sending API request to %@", url);
  
  // create and configure the URL request
  OAMutableURLRequest* request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                  consumer:rdOAuthConsumer 
                                                                     token:rdOAuthAccessToken 
                                                                     realm:nil
                                                         signatureProvider:nil] autorelease];
  [request setHTTPShouldHandleCookies:NO];
  [request setValue:@"text/xml;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
  if( method ) {
    [request setHTTPMethod:method];
  }
  
  // prepare the request before setting the body, because OAuthConsumer wants to parse the body
  // for parameters to include in its signature, but LinkedIn doesn't work that way
  [request prepare];
  if( [body length] ) {
    [request setHTTPBody:body];
  }
  
  // initiate a URL connection with this request
  RDLinkedInHTTPURLConnection* connection = [[[RDLinkedInHTTPURLConnection alloc] initWithRequest:request delegate:self] autorelease];
  if( connection ) {
    [rdConnections setObject:connection forKey:connection.identifier];
  }
  
  return connection.identifier;
}

- (void)parseConnectionResponse:(RDLinkedInHTTPURLConnection *)connection {
  NSError* error = nil;
  id results = nil;
  
  if( [RDLinkedInResponseParser parseXML:[connection data] connection:connection results:&results error:&error] ) {
    if( [rdDelegate respondsToSelector:@selector(linkedInEngine:requestSucceeded:withResults:)] ) {
      [rdDelegate linkedInEngine:self requestSucceeded:connection.identifier withResults:results];
    }
  }
  else {
    if( [rdDelegate respondsToSelector:@selector(linkedInEngine:requestFailed:withError:)] ) {
      [rdDelegate linkedInEngine:self requestFailed:connection.identifier withError:error];
    }    
  }
}

- (void)sendTokenRequestWithURL:(NSURL *)url token:(OAToken *)token onSuccess:(SEL)successSel onFail:(SEL)failSel {
  OAMutableURLRequest* request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:rdOAuthConsumer token:token realm:nil signatureProvider:nil] autorelease];
	if( !request ) return;
	
  [request setHTTPMethod:@"POST"];
	if( rdOAuthVerifier.length ) token.pin = rdOAuthVerifier;
	
  OADataFetcher* fetcher = [[[OADataFetcher alloc] init] autorelease];	
  [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:successSel didFailSelector:failSel];
}

- (void)oauthTicketFailed:(OAServiceTicket *)ticket data:(NSData *)data {
  //RDLOG(@"oauthTicketFailed! %@", ticket);
  
  // notification of authentication failure
  [[NSNotificationCenter defaultCenter]
   postNotificationName:RDLinkedInEngineAuthFailureNotification object:self];
}

- (void)setRequestTokenFromTicket:(OAServiceTicket *)ticket data:(NSData *)data {
  //RDLOG(@"got request token ticket response: %@ (%lu bytes)", ticket, (unsigned long)[data length]);
  if (!ticket.didSucceed || !data) return;
  
  NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
  if (!dataString) return;
  
  [rdOAuthRequestToken release];
  rdOAuthRequestToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
  //RDLOG(@"  request token set %@", rdOAuthRequestToken.key);
  
  if( rdOAuthVerifier.length ) rdOAuthRequestToken.pin = rdOAuthVerifier;
  
  // notification of request token
  [[NSNotificationCenter defaultCenter]
   postNotificationName:RDLinkedInEngineRequestTokenNotification object:self
   userInfo:[NSDictionary dictionaryWithObject:rdOAuthRequestToken forKey:RDLinkedInEngineTokenKey]];
}

- (void)setAccessTokenFromTicket:(OAServiceTicket *)ticket data:(NSData *)data {
  //RDLOG(@"got access token ticket response: %@ (%lu bytes)", ticket, (unsigned long)[data length]);
  if (!ticket.didSucceed || !data) return;
  
  NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
  if (!dataString) return;
  
  if( rdOAuthVerifier.length && [dataString rangeOfString:@"oauth_verifier"].location == NSNotFound ) {
    dataString = [dataString stringByAppendingFormat:@"&oauth_verifier=%@", rdOAuthVerifier];
  }
  
  [rdOAuthAccessToken release];
  rdOAuthAccessToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
  //RDLOG(@"  access token set %@", rdOAuthAccessToken.key);
  
  if( [rdDelegate respondsToSelector:@selector(linkedInEngineAccessToken:setAccessToken:)] ) {
    [rdDelegate linkedInEngineAccessToken:self setAccessToken:rdOAuthAccessToken];
  }
  
  // notification of access token
  [[NSNotificationCenter defaultCenter]
   postNotificationName:RDLinkedInEngineAccessTokenNotification object:self
   userInfo:[NSDictionary dictionaryWithObject:rdOAuthAccessToken forKey:RDLinkedInEngineTokenKey]];
}

- (void)tokenInvalidationSucceeded:(OAServiceTicket *)ticket data:(NSData *)data {
  OAToken* invalidToken = [rdOAuthAccessToken retain];
  [rdOAuthAccessToken release];
  rdOAuthAccessToken = nil;
  
  NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  for( NSHTTPCookie *c in [cookieStorage cookies] ){
    if( [[c domain] hasSuffix:@".linkedin.com"] ) {
      [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:c];
    }
  }
  
  if( [rdDelegate respondsToSelector:@selector(linkedInEngineAccessToken:setAccessToken:)] ) {
    [rdDelegate linkedInEngineAccessToken:self setAccessToken:nil];
  }
  
  // notification of token invalidation
  [[NSNotificationCenter defaultCenter]
   postNotificationName:RDLinkedInEngineTokenInvalidationNotification object:self
   userInfo:[NSDictionary dictionaryWithObject:invalidToken forKey:RDLinkedInEngineTokenKey]];
}


#pragma mark NSURLConnectionDelegate


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  //RDLOG(@"received credential challenge!");
  [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}


- (void)connection:(RDLinkedInHTTPURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  // This method is called when the server has determined that it has enough information to create the NSURLResponse.
  // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
  [connection resetData];
  
  NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
  int statusCode = [resp statusCode];
  
  if( kRDLinkedInDebugLevel > 5 ) {
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    RDLOG(@"%@ (%d) [%@]:\r%@",
          connection.request.URL,
          [resp statusCode], 
          [NSHTTPURLResponse localizedStringForStatusCode:[resp statusCode]], 
          [resp allHeaderFields]);
  }
  
  if( statusCode >= 400 ) {
    // error response; just abort now
    NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                               [resp allHeaderFields], @"headers",
                                               nil]];
    if( [rdDelegate respondsToSelector:@selector(linkedInEngine:requestFailed:withError:)] ) {
      [rdDelegate linkedInEngine:self requestFailed:connection.identifier withError:error];
    }
    [self closeConnection:connection];
  }
  else if( statusCode == 204 || statusCode == 201) {
    // 204: no content; so skip the parsing, and declare success!
	// 201: created. declare success!
    if( [rdDelegate respondsToSelector:@selector(linkedInEngine:requestSucceeded:withResults:)] ) {
      [rdDelegate linkedInEngine:self requestSucceeded:connection.identifier withResults:nil];
    }
    [self closeConnection:connection];
  }
}


- (void)connection:(RDLinkedInHTTPURLConnection *)connection didReceiveData:(NSData *)data {
  [connection appendData:data];
}


- (void)connection:(RDLinkedInHTTPURLConnection *)connection didFailWithError:(NSError *)error {
  if( [rdDelegate respondsToSelector:@selector(linkedInEngine:requestFailed:withError:)] ) {
    [rdDelegate linkedInEngine:self requestFailed:connection.identifier withError:error];
  }
  
  [self closeConnection:connection];
}


- (void)connectionDidFinishLoading:(RDLinkedInHTTPURLConnection *)connection {
  NSData *receivedData = [connection data];
  if( [receivedData length] ) {
    if( kRDLinkedInDebugLevel > 0 ) {
      NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
      RDLOG(@"Succeeded! Received %d bytes of data:\r\r%@", [receivedData length], dataString);
    }
    
    if( kRDLinkedInDebugLevel > 8 ) {
      // Dump XML to file for debugging.
      NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
      [dataString writeToFile:[@"~/Desktop/linkedin_messages.xml" stringByExpandingTildeInPath] 
                   atomically:NO encoding:NSUnicodeStringEncoding error:NULL];
    }
    
    [self parseConnectionResponse:connection];
  }
  
  // Release the connection.
  [rdConnections removeObjectForKey:[connection identifier]];
}

@end
