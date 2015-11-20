//
//  UICollectionView+CellRearrangeSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+CellRearrangeSupport.h"
#import "NSIndexPath+Additions.h"

#define CGRectReplaceSize(rect, size)   CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), size.width, size.height)

@interface UICollectionView ()
@end

@implementation UICollectionView (CellRearrangeSupport)

- (void)startCellRearrangement:(CGPoint)location {
    DLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.cellRearrangeOrigin == nil)
        self.cellRearrangeOrigin = [self indexPathForItemAtPoint:location];
    
    if (self.cellRearrangeDestination == nil)
        self.cellRearrangeDestination = [self indexPathForItemAtPoint:location];
    
    [self createVacancyForMovementFromIndexPath:self.cellRearrangeOrigin
                                    toIndexPath:self.cellRearrangeDestination
                                       animated:YES completion:nil];
}

- (void)continueCellRearrangement:(CGPoint)location {
    
    NSIndexPath *toIndexPath = [self indexPathForItemAtPoint:location];
    if (!toIndexPath) return;

    if (![self.cellRearrangeDestination isIndexPath:toIndexPath]) {

        if ([self.dataSource respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toIndexPath:)])
            [self.dataSource collectionView:self moveItemAtIndexPath:self.cellRearrangeDestination toIndexPath:toIndexPath];

        [self createVacancyForMovementFromIndexPath:self.cellRearrangeOrigin
                                        toIndexPath:toIndexPath
                                           animated:YES completion:nil];
    }
    
    self.cellRearrangeDestination = toIndexPath;
}

- (void)stopCellRearrangement {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [self removeVacancyAtIndexPath:self.cellRearrangeOrigin animated:YES];
}

- (void)finishCellRearrangement {
    DLog(@"%s", __PRETTY_FUNCTION__);
    
    BOOL canMove = YES;
     if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)])
         canMove = [self.dataSource collectionView:self canMoveItemAtIndexPath:self.cellRearrangeDestination];

    if (canMove) [self resetAfterRearrange];
}

- (void)cancelCellRearrangement {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [self createVacancyForMovementFromIndexPath:self.cellRearrangeOrigin
                                    toIndexPath:self.cellRearrangeOrigin
                                       animated:YES
                                     completion:^{

                                         if ([self.dataSource respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toIndexPath:)])
                                             [self.dataSource collectionView:self moveItemAtIndexPath:self.cellRearrangeDestination toIndexPath:self.cellRearrangeOrigin];

                                         [self resetAfterRearrange];
                                     }];
}

#pragma mark -

- (void)createVacancyForMovementFromIndexPath:(NSIndexPath *)fromIndexPath
                                  toIndexPath:(NSIndexPath *)toIndexPath
                                     animated:(BOOL)animated
                                   completion:(dispatch_block_t)completion {
    
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){

            CGRect frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
            UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
            
            if ([indexPath isIndexPath:fromIndexPath]) {
                CGSize size = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:toIndexPath].size;
                frame = CGRectReplaceSize(cell.frame, size);
            }
            else if ([indexPath isBetweenIndexPath:fromIndexPath andIndexPath:toIndexPath]) {
                frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:[indexPath indexPathByDecrementingRow]].frame;
            }
            else if ([indexPath isBetweenIndexPath:toIndexPath andIndexPath:fromIndexPath]) {
                frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:[indexPath indexPathByIncrementingRow]].frame;
            }
            else if ([indexPath isIndexPath:toIndexPath]) {
                if ([toIndexPath isBeforeIndexPath:fromIndexPath]) {
                    frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:[indexPath indexPathByIncrementingRow]].frame;
                }
                else if ([toIndexPath isAfterIndexPath:fromIndexPath]) {
                    frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:[indexPath indexPathByDecrementingRow]].frame;
                }
            }

            cell.frame = frame;
        }];
        
    } completion:^(BOOL finsihed){
        if (completion)
            completion();
    }];
}

- (void)removeVacancyAtIndexPath:(NSIndexPath *)fromIndexPath
                        animated:(BOOL)animated {
    DLog(@"%s", __PRETTY_FUNCTION__);
    
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){

            // do not adjust the cell that is being moved..
            if ([indexPath isIndexPath:fromIndexPath]) return;
            
            CGRect frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;

            // if this cell is after/below our cell being moved, then move the cell "up"
            // one indexpath so that the "gap" is closed..
            if ([indexPath isAfterIndexPath:fromIndexPath])
                frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:[indexPath indexPathByDecrementingRow]].frame;

            [self cellForItemAtIndexPath:indexPath].frame = frame;
        }];
        
    } completion:NULL];
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

@end