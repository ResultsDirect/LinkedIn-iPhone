//
//  RDLinkedInAuthorizationControllerDelegate.h
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 6/2/11.
//  Copyright 2011 Results Direct. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RDLinkedInAuthorizationController;


@protocol RDLinkedInAuthorizationControllerDelegate <NSObject>

@optional

- (void)linkedInAuthorizationControllerSucceeded:(RDLinkedInAuthorizationController *)controller;

- (void)linkedInAuthorizationControllerFailed:(RDLinkedInAuthorizationController *)controller;

- (void)linkedInAuthorizationControllerCanceled:(RDLinkedInAuthorizationController *)controller;

@end
