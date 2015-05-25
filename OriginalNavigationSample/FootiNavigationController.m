/**
 * Copyright (c) 2014年 fotome. All rights reserved.
 */

#import "FootiNavigationController.h"
#import <QuartzCore/QuartzCore.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) \
    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


static const CGFloat kAnimationDuration = 0.4f;
static const CGFloat kAnimationDelay = 0.0f;
static const CGFloat kMaxBlackMaskAlpha = 0.8f;

typedef enum {
    PanDirectionNone = 0,
    PanDirectionLeft = 1,
    PanDirectionRight = 2
} PanDirection;


@interface FootiNavigationController ()<UIGestureRecognizerDelegate>{
    NSMutableArray *_gestures;
    UIView *_blackMask;
    CGPoint _panOrigin;
    BOOL _animationInProgress;
}

- (void) addPanGestureToView:(UIView*)view;
- (void) rollBackViewController;

- (UIViewController *)currentViewController;
- (UIViewController *)previousViewController;

- (void) transformAtPercentage:(CGFloat)percentage ;
- (void) completeSlidingAnimationWithDirection:(PanDirection)direction;
- (void) completeSlidingAnimationWithOffset:(CGFloat)offset;
- (CGRect) getSlidingRectWithPercentageOffset:(CGFloat)percentage orientation:(UIInterfaceOrientation)orientation ;
- (CGRect) viewBoundsWithOrientation:(UIInterfaceOrientation)orientation;

@end

@implementation FootiNavigationController

- (id) initWithRootViewController:(UIViewController*)rootViewController {
    if (self = [super init]) {
        self.viewControllers = [NSMutableArray arrayWithObject:rootViewController];
    }
    return self;
}

- (void) dealloc {
    self.viewControllers = nil;
    _gestures  = nil;
    _blackMask = nil;
}

#pragma mark - Load View
- (void) loadView {
    [super loadView];
    CGRect viewRect = [self viewBoundsWithOrientation:self.interfaceOrientation];

    UIViewController *rootViewController = [self.viewControllers objectAtIndex:0];
    [rootViewController willMoveToParentViewController:self];
    [self addChildViewController:rootViewController];

    UIView * rootView = rootViewController.view;
    rootView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    rootView.frame = viewRect;
    [self.view addSubview:rootView];
    [rootViewController didMoveToParentViewController:self];
    _blackMask = [[UIView alloc] initWithFrame:viewRect];
    _blackMask.backgroundColor = [UIColor blackColor];
    _blackMask.alpha = 0.0;
    _blackMask.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:_blackMask atIndex:0];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

#pragma mark - PushViewController With Completion Block
- (void) pushViewController:(UIViewController *)viewController completion:(FootiNavigationControllerCompletionBlock)handler {
    _animationInProgress = YES;
    viewController.view.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
    viewController.view.autoresizingMask =  UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _blackMask.alpha = 0.0;
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    [self.view bringSubviewToFront:_blackMask];
    [self.view addSubview:viewController.view];
    [UIView animateWithDuration:kAnimationDuration delay:kAnimationDelay options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGAffineTransform transf = CGAffineTransformIdentity;
        transf = CGAffineTransformScale(transf, 1.0f, 0.9f);
        transf = CGAffineTransformTranslate(transf, -30.0f, 0.0f);
        [self currentViewController].view.transform = transf;
        viewController.view.frame = self.view.bounds;
        _blackMask.alpha = kMaxBlackMaskAlpha;
    } completion:^(BOOL finished) {
        if (finished) {
            [self.viewControllers addObject:viewController];
            [viewController didMoveToParentViewController:self];
            _animationInProgress = NO;
            _gestures = [[NSMutableArray alloc] init];
            [self addPanGestureToView:[self currentViewController].view];
            handler();
        }
    }];
}

- (void) pushViewController:(UIViewController *)viewController {
    [self pushViewController:viewController completion:^{}];
}

#pragma mark - PopViewController With Completion Block
- (void) popViewControllerWithCompletion:(FootiNavigationControllerCompletionBlock)handler {
    _animationInProgress = YES;
    if (self.viewControllers.count < 2) {
        return;
    }

    UIViewController *currentVC = [self currentViewController];
    UIViewController *previousVC = [self previousViewController];
    [previousVC viewWillAppear:NO];
    [UIView animateWithDuration:kAnimationDuration delay:kAnimationDelay options:UIViewAnimationOptionCurveEaseOut animations:^{
        currentVC.view.frame = CGRectOffset(self.view.bounds, self.view.bounds.size.width, 0);
        CGAffineTransform transf = CGAffineTransformIdentity;
        previousVC.view.transform = CGAffineTransformScale(transf, 1.0, 1.0);
        previousVC.view.frame = self.view.bounds;
        _blackMask.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [currentVC.view removeFromSuperview];
            [currentVC willMoveToParentViewController:nil];
            [self.view bringSubviewToFront:[self previousViewController].view];
            [currentVC removeFromParentViewController];
            [currentVC didMoveToParentViewController:nil];
            [self.viewControllers removeObject:currentVC];
            _animationInProgress = NO;
            [previousVC viewDidAppear:NO];
            handler();
        }
    }];
}

- (void) popViewController {
    [self popViewControllerWithCompletion:^{}];
}

- (void) rollBackViewController {
    _animationInProgress = YES;

    UIViewController * vc = [self currentViewController];
    UIViewController * nvc = [self previousViewController];
    CGRect rect = CGRectMake(0, 0, vc.view.frame.size.width, vc.view.frame.size.height);

    [UIView animateWithDuration:0.3f delay:kAnimationDelay options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGAffineTransform transf = CGAffineTransformIdentity;
        nvc.view.transform = CGAffineTransformScale(transf, 1.0f, 0.9f);
        vc.view.frame = rect;
        _blackMask.alpha = kMaxBlackMaskAlpha;
    }   completion:^(BOOL finished) {
        if (finished) {
            _animationInProgress = NO;
        }
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

}

#pragma mark - ChildViewController
- (UIViewController *)currentViewController {
    UIViewController *result = nil;
    if ([self.viewControllers count] > 0) {
        result = [self.viewControllers lastObject];
    }
    return result;
}

#pragma mark - ParentViewController
- (UIViewController *)previousViewController {
    UIViewController *result = nil;
    if ([self.viewControllers count] > 1) {
        result = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
    }
    return result;
}

#pragma mark - Add Pan Gesture
- (void) addPanGestureToView:(UIView*)view
{
    // NSLog(@"ADD PAN GESTURE $$### %i",[_gestures count]);
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(gestureRecognizerDidPan:)];
    panGesture.cancelsTouchesInView = YES;
    panGesture.delegate = self;
    [view addGestureRecognizer:panGesture];
    [_gestures addObject:panGesture];
    panGesture = nil;
}

# pragma mark - Avoid Unwanted Vertical Gesture
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    // x (横方向) の移動距離が y (縦方向) の移動距離より大きい場合に
    // ジェスチャーを認識し始めるようにする。
    CGPoint translation = [panGestureRecognizer translationInView:self.view];
    return fabs(translation.x) > fabs(translation.y) ;
}

#pragma mark - Gesture recognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // UIGestureRecognizerDelegate の中ではじめに呼ばれる。
    // touch イベントを受け付けるかどうかを判定する。
    // アニメーション中は受け付けない。
    UIViewController * vc =  [self.viewControllers lastObject];
    _panOrigin = vc.view.frame.origin;
    gestureRecognizer.enabled = YES;
    return !_animationInProgress;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 複数のジェスチャーを同時に認識させる。
    return YES;
}

#pragma mark - Handle Panning Activity
- (void) gestureRecognizerDidPan:(UIPanGestureRecognizer*)panGesture {
    if(_animationInProgress) return;

    CGPoint currentPoint = [panGesture translationInView:self.view];
    CGFloat movingDistanceX = currentPoint.x + _panOrigin.x;

    PanDirection panDirection = PanDirectionNone;
    CGPoint vel = [panGesture velocityInView:self.view];

    if (vel.x > 0) {
        panDirection = PanDirectionRight;
    } else {
        panDirection = PanDirectionLeft;
    }

    CGFloat offset = 0;

    UIViewController *vc ;
    vc = [self currentViewController];
    offset = CGRectGetWidth(vc.view.frame) - movingDistanceX;
    // 右へドラッグすると offset は小さくなっていく。

    CGFloat percentageOffsetFromLeft = offset / [self viewBoundsWithOrientation:self.interfaceOrientation].size.width;
    vc.view.frame = [self getSlidingRectWithPercentageOffset:percentageOffsetFromLeft orientation:self.interfaceOrientation];
    [self transformAtPercentage:percentageOffsetFromLeft];

    if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) {
        // If velocity is greater than 100 the Execute the Completion base on pan direction
        if (abs(vel.x) > 100) {
            [self completeSlidingAnimationWithDirection:panDirection];
        } else {
            [self completeSlidingAnimationWithOffset:offset];
        }
    }
}

#pragma mark - Set the required transformation based on percentage
- (void) transformAtPercentage:(CGFloat)percentage {
    // ドラッグしている間の previous view のアニメーション.
    CGAffineTransform transf = CGAffineTransformIdentity; // アフィン変換の初期化
    CGFloat newTransformValue = 1.0f - (percentage * 10) / 100; // 等倍が最大 == 1.0f
    transf = CGAffineTransformScale(transf, 1.0f, newTransformValue);

    // 移動後の x 座標 = 起点となる座標 + (起点 * 割合 / 100);
    // 起点となる座標は -30 だが、previous view になる時点で -30 で保存されている
    // ので、不要。起点となる座標 - (マイナス) になってるのは、
    // percentage が 0 -> 100 でなく 100 -> になってるから反転させている。
    // percentage に 100 をかけているのは、percentage の桁 (0.85)を合わせるため。
    CGFloat newTransformX = - (30 * percentage * 100 / 100);

    NSLog(@"newTransformX : %f", newTransformX);
    transf = CGAffineTransformTranslate(transf, newTransformX, 0.0f);

    [self previousViewController].view.transform = transf;

    CGFloat newAlphaValue = percentage * kMaxBlackMaskAlpha;
    _blackMask.alpha = newAlphaValue;
}

#pragma mark - This will complete the animation base on pan direction
- (void) completeSlidingAnimationWithDirection:(PanDirection)direction {
    if (direction == PanDirectionRight){
        [self popViewController];
    } else {
        [self rollBackViewController];
    }
}

#pragma mark - This will complete the animation base on offset
- (void) completeSlidingAnimationWithOffset:(CGFloat)offset{
    if (offset<[self viewBoundsWithOrientation:self.interfaceOrientation].size.width/2) {
         [self popViewController];
    } else {
        [self rollBackViewController];
    }
}

#pragma mark - Get the origin and size of the visible viewcontrollers(child)
- (CGRect) getSlidingRectWithPercentageOffset:(CGFloat)percentage orientation:(UIInterfaceOrientation)orientation {
    // ドラッグしている間の current view のアニメーション.
    CGRect viewRect = [self viewBoundsWithOrientation:orientation];
    CGRect rectToReturn = CGRectZero;
    rectToReturn.size = viewRect.size;
    rectToReturn.origin =
        CGPointMake(MAX(0, (1-percentage) * viewRect.size.width), 0.0);
    return rectToReturn;
}

#pragma mark - Get the size of view in the device screen
- (CGRect) viewBoundsWithOrientation:(UIInterfaceOrientation)orientation{
    // ステータスバー領域を含む画面のサイズを取得.
    CGRect bounds = [UIScreen mainScreen].bounds;
    if ([[UIApplication sharedApplication] isStatusBarHidden]) {
        return bounds;
    } else if(UIInterfaceOrientationIsLandscape(orientation)) {
        // 横向きの場合
        CGFloat width = bounds.size.width;
        bounds.size.width = bounds.size.height;
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            bounds.size.height = width - 20;
        } else {
            bounds.size.height = width;
        }
        return bounds;
    } else {
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            bounds.size.height-=20;
        }
        return bounds;
    }
}

@end



#pragma mark - UIViewController Category
//For Global Access of flipViewController
@implementation UIViewController (FootiNavigationController)
@dynamic footiNavigationController;

- (FootiNavigationController *)footiNavigationController
{
    
    if([self.parentViewController isKindOfClass:[FootiNavigationController class]]){
        return (FootiNavigationController*)self.parentViewController;
    }
    else if([self.parentViewController isKindOfClass:[UINavigationController class]] &&
            [self.parentViewController.parentViewController isKindOfClass:[FootiNavigationController class]]){
        return (FootiNavigationController*)[self.parentViewController parentViewController];
    }
    else{
        return nil;
    }
    
}


@end
