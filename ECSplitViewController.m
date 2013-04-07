//
//  ECSplitViewController.m
//
//  Created by Evgeny Cherpak on 12/10/12.
//  Copyright (c) 2012 Evgeny Cherpak. All rights reserved.
//

#import "ECSplitViewController.h"
#import <QuartzCore/QuartzCore.h>

#define MASTER_WIDTH 320.0
#define DEVIDER_WIDTH 1.0

@interface ECSplitViewController ()

@property (nonatomic, assign) BOOL masterInPopover;

@property (nonatomic, strong) UITapGestureRecognizer* tapGestureRecognizer;

@property (nonatomic, readwrite, assign) UIViewController* masterViewController;
@property (nonatomic, readwrite, assign) UIViewController* detailViewController;

@end

@implementation ECSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _masterHidden = [self.delegate splitViewController:self
                              shouldHideViewController:self.masterViewController
                                         inOrientation:self.interfaceOrientation];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:[UIDevice currentDevice]];
    
    if (!self.tapGestureRecognizer) {
        UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [tapGestureRecognizer setDelegate:self];
        [tapGestureRecognizer setCancelsTouchesInView:NO];
        [self.view addGestureRecognizer:tapGestureRecognizer];
        self.tapGestureRecognizer = tapGestureRecognizer;
    }
    
    if ( [self.delegate splitViewController:self
                   shouldHideViewController:self.masterViewController
                              inOrientation:self.interfaceOrientation] )
    {
        [self.delegate splitViewController:self
                    willHideViewController:self.masterViewController
                         withBarButtonItem:[self showMasterBarButton]];
        
        [self hideView:[self.masterViewController view] hide:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    [self masterStateChanged];
}

- (void)viewWillLayoutSubviews
{
    [self masterStateChanged];
    
    [super viewWillLayoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // when this VC is not presented, need to monitor background orientation
    // changes to keep it synced
	[[NSNotificationCenter defaultCenter] addObserver:self
		   selector:@selector(orientationChanged:)
			   name:UIDeviceOrientationDidChangeNotification
			 object:[UIDevice currentDevice]];
}

- (void)orientationChanged:(NSNotification *)notification
{
    UIViewController* masterVC = [self masterViewController];
    
    if ( ![self.delegate splitViewController:self shouldHideViewController:self.masterViewController inOrientation:[[UIApplication sharedApplication] statusBarOrientation]] ) {
        [masterVC.view layer].shadowOpacity = 0.0f;
        [masterVC.view layer].shadowOffset = CGSizeZero;
        [masterVC.view layer].shadowColor = [UIColor clearColor].CGColor;
    }
    
    [masterVC.view layer].shadowPath = [UIBezierPath bezierPathWithRect:masterVC.view.layer.bounds].CGPath;

    BOOL shouldHideViewController = [self.delegate splitViewController:self
                                              shouldHideViewController:masterVC
                                                         inOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    [self setMasterHidden:shouldHideViewController];
}

- (void)setMasterViewController:(UIViewController *)masterViewController
{
    [_masterViewController.view removeFromSuperview];
    [_masterViewController willMoveToParentViewController:nil];
    [_masterViewController removeFromParentViewController];
    _masterViewController = nil;
    
    [self addChildViewController:masterViewController];
    [masterViewController didMoveToParentViewController:self];

    [self.view addSubview:masterViewController.view];    
    
    _masterViewController = masterViewController;
}

- (void)setDetailViewController:(UIViewController *)detailViewController
{
    if ( self.masterInPopover ) {
        self.masterInPopover = NO;
    }
    
    [_detailViewController.view removeFromSuperview];
    [_detailViewController willMoveToParentViewController:nil];
    [_detailViewController removeFromParentViewController];
    _detailViewController = nil;
    
    [self addChildViewController:detailViewController];
    [detailViewController didMoveToParentViewController:self];

    [self.view addSubview:detailViewController.view];
        
    _detailViewController = detailViewController;
}

- (void)setViewControllers:(NSArray *)viewControllers
{
    _viewControllers = nil;

    self.masterViewController = viewControllers[0];
    self.detailViewController = viewControllers[1];
    
    _viewControllers = viewControllers;
    
    [self masterStateChanged];
}

- (UINavigationController*)masterNavigationController
{
    if ( [self.masterViewController isKindOfClass:[UINavigationController class]] )
        return (UINavigationController*)self.masterViewController;
    
    return nil;
}

- (UINavigationController*)detailNavigationController
{
    if ( [self.detailViewController isKindOfClass:[UINavigationController class]] )
        return (UINavigationController*)self.detailViewController;
    
    return nil;
}

- (void)slideMasterFromSide
{
    if ( ![self isMasterHidden] )
        return;
    
    self.masterInPopover = YES;
    
    [self hideView:[self.masterViewController view] hide:NO];
    
    UIViewController* masterVC = [self masterViewController];
    [[masterVC view] setFrame:CGRectMake(self.view.bounds.origin.x - MASTER_WIDTH, self.view.bounds.origin.y, MASTER_WIDTH, self.view.bounds.size.height)];

    [masterVC.view layer].shadowOpacity = 0.50f;
    [masterVC.view layer].shadowOffset = CGSizeMake(5.0f, 0.0f);
    [masterVC.view layer].shadowColor = [UIColor blackColor].CGColor;
    [masterVC.view layer].shadowPath = [UIBezierPath bezierPathWithRect:masterVC.view.layer.bounds].CGPath;
    
    [UIView animateWithDuration:0.3f animations:^{
        [masterVC viewWillAppear:YES];
        
        CGRect origFrame = [[masterVC view] frame];
        origFrame.origin.x = self.view.bounds.origin.x;
        origFrame.size.width = MASTER_WIDTH;
        
        [[masterVC view] setFrame:origFrame];
    } completion:^(BOOL finished) {
        if ( finished )
            [masterVC viewDidAppear:YES];
    }];
}

- (void)hideView:(UIView*)view hide:(BOOL)hide
{
    if ( hide ) {
        [view setAlpha:0.0f];
        [self.view sendSubviewToBack:view];
    } else {
        [view setAlpha:1.0f];
        [self.view bringSubviewToFront:view];
        
        [view layer].shadowOpacity = 0.0f;
        [view layer].shadowOffset = CGSizeZero;
        [view layer].shadowColor = [UIColor clearColor].CGColor;
    }
}

- (void)slideMasterToSide
{
    UIViewController* masterVC = [self masterViewController];
    
    [UIView animateWithDuration:0.3f animations:^{
        [masterVC viewWillDisappear:YES];
        
        [[masterVC view] setFrame:CGRectMake(self.view.bounds.origin.x - MASTER_WIDTH, self.view.bounds.origin.y, MASTER_WIDTH, self.view.bounds.size.height)];
    } completion:^(BOOL finished) {
        if ( finished ) {
            [self hideView:[self.masterViewController view] hide:YES];
            self.masterInPopover = NO;
            
            [masterVC viewDidDisappear:YES];
        }
    }];
}

- (void)masterStateChanged
{
    CGFloat masterWidth = MASTER_WIDTH;
    CGFloat deviderWidth = DEVIDER_WIDTH;
    
    CGFloat masterOffset = 0.0f;
    
    if ( [self isMasterHidden] && !self.masterInPopover ) {
        masterOffset = masterOffset - MASTER_WIDTH;
    }
    
    if ( [[self.masterViewController view] superview] == self.view ) {
        CGRect newFrame = CGRectMake(masterOffset, 0, masterWidth, self.view.bounds.size.height);
        if (!CGRectEqualToRect(newFrame, [self.masterViewController.view frame]))
            [self.masterViewController.view setFrame:newFrame];
    }
    
    CGFloat detailOffset = masterWidth + deviderWidth;
    CGFloat detailWidth = self.view.bounds.size.width - detailOffset;
    
    if ( [self isMasterHidden] ) {
        detailOffset = 0.0f;
        detailWidth = self.view.bounds.size.width;
    }
    
    if ( [[self.detailViewController view] superview] == self.view ) {
        CGRect newFrame = CGRectMake(detailOffset, 0, detailWidth, self.view.bounds.size.height);
        if (!CGRectEqualToRect(newFrame, [self.detailViewController.view frame]))
            [self.detailViewController.view setFrame:newFrame];
    }
}

- (UIBarButtonItem*)showMasterBarButton
{
    UIViewController* vc = nil;
    if ( [self.masterViewController isKindOfClass:[UINavigationController class]] ) {
        UINavigationController* masterNav = (UINavigationController*)self.masterViewController;
        vc = masterNav.topViewController;
    } else {
        vc = self.masterViewController;
    }
    return [[UIBarButtonItem alloc] initWithTitle:vc.title style:UIBarButtonItemStyleBordered target:self action:@selector(slideMasterFromSide)];
}

- (UIBarButtonItem*)toggleMasterHiddenBarButtonItem
{
    UIImage* arrowImage = nil;
    if ( [self isMasterHidden] ) {
        arrowImage = [UIImage imageNamed:@"WRightArrow"];
    } else {
        arrowImage = [UIImage imageNamed:@"WLeftArrow"];
    }
    
    return [[UIBarButtonItem alloc] initWithImage:arrowImage
                              landscapeImagePhone:arrowImage
                                            style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(toggleMasterHidden)];
}

- (void)toggleMasterHidden
{
    [self setMasterHidden:![self isMasterHidden]];
}

- (void)setMasterHidden:(BOOL)masterHidden
{
    if ( !masterHidden ) {
        [self.delegate splitViewController:self willShowViewController:self.masterViewController invalidatingBarButtonItem:[self showMasterBarButton]];
        [self hideView:[self.masterViewController view] hide:NO];
        self.masterInPopover = NO;
    }
    
    _masterHidden = masterHidden;
    
    if ( !masterHidden ) {
        CGRect startMasterRect = CGRectMake(0 - MASTER_WIDTH, 0, MASTER_WIDTH, self.view.bounds.size.height);
        [[self.masterViewController view] setFrame:startMasterRect];
    }
    
    if ( masterHidden )
        [self.masterViewController viewWillDisappear:self.view.window != nil];
    else
        [self.masterViewController viewWillAppear:self.view.window != nil];

    if ( self.view.window ) {
        [UIView animateWithDuration:0.3f animations:^{
            CGRect newMasterRect = CGRectZero;
            CGRect newDetailRect = CGRectZero;
            
            if ( masterHidden ) {
                newMasterRect = CGRectOffset([[self.masterViewController view] frame], -MASTER_WIDTH, 0);
                newDetailRect = [self.view bounds];
            } else {
                newMasterRect = CGRectMake(0, 0, MASTER_WIDTH, self.view.bounds.size.height);
                newDetailRect = CGRectMake(MASTER_WIDTH + DEVIDER_WIDTH, 0, self.view.bounds.size.width - MASTER_WIDTH - DEVIDER_WIDTH, self.view.bounds.size.height);
            }
            
            [[self.masterViewController view] setFrame:newMasterRect];
            [[self.detailViewController view] setFrame:newDetailRect];
            
        } completion:^(BOOL finished) {
            if ( finished && [self isMasterHidden] ) {
                [self.delegate splitViewController:self willHideViewController:self.masterViewController withBarButtonItem:[self showMasterBarButton]];
                [self hideView:[self.masterViewController view] hide:YES];
            }

            if ( finished ) {
                if ( masterHidden )
                    [self.masterViewController viewDidDisappear:YES];
                else
                    [self.masterViewController viewDidAppear:YES];
            }
        }];
    } else {
        [self masterStateChanged];
        if ( [self isMasterHidden] ) {
            [self.delegate splitViewController:self willHideViewController:self.masterViewController withBarButtonItem:[self showMasterBarButton]];
            [self hideView:[self.masterViewController view] hide:YES];
        }
        
        if ( masterHidden )
            [self.masterViewController viewDidDisappear:NO];
        else
            [self.masterViewController viewDidAppear:NO];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    UIViewController* masterVC = [self masterViewController];
    
    if ( ![self.delegate splitViewController:self shouldHideViewController:self.masterViewController inOrientation:toInterfaceOrientation] ) {
        [masterVC.view layer].shadowOpacity = 0.0f;
        [masterVC.view layer].shadowOffset = CGSizeZero;
        [masterVC.view layer].shadowColor = [UIColor clearColor].CGColor;
    }
    [masterVC.view layer].shadowPath = [UIBezierPath bezierPathWithRect:masterVC.view.layer.bounds].CGPath;

    BOOL shouldHideViewController = [self.delegate splitViewController:self shouldHideViewController:self.masterViewController inOrientation:toInterfaceOrientation];
    
    if ( self.masterHidden != shouldHideViewController )
        [self setMasterHidden:shouldHideViewController];
    else {
        [[masterVC view] setFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, MASTER_WIDTH, self.view.bounds.size.height)];        
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)handleSingleTap:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if ( self.masterInPopover ) {
        CGPoint tapLocation = [tapGestureRecognizer locationInView:[tapGestureRecognizer view]];
        if (!CGRectContainsPoint([[self.masterViewController view] frame], tapLocation)) {
            [self slideMasterToSide];
        }
    }
}

@end

@implementation UIViewController (ECSplitViewController)

- (ECSplitViewController *)ecSplitViewController
{
    UIViewController *viewController = self.parentViewController;
    while (!(viewController == nil || [viewController isKindOfClass:[ECSplitViewController class]])) {
        viewController = viewController.parentViewController;
    }
    
    return (ECSplitViewController *)viewController;
}

@end
