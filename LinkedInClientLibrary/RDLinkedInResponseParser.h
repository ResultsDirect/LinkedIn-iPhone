//
//  RDLinkedInResponseParser.h
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//
//  Significant inspiration and code from MGTwitterEngine by Matt Gemmell
//  <http://mattgemmell.com/source#mgtwitterengine>
//

#import <Foundation/Foundation.h>
#include <libxml/xmlreader.h>

extern NSString *const RDLinkedInResponseParserDomain;
extern NSString *const RDLinkedInResponseParserURLKey;

enum {
  RDLinkedInResponseParserReaderError,
  RDLinkedInResponseParserTagMatchingError
};


@class RDLinkedInHTTPURLConnection;


@interface RDLinkedInResponseParser : NSObject {
	NSData *rdXML;
  RDLinkedInHTTPURLConnection* rdConnection;
	xmlTextReaderPtr rdReader;
  id rdResults;
  NSError* rdError;
}

+ (BOOL)parseXML:(NSData *)xml connection:(RDLinkedInHTTPURLConnection *)connection results:(id*)results error:(NSError **)error;

- (id)initWithXML:(NSData *)xml connection:(RDLinkedInHTTPURLConnection *)connection;

- (BOOL)parse:(NSError **)error;
- (id)results;

/*
- (xmlChar *)nodeValue;
- (NSString *)nodeValueAsString;
- (NSDate *)nodeValueAsDate;
- (NSNumber *)nodeValueAsInt;
- (NSNumber *)nodeValueAsBool;
*/

@end
