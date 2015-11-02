//
//  DragDropController.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 The duration of the animation when the icon is released
 and moves back to its original position
 */
#define kDropAnimationDuration              .4
#define kDragDropPickupAnimationDuration    .15

@class DragDrop;
@class DragDropController;
@protocol DragDropControllerDelegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragDrop *)dd
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(DragDrop *)dd;

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)sourceView
                   AtPoint:(CGPoint)point;

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(DragDrop *)dd
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragDrop *)dd;

- (void)dragDropController:(DragDropController *)controller
              isMovingView:(UIView *)view
            toNewSuperView:(UIView *)superview;

- (void)dragDropController:(DragDropController *)controller
         isDraggingAtPoint:(CGPoint)point;

- (void)dragDropController:(DragDropController *)controller
      didFinishDragAtPoint:(CGPoint)point;

@end

@protocol DragDropControllerDatasource

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
     animatingToNewSuperView:(UIView *)superview;

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
              inNewSuperView:(UIView *)superview;

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)subview;

- (UIView *)dragDropController:(DragDropController *)controller
           draggingViewAtPoint:(CGPoint)point
                        inView:(UIView *)baseView;

- (UIView *)dragDropController:(DragDropController *)controller
           dropRecieverAtPoint:(CGPoint)point;

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDropView:(UIView *)target
                    ToView:(UIView *)destination;
@end

@class DragDrop;
@interface DragDropController : NSObject
@property (nonatomic, weak) NSObject <DragDropControllerDatasource>  *dragDropDataSource;
@property (nonatomic, weak) NSObject <DragDropControllerDelegate>    *dragDropDelegate;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isDropping;

@property (nonatomic, assign) UIView *view;
@property (nonatomic, strong, readonly) UIView *dragInteractionView;

- (void)dragDropStarted:(DragDrop *)dd;
- (void)dragDropMoved:(DragDrop *)dd;
- (void)dragDropEnded:(DragDrop *)dd;

@end
