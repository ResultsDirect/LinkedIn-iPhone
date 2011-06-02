//
//  RDLinkedInResponseParser.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import "RDLinkedInResponseParser.h"
#import "RDLinkedInHTTPURLConnection.h"
#import "RDLogging.h"

NSString *const RDLinkedInResponseParserDomain = @"RDLinkedInResponseParserDomain";
NSString *const RDLinkedInResponseParserURLKey = @"RDLinkedInResponseParserURLKey";


@implementation RDLinkedInResponseParser

+ (BOOL)parseXML:(NSData *)xml connection:(RDLinkedInHTTPURLConnection *)connection results:(id*)results error:(NSError **)error {
  RDLinkedInResponseParser* parser = [[self alloc] initWithXML:xml connection:connection];
  BOOL success = [parser parse:error];
  
  if( success && results ) {
    *results = [parser results];
  }
  
  [parser release];
  return success;
}

- (id)initWithXML:(NSData *)xml connection:(RDLinkedInHTTPURLConnection *)connection {
  self = [super init];
  if( self != nil ) {
    rdXML = [xml retain];
    rdConnection = [connection retain];
  }
  return self;
}

- (void)dealloc {
  [rdXML release];
  [rdConnection release];
  [rdResults release];
  [rdError release];
  [super dealloc];
}

- (NSError *)genericError {
  return [NSError errorWithDomain:RDLinkedInResponseParserDomain
                             code:RDLinkedInResponseParserReaderError
                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                   rdConnection.request.URL, RDLinkedInResponseParserURLKey,
                                   nil]];
}

- (BOOL)nextNode {
  if( rdError ) return NO;
  
  int result = xmlTextReaderRead(rdReader);
  
  if( result == -1 ) {
    xmlErrorPtr err = xmlGetLastError();
    if( err ) {
      RDLOG(@"libxml error level %i: %s", err->level, err->message);
      // TODO: set rdError properly
      rdError = [[self genericError] retain];
    }
    else {
      rdError = [[self genericError] retain];
    }
  }
  
  return result == 1;
}

- (BOOL)parseInternal {
  NSMutableArray* elementStack = [[NSMutableArray alloc] init];
  NSMutableDictionary* element = nil;
  
  while( [self nextNode] ) {
    int nodeType = xmlTextReaderNodeType(rdReader);
    int depth = xmlTextReaderDepth(rdReader);
    const xmlChar *name = xmlTextReaderConstName(rdReader);
    //RDLOG(@"read node type %2i at depth %3i: %s", nodeType, depth, name);
    
    NSMutableString* text = nil;
    NSMutableDictionary* child = nil;
    NSString* key;
    id currentValue = nil;
    id newValue = nil;
    BOOL forceEndElement = NO;
    
    switch( nodeType ) {
      case XML_READER_TYPE_ELEMENT:
        element = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                   [NSString stringWithUTF8String:(const char *)name], @"#name",
                   [NSMutableString string], @"#text",
                   nil];
        [elementStack addObject:element];
        if( xmlTextReaderIsEmptyElement(rdReader) == 1 ){
          forceEndElement = YES;
        }
        break;
        
      case XML_READER_TYPE_TEXT:
        text = [element objectForKey:@"#text"];
        [text appendString:[NSMutableString stringWithUTF8String:(const char *)xmlTextReaderValue(rdReader)]];
        break;
    }
    
    if( nodeType == XML_READER_TYPE_END_ELEMENT || forceEndElement ) {
      child = [element retain];
      [elementStack removeLastObject];
      //RDLOG(@"popped node %@", child);
      
      key = [[child objectForKey:@"#name"] retain];
      text = [element objectForKey:@"#text"];
      [child removeObjectForKey:@"#name"];
      
      if( [elementStack count] ) {
        element = [elementStack lastObject];
        currentValue = [element objectForKey:key];
        
        if( [child count] == 1 ) {
          // new node has only text, no children
          newValue = text;
        }
        else {
          newValue = child;
          if( [text length] == 0 ) [child removeObjectForKey:@"#text"];
        }
        
        if( !currentValue ) {
          [element setObject:newValue forKey:key];
        }
        else if( [currentValue isKindOfClass:[NSMutableArray class]] ) {
          [currentValue addObject:newValue];
        }
        else {
          currentValue = [NSMutableArray arrayWithObjects:currentValue, newValue, nil];
          [element setObject:currentValue forKey:key];
        }
      }
      else {
        // if the stack emptied before we got back to the root node, that's an error
        // a non-null error pointer will cause the parsing loop to abort on the next pass
        if( depth != 0 ) {
          rdError = [NSError errorWithDomain:RDLinkedInResponseParserDomain
                                        code:RDLinkedInResponseParserTagMatchingError
                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSString stringWithUTF8String:(const char *)name], @"currentElement",
                                              [NSNumber numberWithInt:depth], @"depth",
                                              rdConnection.request.URL, RDLinkedInResponseParserURLKey,
                                              nil]];
        }
        else {
          if( [text length] == 0 ) [child removeObjectForKey:@"#text"];
          rdResults = [child retain];
        }
      }
      [child release];
      [key release];
    }
  }
  
  [elementStack release];
  return !rdError;
}

- (BOOL)parse:(NSError **)error {
  BOOL success = YES;
  
  if( !rdReader ) {
    rdReader = xmlReaderForMemory([rdXML bytes], [rdXML length], [[rdConnection.request.URL absoluteString] UTF8String], nil, XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING);
    if( ! rdReader ) {
      if( error ) *error = [self genericError];
      return NO;
    }
    
    if( !(success = [self parseInternal]) ) {
      if( error ) *error = rdError ? [[rdError retain] autorelease]
                                   : [self genericError];
    }
    
    xmlFree(rdReader);
    rdReader = NULL;
  }
  
  return success;
}

- (id)results {
  if( !rdReader && rdResults ) {
    return [[rdResults retain] autorelease];
  }
  return nil;
}

@end
