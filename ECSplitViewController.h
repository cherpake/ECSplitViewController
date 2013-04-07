//
//  ECSplitViewController.h
//
//  Created by Evgeny Cherpak on 12/10/12.
//  Copyright (c) 2012 Evgeny Cherpak. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ECSplitViewControllerDelegate;

@interface ECSplitViewController : UIViewController<UIGestureRecognizerDelegate>

@property(nonatomic,getter=isMasterHidden) BOOL masterHidden;

@property (nonatomic, copy) NSArray *viewControllers;

@property (nonatomic, readonly) UIViewController *masterViewController;
@property (nonatomic, readonly) UIViewController *detailViewController;
@property (nonatomic, readonly) UINavigationController* masterNavigationController;
@property (nonatomic, readonly) UINavigationController* detailNavigationController;

@property (nonatomic, assign) id <ECSplitViewControllerDelegate> delegate;

@property (nonatomic, readonly) UIBarButtonItem* showMasterBarButton;
@property (nonatomic, readonly) UIBarButtonItem* toggleMasterHiddenBarButtonItem;

- (void)setMasterViewController:(UIViewController *)masterViewController;
- (void)setDetailViewController:(UIViewController *)detailViewController;

- (void)setMasterHidden:(BOOL)masterHidden;
- (void)slideMasterFromSide;
- (void)slideMasterToSide;

@end

@protocol ECSplitViewControllerDelegate

@required

// Called when a button should be added to a toolbar for a hidden view controller.
// Implementing this method allows the hidden view controller to be presented via a swipe gesture if 'presentsWithGesture' is 'YES' (the default).
- (void)splitViewController:(ECSplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem;

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(ECSplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem;

//// Called when the view controller is shown in a popover so the delegate can take action like hiding other popovers.
//- (void)splitViewController:(UISplitViewController *)svc popoverController:(UIPopoverController *)pc willPresentViewController:(UIViewController *)aViewController;

// Returns YES if a view controller should be hidden by the split view controller in a given orientation.
// (This method is only called on the leftmost view controller and only discriminates portrait from landscape.)
- (BOOL)splitViewController:(ECSplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation;

@end

@interface UIViewController (ECSplitViewControllerExtension)

- (ECSplitViewController*)ecSplitViewController; // If the view controller has a split view controller as its ancestor, return it. Returns nil otherwise.

@end
