//
//  RDLinkedInEngine.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import "RDLinkedInEngine.h"
#import "RDLinkedInRequestBuilder.h"
#import "RDLinkedInResponseParser.h"
#import "GTMNSString+HTML.h"

static NSString *const kAPIBaseURL           = @"http://api.linkedin.com";
static NSString *const kOAuthRequestTokenURL = @"https://api.linkedin.com/uas/oauth/requestToken";
static NSString *const kOAuthAccessTokenURL  = @"https://api.linkedin.com/uas/oauth/accessToken";
static NSString *const kOAuthAuthorizeURL    = @"https://www.linkedin.com/uas/oauth/authorize";
static NSString *const kOAuthInvalidateURL   = @"https://api.linkedin.com/uas/oauth/invalidateToken";

static const unsigned char kRDLinkedInDebugLevel = 0; //setto zero.

NSString *const RDLinkedInEngineRequestTokenNotification = @"RDLinkedInEngineRequestTokenNotification";
NSString *const RDLinkedInEngineAccessTokenNotification  = @"RDLinkedInEngineAccessTokenNotification";
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
  if( self = [super init] ) {
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


#pragma mark misc public methods

- (NSString *)pathForBundleResource:(NSString *)name ofType:(NSString *)ext {
  static NSBundle* bundle = nil;
  if( !bundle ) {
    NSString* path = [[[NSBundle mainBundle] resourcePath]
                      stringByAppendingPathComponent:@"LinkedIn.bundle"];
    bundle = [[NSBundle bundleWithPath:path] retain];
  }
  
  return [bundle pathForResource:name ofType:ext];
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

- (NSURLRequest *)authorizationFormURLRequest {
	OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kOAuthAuthorizeURL] consumer:nil token:rdOAuthRequestToken realm:nil signatureProvider:nil] autorelease];
	[request setParameters: [NSArray arrayWithObject: [[[OARequestParameter alloc] initWithName:@"oauth_token" value:rdOAuthRequestToken.key] autorelease]]];	
  return request;
}

- (void)requestAccessInvalidation {
	[self sendTokenRequestWithURL:[NSURL URLWithString:kOAuthInvalidateURL]
							token:rdOAuthRequestToken
						onSuccess:@selector(logoutRequestSucceeded:data:)
						   onFail:@selector(logoutRequestFailed:data:)];

}

-(void)logout{
	[self requestAccessInvalidation];
	
	if( [rdDelegate respondsToSelector:@selector(linkedInEngineAccessToken:removeAccessToken:)] ) {
		[rdDelegate linkedInEngineAccessToken:self removeAccessToken:rdOAuthAccessToken];
	}
	
	[rdOAuthAccessToken release];
	rdOAuthAccessToken = nil;

	
	NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
	//NSLog(@"cookies: %@", cookies);
	for(NSHTTPCookie *c in cookies){
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:c];
	}
	
}

-(void)logoutRequestFailed:(OAServiceTicket *)ticket data:(NSData *)data{
	//NSLog(@"logoutRequestFailed");
}
-(void)logoutRequestSucceeded:(OAServiceTicket *)ticket data:(NSData *)data{
	//NSLog(@"logoutRequestSucceeded");
	//NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	//NSLog(@"RESPONSE; %@", dataString);
}

- (RDLinkedInConnectionID *)sendInvitation:(NSString *)memberID subject:(NSString *)subject body:(NSString *)body
						authorizationName:(NSString *)authorizationName authorizationValue:(NSString *)authorizationValue{
	
	//was lazy & couldn't figure out th xmlwriter stuff.
	NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingString:@"/v1/people/~/mailbox"]];
	
	NSString *xmlRequest = [NSString stringWithFormat:@"<?xml version='1.0' encoding='UTF-8'?>\
							<mailbox-item>\
								<recipients>\
									<recipient>\
										<person path=\"/people/id=%@\" />\
									</recipient>\
								</recipients>\
								<subject>%@</subject>\
								<body>%@</body>\
								<item-content>\
									<invitation-request>\
										<connect-type>friend</connect-type>\
										<authorization>\
											<name>%@</name>\
											<value>%@</value>\
										</authorization>\
									</invitation-request>\
								</item-content>\
							</mailbox-item>",
							memberID, subject, body, authorizationName, authorizationValue];
	//NSLog(@"request: %@", xmlRequest);
	NSData *requestData = [xmlRequest dataUsingEncoding:NSUTF8StringEncoding];
	return [self sendAPIRequestWithURL:url HTTPMethod:@"POST" body:requestData];

/*
	RDLinkedInRequestBuilder *requestBuilder = [[RDLinkedInRequestBuilder alloc] init];
	BOOL ret = [requestBuilder openNodeNamed:@"mailbox-item"];
	NSLog(@"request: %@; ret = %d", [requestBuilder buffer], ret);

	[requestBuilder openNodeNamed:@"recipients"];
	[requestBuilder openNodeNamed:@"recipient"];
	NSLog(@"request: %@", [requestBuilder buffer]);
	NSString *personPath = [NSString stringWithFormat:@"/people/id=%@", memberID];
	[requestBuilder addNodeNamed:@"person" attributes:[NSDictionary dictionaryWithObject:personPath forKey:@"path"]];
	[requestBuilder closeNode]; //recipient
	NSLog(@"request: %@", [requestBuilder buffer]);
	[requestBuilder closeNode]; //recipients.
	
	[requestBuilder addNodeNamed:@"subject" content:subject];
	[requestBuilder addNodeNamed:@"body" content:body];
	NSLog(@"request: %@", [requestBuilder buffer]);
	
	[requestBuilder openNodeNamed:@"item-content"];
	[requestBuilder openNodeNamed:@"invitation-request"];
	NSLog(@"request: %@", [requestBuilder buffer]);
	[requestBuilder addNodeNamed:@"connect-type" content:@"friend"];
	[requestBuilder openNodeNamed:@"authorization"];
	[requestBuilder addNodeNamed:@"name" content:authorizationName];
	NSLog(@"request: %@", [requestBuilder buffer]);
	[requestBuilder addNodeNamed:@"value" content:authorizationValue];
	[requestBuilder closeNode]; //authorization
	NSLog(@"request: %@", [requestBuilder buffer]);
	[requestBuilder closeNode]; //invitation-request
	[requestBuilder closeNode]; //item-content.
	NSLog(@"request: %@", [requestBuilder buffer]);
	[requestBuilder closeNode]; //mailbox-item
	NSLog(@"request: %@", [requestBuilder buffer]);
 NSData* requestData = [requestBuilder finish];
 [requestBuilder release];
	*/
	
	
	
}


#pragma mark profile methods

-(NSString *)fieldSelectors{
	return @"id,first-name,last-name,headline,site-standard-profile-request,picture-url,distance";
}
- (RDLinkedInConnectionID *)profileForCurrentUser {
  NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingFormat:@"/v1/people/~:(%@,positions:(title,company:(name)),api-standard-profile-request,connections:())", [self fieldSelectors]]]; //connections:(id),
//	NSLog(@"profileForCurrentUser: %@", url);
  return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (RDLinkedInConnectionID *)profileForPersonWithID:(NSString *)memberID{
//  NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingFormat:@"/v1/people/id=%@:(%@)", [memberID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [self fieldSelectors]]];
	  NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingFormat:@"/v1/people/id=%@:(id,distance)", [memberID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
//	NSLog(@"profileForPersonWithID: %@ - %@", memberID, url);
  return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

-(NSString *)linkedInLocaleCode{
	//NSLocaleLanguageCode_NSLocaleCountryCode	
	NSLocale *locale = [NSLocale currentLocale];
	return [NSString stringWithFormat:@"%@_%@", [locale objectForKey:NSLocaleLanguageCode], [locale objectForKey:NSLocaleCountryCode]]; 
}

- (RDLinkedInConnectionID *)updateStatus:(NSString *)newStatus {
	//http://developer.linkedin.com/docs/DOC-1009
	NSURL* url = [NSURL URLWithString:[kAPIBaseURL stringByAppendingString:@"/v1/people/~/person-activities"]];
	NSString *xmlRequest = [NSString stringWithFormat:@"<?xml version='1.0' encoding='UTF-8'?>\
							<activity locale=\"%@\">\
							<content-type>linkedin-html</content-type>\
							<body>%@</body>\
							</activity>", [self linkedInLocaleCode], [newStatus gtm_stringByEscapingForHTML]];
	NSData *requestData = [xmlRequest dataUsingEncoding:NSUTF8StringEncoding];
	return [self sendAPIRequestWithURL:url HTTPMethod:@"POST" body:requestData];
}


#pragma mark private

- (RDLinkedInConnectionID *)sendAPIRequestWithURL:(NSURL *)url HTTPMethod:(NSString *)method body:(NSData *)body {
  if( !self.isAuthorized ) return nil;
  //NSLog(@"sending API request to %@", url);
  
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
  
	//NSLog(@"response: %@", [[[NSString alloc] initWithData:[connection data] encoding:NSUTF8StringEncoding] autorelease]);
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
	//NSLog(@"oauthTicketFailed! %@", ticket);
  
  // notification of authentication failure
  [[NSNotificationCenter defaultCenter]
   postNotificationName:RDLinkedInEngineAuthFailureNotification object:self];
}

- (void)setRequestTokenFromTicket:(OAServiceTicket *)ticket data:(NSData *)data {
  //NSLog(@"got request token ticket response: %@ (%lu bytes)", ticket, (unsigned long)[data length]);
	if (!ticket.didSucceed || !data) return;
	
	NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if (!dataString) return;
	
	[rdOAuthRequestToken release];
	rdOAuthRequestToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
  //NSLog(@"  request token set %@", rdOAuthRequestToken.key);
	
  if( rdOAuthVerifier.length ) rdOAuthRequestToken.pin = rdOAuthVerifier;
  
  // notification of request token
  [[NSNotificationCenter defaultCenter]
   postNotificationName:RDLinkedInEngineRequestTokenNotification object:self
   userInfo:[NSDictionary dictionaryWithObject:rdOAuthRequestToken forKey:RDLinkedInEngineTokenKey]];
}

- (void)setAccessTokenFromTicket:(OAServiceTicket *)ticket data:(NSData *)data {
  //NSLog(@"got access token ticket response: %@ (%lu bytes)", ticket, (unsigned long)[data length]);
	if (!ticket.didSucceed || !data) return;
	
	NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if (!dataString) return;
  
	if( rdOAuthVerifier.length && [dataString rangeOfString:@"oauth_verifier"].location == NSNotFound ) {
    dataString = [dataString stringByAppendingFormat:@"&oauth_verifier=%@", rdOAuthVerifier];
  }
	
  [rdOAuthAccessToken release];
	rdOAuthAccessToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
  //NSLog(@"  access token set %@", rdOAuthAccessToken.key);
  
	if( [rdDelegate respondsToSelector:@selector(linkedInEngineAccessToken:setAccessToken:)] ) {
    [rdDelegate linkedInEngineAccessToken:self setAccessToken:rdOAuthAccessToken];
  }
  
  // notification of access token
  [[NSNotificationCenter defaultCenter]
   postNotificationName:RDLinkedInEngineAccessTokenNotification object:self
   userInfo:[NSDictionary dictionaryWithObject:rdOAuthAccessToken forKey:RDLinkedInEngineTokenKey]];
}


#pragma mark NSURLConnectionDelegate


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  NSLog(@"received credential challenge!");
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
    NSLog(@"%@ (%d) [%@]:\r%@",
          connection.request.URL,
          [resp statusCode], 
          [NSHTTPURLResponse localizedStringForStatusCode:[resp statusCode]], 
          [resp allHeaderFields]);
  }
  
  if( statusCode >= 400 ) {
    // error response; just abort now
    NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:nil];
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
	NSLog(@"connection didFailWithError: %@", error);
	if( [rdDelegate respondsToSelector:@selector(linkedInEngine:requestFailed:withError:)] ) {
		[rdDelegate linkedInEngine:self requestFailed:connection.identifier withError:error];
  }
  
  [self closeConnection:connection];
}


- (void)connectionDidFinishLoading:(RDLinkedInHTTPURLConnection *)connection {
  NSData *receivedData = [connection data];
  if( [receivedData length] ) {
    if( kRDLinkedInDebugLevel > 0 ) {
      //NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
      //NSLog(@"Succeeded! Received %d bytes of data:\r\r%@", [receivedData length], dataString);
    }
    
    if( kRDLinkedInDebugLevel > 8 ) {
      // Dump XML to file for debugging.
      NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
		//NSLog(@"connectionDidFinishLoading: %@", dataString);
      [dataString writeToFile:[@"~/Desktop/linkedin_messages.xml" stringByExpandingTildeInPath] 
                   atomically:NO encoding:NSUnicodeStringEncoding error:NULL];
    }
    
    [self parseConnectionResponse:connection];
  }
  
  // Release the connection.
  [rdConnections removeObjectForKey:[connection identifier]];
}

@end
