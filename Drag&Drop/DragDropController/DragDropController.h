//
//  DragDropController.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DragAction.h"

/*
 * The duration of the animation when the icon is released
 * and moves to its next position.
 */
#define kDropAnimationDuration              .2

/*
 * The duration of the drag pickup animation.
 */
#define kDragDropPickupAnimationDuration    .15

/*
 * The delay in seconds before the drag operation begins.
 * This is used when the view being dragged is contained
 * within a UIScrollView, UITableView, or UICollectionView.
 */
#define kDragPickupBeginDelay               .12

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

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination;

@end


@protocol UICollectionViewDataSource_DropSupport <UICollectionViewDataSource>

- (BOOL)collectionView:(UICollectionView *)sourceCollectionView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath;

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath;
@end


/*
 * DragDropController manages the drag actions of registered views and the drop
 * actions within it's own dropTargetView. It uses a datasource and delegate
 * pattern to allow your code to customize the drag and drop behavious and respond
 * to drag and drop actions.
 *
 */
@interface DragDropController : NSObject
@property (nonatomic, weak) NSObject <DragDropControllerDatasource>  *dragDropDataSource;
@property (nonatomic, weak) NSObject <DragDropControllerDelegate>    *dragDropDelegate;

@property (nonatomic, weak) UIView *dropTargetView;     // This is a drop target for views. If set, this view will be able to recieve dropped views

- (void)enableDragActionForView:(UIView *)view;         // Call this to enable drag actions for the view.
- (void)disableDragActionForView:(UIView *)view;        // Call this to disable drag actions for the view.

@end
