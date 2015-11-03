//
//  DragDropController.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

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
             willStartDrag:(Drag *)drag
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(Drag *)drag;

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(Drag *)drag
                  animated:(BOOL)animated;

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(Drag *)drag;

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination;


- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                   atPoint:(CGPoint)point;

@end

@protocol DragDropControllerDatasource

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)view;

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination;

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
- (BOOL)startDrag:(Drag *)drag;

- (void)moveDrag:(Drag *)drag;
- (void)endDrag:(Drag *)drag;

@end
