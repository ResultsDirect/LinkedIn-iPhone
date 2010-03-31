//
//  RDLinkedInEngine.h
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//
//  Significant inspiration and code from MGTwitterEngine by Matt Gemmell
//    and the OAuth enhancements to same by Ben Gottlieb
//  <http://mattgemmell.com/source#mgtwitterengine>
//  <http://github.com/bengottlieb/Twitter-OAuth-iPhone>
//

#import <Foundation/Foundation.h>
#import <OAuthConsumer/OAuthConsumer.h>
#import "RDLinkedInHTTPURLConnection.h"

@class RDLinkedInEngine;


extern NSString *const RDLinkedInEngineRequestTokenNotification;
extern NSString *const RDLinkedInEngineAccessTokenNotification;
extern NSString *const RDLinkedInEngineAuthFailureNotification;
extern NSString *const RDLinkedInEngineTokenKey;

extern const NSUInteger kRDLinkedInMaxStatusLength;


@protocol RDLinkedInEngineDelegate <NSObject>
  
@optional

- (void)linkedInEngineAccessToken:(RDLinkedInEngine *)engine setAccessToken:(OAToken *)token;
- (OAToken *)linkedInEngineAccessToken:(RDLinkedInEngine *)engine;

- (void)linkedInEngine:(RDLinkedInEngine *)engine requestSucceeded:(RDLinkedInConnectionID *)identifier withResults:(id)results;
- (void)linkedInEngine:(RDLinkedInEngine *)engine requestFailed:(RDLinkedInConnectionID *)identifier withError:(NSError *)error;

@end


@interface RDLinkedInEngine : NSObject {
  id<RDLinkedInEngineDelegate> rdDelegate;
	OAConsumer* rdOAuthConsumer;
	OAToken*    rdOAuthRequestToken;
	OAToken*    rdOAuthAccessToken;
  NSString*   rdOAuthVerifier;
  NSMutableDictionary* rdConnections;
}

@property (nonatomic, readonly) BOOL isAuthorized;
@property (nonatomic, readonly) BOOL hasRequestToken;
@property (nonatomic, retain) NSString* verifier;

+ (id)engineWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInEngineDelegate>)delegate;
- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInEngineDelegate>)delegate;

- (NSUInteger)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnectionWithID:(RDLinkedInConnectionID *)identifier;
- (void)closeAllConnections;

- (void)requestRequestToken;
- (void)requestAccessToken;
- (NSURLRequest *)authorizationFormURLRequest;

- (RDLinkedInConnectionID *)profileForCurrentUser;
- (RDLinkedInConnectionID *)profileForPersonWithID:(NSString *)memberID;

- (RDLinkedInConnectionID *)updateStatus:(NSString *)newStatus;

@end
