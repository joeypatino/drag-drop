//
//  DragDropController.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DragAction.h"

/**
 The duration of the animation when the icon is released
 and moves back to its original position
 */
#define kDropAnimationDuration              .4
#define kDragDropPickupAnimationDuration    .15
#define kDragPickupBeginDelay               .16

@class DragAction;
@class DragDropController;
@protocol DragDropControllerDelegate
@optional

#pragma mark - Drag callbacks

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragAction *)drag
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(DragAction *)drag;

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(DragAction *)drag
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragAction *)drag;

#pragma mark - Drop callbacks

- (void)dragDropController:(DragDropController *)controller
      didStartDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination;

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination;

- (void)dragDropController:(DragDropController *)controller
        didEndDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination;

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination;

@end

@protocol DragDropControllerDatasource

@optional
- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)view;

- (BOOL)dragDropController:(DragDropController *)controller
               canDropView:(UIView *)target
             toDestination:(DragDropController *)destination;

@required
- (UIView *)dragDropController:(DragDropController *)controller
     dragRepresentationForView:(UIView *)view;

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination;

@end

@interface DragDropController : NSObject
@property (nonatomic, weak) NSObject <DragDropControllerDatasource>  *dragDropDataSource;
@property (nonatomic, weak) NSObject <DragDropControllerDelegate>    *dragDropDelegate;
@property (nonatomic, weak) UIView *dropTargetView;

- (void)enableDragActionForView:(UIView *)view;
- (void)disableDragActionForView:(UIView *)view;

@end
