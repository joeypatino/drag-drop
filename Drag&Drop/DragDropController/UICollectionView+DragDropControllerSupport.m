
//  UICollectionView+DragDropControllerSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+DragDropControllerSupport.h"
#import "UICollectionView+CellRearrangeSupport.h"
#import "UICollectionView+CellSwapSupport.h"
#import "NSIndexPath+Additions.h"
#import "DragDropController.h"

@interface UICollectionView ()
@property (nonatomic, assign) BOOL isDragInCollectionView;
@property (nonatomic, assign) BOOL isDroppingCell;
@end

@implementation UICollectionView (DragDropControllerSupport)

#pragma mark -

- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell {
    if (!self.dragDropController) self.dragDropController = [self controller];
    
    [self.dragDropController disableDragActionForView:cell];
    [self.dragDropController enableDragActionForView:cell];
}

- (void)disableDragAndDropForCell:(UICollectionViewCell *)cell {
    [self.dragDropController disableDragActionForView:cell];
}

#pragma mark -

- (UICollectionView *)dragDropCollectionView:(DragDropController *)controller {
    
    UICollectionView *collectionView = nil;

    if ([controller.dropTargetView isKindOfClass:[UICollectionView class]])
        collectionView = (UICollectionView *)controller.dropTargetView;
    
    return collectionView;
}

- (DragDropController *)controller {
    DragDropController *ddController = [[DragDropController alloc] init];
    ddController.dropTargetView = self;
    ddController.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    ddController.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    
    return ddController;
}

#pragma mark -

- (void)startedDraggingInCollectionView:(UICollectionView *)collectionView atPoint:(CGPoint)point {
    self.isDragInCollectionView = YES;

    if ([self isEqual:collectionView])
        return [self startCellRearrangement:point];

    [collectionView startCellSwapFromIndexPath:self.cellRearrangeDestination
                              inCollectionView:self
                                    toLocation:point];

    collectionView.layer.borderColor = [UIColor redColor].CGColor;
    collectionView.layer.borderWidth = 2.0;
}

- (void)isDraggingInCollectionView:(UICollectionView *)collectionView atPoint:(CGPoint)point {
    
    if ([self isEqual:collectionView])
        return [self continueCellRearrangement:point];
    
    [collectionView continueCellSwap:point];
}

- (void)endedDraggingInCollectionView:(UICollectionView *)collectionView atPoint:(CGPoint)point {
    self.isDragInCollectionView = NO;

    if ([self isEqual:collectionView]) {

        if (self.isDroppingCell) [self finishCellRearrangement];
        else [self stopCellRearrangement];
    }
    else {
        
        // when the drag exits the current destination, cancel the swap by
        // reversing any previous swap
        if (!self.isDroppingCell)
            [collectionView reverseCellSwapFromIndexPath:self.cellRearrangeDestination inCollectionView:self];

        collectionView.layer.borderColor = [UIColor clearColor].CGColor;
        collectionView.layer.borderWidth = 0.0;
    }
}

- (BOOL)shouldRearrangeCell:(UICollectionViewCell *)cell {

    // do not rearrange if our datasource disallows it
    if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)])
        return [self.dataSource collectionView:self canMoveItemAtIndexPath:[self indexPathForCell:cell]];
    
    return YES;
}

- (void)didMoveCellToCollectionView:(UICollectionView *)collectionView {
    if ([self isEqual:collectionView]) return;

    // on successful cell transfer, delete the cell from it's
    // final destination in self (the last known location), and
    // then reset after rearrangement..
    [self deleteCellAtIndexPath:self.cellRearrangeDestination];
    [self finishCellRearrangement];
    
    
    // after successful cell transfer in the destination, insert the cell at
    // the final destination (the last known location), and then
    // then reset after the rearrangement..
    [collectionView insertCellAtIndexPath:collectionView.cellSwapDestination];
    [collectionView finishCellRearrangement];
}

#pragma mark - DragDropController Delegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragAction *)drag
                  animated:(BOOL)animated {
    DLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(DragAction *)drag {
    DLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(DragAction *)drag
                  animated:(BOOL)animated {
    DLog(@"%s", __PRETTY_FUNCTION__);
    self.isDroppingCell = YES;

    // if we ended the drag outside of any valid dragDropController,
    // then we should cancel any rearrangements that were
    // previously made.
    if (!self.isDragInCollectionView)
        [self cancelCellRearrangement];
}

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragAction *)drag {
    DLog(@"%s", __PRETTY_FUNCTION__);
    self.isDroppingCell = NO;
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
              dragDidEnter:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    DLog(@"%s", __PRETTY_FUNCTION__);
    
    [self startedDraggingInCollectionView:[self dragDropCollectionView:destination] atPoint:drag.currentLocation];
}

- (void)dragDropController:(DragDropController *)controller
               dragDidMove:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    
    [self isDraggingInCollectionView:[self dragDropCollectionView:destination] atPoint:drag.currentLocation];
}

- (void)dragDropController:(DragDropController *)controller
               dragDidExit:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [self endedDraggingInCollectionView:[self dragDropCollectionView:destination] atPoint:drag.currentLocation];
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination {
    DLog(@"%s", __PRETTY_FUNCTION__);
    
    [self didMoveCellToCollectionView:[self dragDropCollectionView:destination]];
}

#pragma mark - DragDropController Datasource

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination {
    DLog(@"%s", __PRETTY_FUNCTION__);

    UICollectionView *collectionView = nil;
    NSIndexPath *indexPath = nil;
    
    if (![controller isEqual: destination]) {
        collectionView = [self dragDropCollectionView:destination];
        indexPath = [self dragDropCollectionView:destination].cellSwapDestination;
    }
    else {
        collectionView = [self dragDropCollectionView:controller];
        indexPath = self.cellRearrangeDestination;
    }

    return [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
}

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)view {
    return [self shouldRearrangeCell:(UICollectionViewCell *)view];
}

- (BOOL)dragDropController:(DragDropController *)controller
               canDropView:(UIView *)target
             toDestination:(DragDropController *)destination {
    if ([controller isEqual:destination]) return YES;

    BOOL canDrop = [[self dragDropCollectionView:destination] shouldAcceptCellSwapFrom:self];

    if (!canDrop)
        [[self dragDropCollectionView:destination] didNotAcceptCellSwapFrom:self];

    return canDrop;
}

- (void)didNotAcceptCellSwapFrom:(UICollectionView *)source {

    // on failure to transfer a cell to a different destination,
    // relayout the collectionview, and then cancel any cell
    // rearrangements that may have been made..
    [self layoutCollectionViewAnimated:YES completion:^{
        [self cancelCellRearrangement];
        [source cancelCellRearrangement];
    }];
}

#pragma mark -

- (void)setDragDropController:(DragDropController *)dragDropController {
    objc_setAssociatedObject(self, @selector(dragDropController), dragDropController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (DragDropController *)dragDropController {
    return objc_getAssociatedObject(self, @selector(dragDropController));
}

- (void)setIsDroppingCell:(BOOL)isDroppingCell {
    objc_setAssociatedObject(self, @selector(isDroppingCell), [NSNumber numberWithBool:isDroppingCell], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDroppingCell {
    NSNumber *isDroppingCell = objc_getAssociatedObject(self, @selector(isDroppingCell));
    return [isDroppingCell boolValue];
}

- (void)setIsDragInCollectionView:(BOOL)isDragInCollectionView {
    objc_setAssociatedObject(self, @selector(isDragInCollectionView), [NSNumber numberWithBool:isDragInCollectionView], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDragInCollectionView {
    NSNumber *isDragInCollectionView = objc_getAssociatedObject(self, @selector(isDragInCollectionView));
    return [isDragInCollectionView boolValue];
}


@end
