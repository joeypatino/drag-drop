//
//  UICollectionView+DragSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+DragSupport.h"
#import "UICollectionView+DragDropControllerSupport.h"

#define CGRectReplaceSize(rect, size)   CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), size.width, size.height)

@implementation UICollectionView (DragSupport)

- (void)startCellRearrangement:(CGPoint)location {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.cellRearrangeOrigin == nil)
        self.cellRearrangeOrigin = [self indexPathForItemAtPoint:location];
    
    if (self.cellRearrangeDestination == nil)
        self.cellRearrangeDestination = [self indexPathForItemAtPoint:location];
}

- (void)continueCellRearrangement:(CGPoint)location {
    
    NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];
    if (!indexPathAtDragLocation) return;
    
    NSIndexPath *toIndexPath = indexPathAtDragLocation;
    NSIndexPath *fromIndexPath = self.cellRearrangeDestination
    ? self.cellRearrangeDestination
    : self.cellRearrangeOrigin ;
    
    if (!fromIndexPath ||
        [fromIndexPath compare:indexPathAtDragLocation] == NSOrderedSame) return;
    
    if (self.isUpdatingCells) return;
    self.isUpdatingCells = YES;

    self.cellRearrangeDestination = toIndexPath;

    [self.dataSource collectionView:self
                moveItemAtIndexPath:fromIndexPath
                        toIndexPath:toIndexPath];

    [self makeSpaceForCellFromIndexPath:self.cellRearrangeOrigin
                            toIndexPath:toIndexPath
                               animated:YES];}

- (void)endCellRearrangement {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.isDroppingCell) {
        [self resetAfterRearrange];
    }
    else {
        [self removeSpaceForCellAtIndexPath:self.cellRearrangeOrigin animated:YES];
    }
}

- (void)makeSpaceForCellFromIndexPath:(NSIndexPath *)fromIndexPath
                          toIndexPath:(NSIndexPath *)toIndexPath
                             animated:(BOOL)animated {

    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{

        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){
            UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
            
            NSComparisonResult toResult = [indexPath compare:toIndexPath];
            NSComparisonResult fromResult = [indexPath compare:fromIndexPath];
            NSIndexPath *nextIndexPath = indexPath;
            
            if ([indexPath compare:fromIndexPath] == NSOrderedSame) {
                
                UICollectionViewLayoutAttributes *attributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:toIndexPath];
                visibleCell.frame = CGRectReplaceSize(visibleCell.frame, attributes.size);
                return;
            }
            
            if (toResult == NSOrderedAscending) {
                if (fromResult == NSOrderedDescending) {
                    // - 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
                }
            }
            else if (toResult == NSOrderedDescending) {
                if (fromResult == NSOrderedAscending) {
                    // + 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
                }
            }
            else if (toResult == NSOrderedSame) {
                NSComparisonResult toFromResult = [toIndexPath compare:fromIndexPath];
                if (toFromResult == NSOrderedAscending) {
                    // + 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
                }
                else if (toFromResult == NSOrderedDescending) {
                    // - 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
                }
            }
            visibleCell.frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:nextIndexPath].frame;
        }];
        
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)removeSpaceForCellAtIndexPath:(NSIndexPath *)fromIndexPath
                             animated:(BOOL)animated {

    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){
            UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
            // do not adjust the cell that is being moved..
            if ([indexPath compare:fromIndexPath] == NSOrderedSame) return;
            
            NSIndexPath *nextIndexPath = indexPath;
            
            // if this cell is after/below our cell being moved, then move the cell "up"
            // one indexpath so that the "gap" is closed..
            if ([indexPath compare:fromIndexPath] == NSOrderedDescending) {
                nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1
                                                   inSection:indexPath.section];
            }
            visibleCell.frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:nextIndexPath].frame;
        }];
        
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}


#pragma mark -

- (void)resetAfterRearrange {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.cellRearrangeOrigin = nil;
    self.cellRearrangeDestination = nil;

    [UIView setAnimationsEnabled:NO];
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
    [UIView setAnimationsEnabled:YES];
}

#pragma mark -

- (void)setCellRearrangeDestination:(NSIndexPath *)cellRearrangeDestination {
    objc_setAssociatedObject(self, @selector(cellRearrangeDestination), cellRearrangeDestination, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)cellRearrangeDestination {
    return objc_getAssociatedObject(self, @selector(cellRearrangeDestination));
}

- (void)setCellRearrangeOrigin:(NSIndexPath *)cellRearrangeOrigin {
    objc_setAssociatedObject(self, @selector(cellRearrangeOrigin), cellRearrangeOrigin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)cellRearrangeOrigin {
    return objc_getAssociatedObject(self, @selector(cellRearrangeOrigin));
}

@end
