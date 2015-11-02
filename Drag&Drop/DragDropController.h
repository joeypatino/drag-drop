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

@class Drag;
@class DragDropController;
@protocol DragDropControllerDelegate
@optional
- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(Drag *)dd
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(Drag *)dd;

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)sourceView
                   AtPoint:(CGPoint)point;

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(Drag *)dd
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(Drag *)dd;

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
               toSuperView:(UIView *)superview __attribute__((deprecated));

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination;

- (void)dragDropController:(DragDropController *)controller
         isDraggingAtPoint:(CGPoint)point;

- (void)dragDropController:(DragDropController *)controller
      didFinishDragAtPoint:(CGPoint)point;

@end

@protocol DragDropControllerDatasource

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)subview;

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination;

//- (CGRect)dragDropController:(DragDropController *)controller
//                frameForView:(UIView *)view
//     animatingToNewSuperView:(UIView *)superview __attribute__((deprecated));
//
//- (CGRect)dragDropController:(DragDropController *)controller
//                frameForView:(UIView *)view
//              inNewSuperView:(UIView *)superview __attribute__((deprecated));

- (BOOL)dragDropController:(DragDropController *)controller
               canDropView:(UIView *)target
             toDestination:(DragDropController *)destination;

@end

@class Drag;
@interface DragDropController : NSObject
@property (nonatomic, weak) NSObject <DragDropControllerDatasource>  *dragDropDataSource;
@property (nonatomic, weak) NSObject <DragDropControllerDelegate>    *dragDropDelegate;
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isDropping;
@property (nonatomic, weak) UIView *view;

// Returns YES if the drag was successfuly started.. Otherwise returns NO.
- (BOOL)dragDropStarted:(Drag *)dd;
- (void)dragDropMoved:(Drag *)dd;
- (void)dragDropEnded:(Drag *)dd;

@end
