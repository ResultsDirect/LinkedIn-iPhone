//
//  RDLinkedInAuthorizationController.h
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//  
//  Based in large part on the OAuth enhancements to MGTwitterEngine by Ben Gottlieb
//  <http://github.com/bengottlieb/Twitter-OAuth-iPhone>
//

#import <UIKit/UIKit.h>

#import "RDLinkedInAuthorizationControllerDelegate.h"

@class RDLinkedInEngine;


@interface RDLinkedInAuthorizationController : UIViewController <UIWebViewDelegate> {
  id<RDLinkedInAuthorizationControllerDelegate> rdDelegate;
  RDLinkedInEngine* rdEngine;
  UINavigationBar*  rdNavBar;
  UIWebView*        rdWebView;
}

@property (nonatomic, assign)   id<RDLinkedInAuthorizationControllerDelegate> delegate;
@property (nonatomic, readonly) RDLinkedInEngine* engine;
@property (nonatomic, readonly) UINavigationBar* navigationBar;

+ (id)authorizationControllerWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationControllerDelegate>)delegate;

- (id)initWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationControllerDelegate>)delegate;
- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInAuthorizationControllerDelegate>)delegate;

@end
