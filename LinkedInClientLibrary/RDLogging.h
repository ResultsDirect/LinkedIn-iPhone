//
//  RDLogging.h
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 6/2/11.
//  Copyright 2011 Results Direct. All rights reserved.
//

/*
 * Because NSLog can be a resource hog, clutters up the debug console, and so
 * many people have alternatives they prefer (have you seen NSLogger?), let's
 * define some macros to use instead. Feel free to provide your own definitions
 * of these to prevent the defaults from being defined.
 */

#ifndef RDLOG

#define RDLOG(...) NSLog(__VA_ARGS__)

#endif
