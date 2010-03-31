//
//  DemoViewController.h
//  Demo
//
//  Created by Sixten Otto on 3/31/10.
//  Copyright Results Direct 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDLinkedInEngine.h"
#import "RDLinkedInAuthorizationController.h"


@interface DemoViewController : UIViewController <RDLinkedInEngineDelegate, RDLinkedInAuthorizationControllerDelegate> {
  RDLinkedInEngine* rdEngine;
  BOOL rdHasAppeared;
}

@end

