//
//  RDLinkedInHTTPURLConnection.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import "RDLinkedInHTTPURLConnection.h"
#import "NSString+UUID.h"


@implementation RDLinkedInHTTPURLConnection

@synthesize request = rdRequest;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate {
  if( self = [super initWithRequest:request delegate:delegate] ) {
    rdRequest = [request retain];
    rdData = [[NSMutableData alloc] init];
  }
  return self;
}

- (void)dealloc {
  [rdRequest release];
  [rdData release];
  [rdIdentifier release];
  [super dealloc];
}

- (RDLinkedInConnectionID *)identifier {
  if( !rdIdentifier ) {
    rdIdentifier = [[NSString stringWithNewUUID] retain];
  }
  return rdIdentifier;
}

- (NSData *)data {
  return rdData;
}

- (void)appendData:(NSData *)data {
  [rdData appendData:data];
}

- (void)resetData {
  [rdData setLength:0];
}

@end
