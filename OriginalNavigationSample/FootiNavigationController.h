/**
 * Copyright (c) 2014年 fotome. All rights reserved.
 */

#import <UIKit/UIKit.h>

typedef void (^FootiNavigationControllerCompletionBlock)(void);

@interface FootiNavigationController : UIViewController

@property(nonatomic, retain) NSMutableArray *viewControllers;

- (id) initWithRootViewController:(UIViewController*)rootViewController;

- (void) pushViewController:(UIViewController *)viewController;
- (void) pushViewController:(UIViewController *)viewController completion:(FootiNavigationControllerCompletionBlock)handler;
- (void) popViewController;
- (void) popViewControllerWithCompletion:(FootiNavigationControllerCompletionBlock)handler;

@end


@interface UIViewController (FootiNavigationController)

@property (nonatomic, retain) FootiNavigationController *footiNavigationController;

@end

