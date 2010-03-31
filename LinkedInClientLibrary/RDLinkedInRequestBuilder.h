//
//  RDLinkedInRequestBuilder.h
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/31/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libxml/xmlwriter.h>


@interface RDLinkedInRequestBuilder : NSObject {
  xmlBufferPtr rdBuffer;
  xmlTextWriterPtr rdWriter;
}

+ (NSData *)buildSimpleRequestWithRootNode:(NSString *)rootNode content:(NSString *)content;

- (BOOL)addNodeNamed:(NSString *)nodeName content:(NSString *)content;

- (NSData *)finish;

@end
