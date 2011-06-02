//
//  RDLinkedInHTTPURLConnection.h
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//
//  Significant inspiration and code from MGTwitterEngine by Matt Gemmell
//  <http://mattgemmell.com/source#mgtwitterengine>
//

#import <Foundation/Foundation.h>

#import "RDLinkedInTypes.h"


@interface RDLinkedInHTTPURLConnection : NSURLConnection {
  NSURLRequest*           rdRequest;
  NSMutableData*          rdData;
  RDLinkedInConnectionID* rdIdentifier;
}

@property (nonatomic, readonly) RDLinkedInConnectionID* identifier;
@property (nonatomic, readonly) NSURLRequest* request;

- (NSData *)data;
- (void)appendData:(NSData *)data;
- (void)resetData;

@end
