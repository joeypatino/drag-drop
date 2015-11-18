
//  UICollectionView+DragDropControllerSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+DragDropControllerSupport.h"
#import "UICollectionView+DragSupport.h"
#import "UICollectionView+DropSupport.h"
#import "DragDropController.h"

@interface UICollectionView ()
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
    DragDropController *d = [[DragDropController alloc] init];
    d.dropTargetView = self;
    d.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    d.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    
    return d;
}

#pragma mark - DragDropController Delegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragAction *)drag
                  animated:(BOOL)animated {
}

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(DragAction *)drag {
}

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(DragAction *)drag
                  animated:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.isDroppingCell = YES;
}

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragAction *)drag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.isDroppingCell = NO;
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
              dragDidEnter:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (![controller isEqual:destination]) {
        [[self dragDropCollectionView:destination] startCellSwapFrom:[self dragDropCollectionView:controller] atLocation:drag.currentLocation];
    }
    else {
        
        [self startCellRearrangement:drag.currentLocation];
    }
}

- (void)dragDropController:(DragDropController *)controller
               dragDidMove:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    
    if (![controller isEqual:destination]) {
        [[self dragDropCollectionView:destination] continueCellSwap:drag.currentLocation];
    }
    else {
        [self continueCellRearrangement:drag.currentLocation];
    }
}

- (void)dragDropController:(DragDropController *)controller
               dragDidExit:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (![controller isEqual:destination]) {
        [[self dragDropCollectionView:destination] endCellSwap:[self dragDropCollectionView:controller]];
    }
    else {
        [self endCellRearrangement];
    }
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (![controller isEqual: destination]) {
        [[self dragDropCollectionView:destination] receivedCellSwapFromSource:[self dragDropCollectionView:controller]];
    }
}

#pragma mark - DragDropController Datasource

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);

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

#pragma mark -

- (void)setDragDropController:(DragDropController *)dragDropController {
    objc_setAssociatedObject(self, @selector(dragDropController), dragDropController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (DragDropController *)dragDropController {
    return objc_getAssociatedObject(self, @selector(dragDropController));
}


- (void)setIsUpdatingCells:(BOOL)isUpdatingCells {
    objc_setAssociatedObject(self, @selector(isUpdatingCells), [NSNumber numberWithBool:isUpdatingCells], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isUpdatingCells {
    NSNumber *isUpdatingCells = objc_getAssociatedObject(self, @selector(isUpdatingCells));
    return [isUpdatingCells boolValue];
}

- (void)setIsDroppingCell:(BOOL)isDroppingCell {
    objc_setAssociatedObject(self, @selector(isDroppingCell), [NSNumber numberWithBool:isDroppingCell], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDroppingCell {
    NSNumber *isDroppingCell = objc_getAssociatedObject(self, @selector(isDroppingCell));
    return [isDroppingCell boolValue];
}

@end
