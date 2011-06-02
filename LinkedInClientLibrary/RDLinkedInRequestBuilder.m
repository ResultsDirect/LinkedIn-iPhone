//
//  RDLinkedInRequestBuilder.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/31/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import "RDLinkedInRequestBuilder.h"

static const char * kUTF8String = "UTF-8";


@implementation RDLinkedInRequestBuilder

+ (NSData *)buildSimpleRequestWithRootNode:(NSString *)rootNode content:(NSString *)content {
  RDLinkedInRequestBuilder* builder = [[RDLinkedInRequestBuilder alloc] init];
  NSData* req = nil;
  if( builder ) {
    [builder addNodeNamed:rootNode content:content];
    req = [builder finish];
    [builder release];
  }
  return req;
}

- (id)init {
  self = [super init];
  if( self != nil ) {
    BOOL success = NO;
    if( (rdBuffer = xmlBufferCreate()) ) {
      if( (rdWriter = xmlNewTextWriterMemory(rdBuffer, 0)) ) {
        if( xmlTextWriterStartDocument(rdWriter, NULL, kUTF8String, NULL) >= 0 ) {
          success = YES;
        }
      }
    }
    
    if( !success ) {
      [self autorelease];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  xmlFreeTextWriter(rdWriter);
  xmlBufferFree(rdBuffer);
  [super dealloc];
}

- (BOOL)addNodeNamed:(NSString *)nodeName content:(NSString *)content {
  return xmlTextWriterWriteElement(rdWriter, BAD_CAST [nodeName UTF8String], BAD_CAST [content UTF8String]) >= 0;
}

- (NSData *)finish {
  if( xmlTextWriterEndDocument(rdWriter) ) {
    //RDLOG(@"complete request document: %s", xmlBufferContent(rdBuffer));
    return [NSData dataWithBytes:xmlBufferContent(rdBuffer) length:xmlBufferLength(rdBuffer)];
  }
  return nil;
}

@end
