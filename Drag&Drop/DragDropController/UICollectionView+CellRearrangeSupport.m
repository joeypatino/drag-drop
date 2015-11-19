//
//  UICollectionView+CellRearrangeSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>
#import "UICollectionView+CellRearrangeSupport.h"

#define CGRectReplaceSize(rect, size)   CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), size.width, size.height)

@interface UICollectionView ()
@property (nonatomic, assign) BOOL isRearrangingCells;
@end

@implementation UICollectionView (CellRearrangeSupport)

- (void)startCellRearrangement:(CGPoint)location {
    DLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.cellRearrangeOrigin == nil)
        self.cellRearrangeOrigin = [self indexPathForItemAtPoint:location];
    
    if (self.cellRearrangeDestination == nil)
        self.cellRearrangeDestination = [self indexPathForItemAtPoint:location];
}

- (void)continueCellRearrangement:(CGPoint)location {
    
    NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];
    if (!indexPathAtDragLocation) return;
    
    NSIndexPath *toIndexPath = indexPathAtDragLocation;
    NSIndexPath *fromIndexPath = self.cellRearrangeDestination;
    
    if ([toIndexPath compare:fromIndexPath] == NSOrderedSame) return;
    
    if (![fromIndexPath compare:toIndexPath] == NSOrderedSame) {
        [self.dataSource collectionView:self
                    moveItemAtIndexPath:fromIndexPath
                            toIndexPath:toIndexPath];
    }
    
    [self makeSpaceForCellFromIndexPath:self.cellRearrangeOrigin
                            toIndexPath:toIndexPath
                               animated:YES
                             completion:nil];
    
    self.cellRearrangeDestination = toIndexPath;
}

- (void)finishCellRearrangement {
    [self resetAfterRearrange];
}

- (void)stopCellRearrangement {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [self removeSpaceForCellAtIndexPath:self.cellRearrangeOrigin animated:YES];
}

- (void)cancelCellRearrangement {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [self makeSpaceForCellFromIndexPath:self.cellRearrangeOrigin
                            toIndexPath:self.cellRearrangeOrigin
                               animated:YES
                             completion:^{
                                 [self.dataSource collectionView:self
                                             moveItemAtIndexPath:self.cellRearrangeDestination
                                                     toIndexPath:self.cellRearrangeOrigin];
                                 
                                 [self resetAfterRearrange];
                             }];
}

#pragma mark -

- (void)makeSpaceForCellFromIndexPath:(NSIndexPath *)fromIndexPath
                          toIndexPath:(NSIndexPath *)toIndexPath
                             animated:(BOOL)animated
                           completion:(dispatch_block_t)completion {
    DLog(@"%s", __PRETTY_FUNCTION__);
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{

        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){
            UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
            
            NSComparisonResult toResult = [indexPath compare:toIndexPath];
            NSComparisonResult fromResult = [indexPath compare:fromIndexPath];
            NSIndexPath *nextIndexPath = indexPath;
            
            if (fromResult == NSOrderedSame) {
                UICollectionViewLayoutAttributes *attributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:toIndexPath];
                visibleCell.frame = CGRectReplaceSize(visibleCell.frame, attributes.size);
                return;
            }
            else if (toResult == NSOrderedAscending) {
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
        if (completion)
            completion();
        self.isRearrangingCells = NO;
    }];
}

- (void)removeSpaceForCellAtIndexPath:(NSIndexPath *)fromIndexPath
                             animated:(BOOL)animated {
    DLog(@"%s", __PRETTY_FUNCTION__);
    
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
        self.isRearrangingCells = NO;
    }];
}


#pragma mark -

- (void)resetAfterRearrange {
    DLog(@"%s", __PRETTY_FUNCTION__);

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

- (void)setIsRearrangingCells:(BOOL)isRearrangingCells {
    objc_setAssociatedObject(self, @selector(isRearrangingCells), [NSNumber numberWithBool:isRearrangingCells], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isRearrangingCells {
    NSNumber *isRearrangingCells = objc_getAssociatedObject(self, @selector(isRearrangingCells));
    return [isRearrangingCells boolValue];
}

@end