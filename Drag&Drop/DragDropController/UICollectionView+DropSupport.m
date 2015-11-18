//
//  UICollectionView+DropSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+DragDropControllerSupport.h"
#import "UICollectionView+DropSupport.h"
#import "UICollectionView+DragSupport.h"

@interface UICollectionView ()
@end

@implementation UICollectionView (DropSupport)


- (void)startCellSwapFrom:(UICollectionView *)collectionView atLocation:(CGPoint)location {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.cellSwapDestination = [self indexPathForItemAtPoint:location];
    
    if (!self.cellSwapDestination)
        self.cellSwapDestination = [self findClosestIndexPathToPoint:location];
    
    self.cellSwapOrigin = self.cellSwapDestination;
    [self moveCellFromSource:collectionView];

    self.layer.borderColor = [UIColor redColor].CGColor;
    self.layer.borderWidth = 2.0;
}

- (void)continueCellSwap:(CGPoint)location {
    
    NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];

    if (!indexPathAtDragLocation)
        indexPathAtDragLocation = [self findClosestIndexPathToPoint:location];

    if (self.isUpdatingCells) return;
    self.isUpdatingCells = YES;

    self.cellSwapDestination = indexPathAtDragLocation;
    
    if (![self.cellSwapOrigin compare:self.cellSwapDestination] == NSOrderedSame) {
        [self.dataSource collectionView:self moveItemAtIndexPath:self.cellSwapOrigin
                            toIndexPath:self.cellSwapDestination];
    }
    
    [self insertSpaceForCellAtIndexPath:self.cellSwapDestination animated:YES];
    
    self.cellSwapOrigin = self.cellSwapDestination;
}

- (void)endCellSwap:(UICollectionView *)collectionView {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (!collectionView.isDroppingCell) {
        [self layoutCollectionViewAnimated:YES];
        [collectionView moveCellFromSource:self];
    }
    
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.layer.borderWidth = 0.0;
}

#pragma mark -

- (void)receivedCellSwapFromSource:(UICollectionView *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [UIView setAnimationsEnabled:NO];
    [self insertSwappedCellAtIndexPath:self.cellSwapDestination];
    [destination deleteSwappedCellAtIndexPath:destination.cellRearrangeDestination];
    [UIView setAnimationsEnabled:YES];
    
    [self resetAfterSwap];
    [self resetAfterRearrange];

    [destination resetAfterSwap];
    [destination resetAfterRearrange];
}

- (void)insertSwappedCellAtIndexPath:(NSIndexPath *)indexPath {
    [self insertItemsAtIndexPaths:@[indexPath]];
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
}

- (void)deleteSwappedCellAtIndexPath:(NSIndexPath *)indexPath {
    [self deleteItemsAtIndexPaths:@[indexPath]];
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
}

#pragma mark -

- (void)resetAfterSwap {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.cellSwapOrigin = nil;
    self.cellSwapDestination = nil;
}

#pragma mark - Cell Rearrangement

- (void)moveCellFromSource:(UICollectionView *)source {

    BOOL canMove = YES;

    NSIndexPath *indexPath = source.cellRearrangeDestination ?
                            source.cellRearrangeDestination : source.cellSwapOrigin;
    
    NSIndexPath *toIndexPath = self.cellSwapDestination ?
                                self.cellSwapDestination : self.cellRearrangeDestination;
    
    NSObject <UICollectionViewDataSource_DropSupport> *dataSource = (NSObject <UICollectionViewDataSource_DropSupport> *)source.dataSource;

    if ([source.delegate respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:toCollectionView:toIndexPath:)]){
        canMove = [dataSource collectionView:source canMoveItemAtIndexPath:indexPath
                            toCollectionView:self toIndexPath:toIndexPath];
    }
    
    if (canMove) {
        if ([dataSource respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toCollectionView:toIndexPath:)]){
            [dataSource collectionView:source moveItemAtIndexPath:indexPath
                      toCollectionView:self toIndexPath:toIndexPath];
        }
    }
}

- (void)insertSpaceForCellAtIndexPath:(NSIndexPath *)toIndexPath animated:(BOOL)animated {

    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){
            UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
            
            NSComparisonResult toResult = [indexPath compare:toIndexPath];
            NSIndexPath *nextIndexPath = indexPath;
            
            if (toResult == NSOrderedAscending) {
                // nothing...
                nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
            }
            else if (toResult == NSOrderedDescending || toResult == NSOrderedSame) {
                // + 1
                nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
            }
            
            visibleCell.frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:nextIndexPath].frame;
        }];
        
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)layoutCollectionViewAnimated:(BOOL)animated {

    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){
            UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
            visibleCell.frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
        }];
        
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

#pragma mark - Helpers

- (NSIndexPath *)findClosestIndexPathToPoint:(CGPoint)touchLocation {
    
    NSArray *collectionViewIndexPaths = [[self indexPathsForVisibleItems] sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *idx1, NSIndexPath *idx2){
        return [idx1 compare:idx2];
    }];
    
    CGFloat distanceToNearestIndexPath = CGFLOAT_MAX;
    BOOL locationIsBelowVisibleCells = YES;
    NSIndexPath *nearestIndexPath = nil;
    
    BOOL (^PointIsBelowFrame)(CGPoint, CGRect) = ^BOOL(CGPoint point, CGRect rect) {
        if (point.y <= CGRectGetMaxY(rect)) return YES;
        return NO;
    };
    
    BOOL (^PointIsToTheRightOfFrame)(CGPoint, CGRect) = ^BOOL(CGPoint point, CGRect rect) {
        if (point.x >= CGRectGetMaxX(rect)) return YES;
        return NO;
    };
    
    for (NSIndexPath *indexPath in collectionViewIndexPaths) {
        UICollectionViewLayoutAttributes *cellLayoutAttributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        CGFloat distanceToCell = [self distanceBetween:touchLocation p2:cellLayoutAttributes.center];
        
        if (PointIsBelowFrame(touchLocation, cellLayoutAttributes.frame)) {
            locationIsBelowVisibleCells = NO;
        }

        if ([collectionViewIndexPaths lastObject] == indexPath &&
            (PointIsToTheRightOfFrame(touchLocation, cellLayoutAttributes.frame))) {
            locationIsBelowVisibleCells = YES;
        }

        if (distanceToCell < distanceToNearestIndexPath) {
            distanceToNearestIndexPath = distanceToCell;
            nearestIndexPath = indexPath;
        }
    }
    
    if (locationIsBelowVisibleCells) {

        NSUInteger section = 0;
        NSUInteger row = 0;

        if (nearestIndexPath) {
            section = nearestIndexPath.section;
            row = [self.dataSource collectionView:self numberOfItemsInSection:section] - 1;
        }

        nearestIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
    }
    
    return nearestIndexPath;
}

- (CGFloat)distanceBetween:(CGPoint)p1 p2:(CGPoint)p2 {
    
    CGFloat x1 = p1.x;
    CGFloat x2 = p2.x;
    
    CGFloat y1 = p1.y;
    CGFloat y2 = p2.y;
    
    double dx = (x2-x1);
    double dy = (y2-y1);
    double dist = sqrt(dx*dx + dy*dy);
    
    return dist;
}

#pragma mark -

- (void)setCellSwapOrigin:(NSIndexPath *)cellSwapOrigin {
    objc_setAssociatedObject(self, @selector(cellSwapOrigin), cellSwapOrigin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)cellSwapOrigin {
    return objc_getAssociatedObject(self, @selector(cellSwapOrigin));
}

- (void)setCellSwapDestination:(NSIndexPath *)cellSwapDestination {
    objc_setAssociatedObject(self, @selector(cellSwapDestination), cellSwapDestination, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)cellSwapDestination {
    return objc_getAssociatedObject(self, @selector(cellSwapDestination));
}


@end
