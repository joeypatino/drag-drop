//
//  UICollectionView+CellSwapSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+CellSwapSupport.h"
#import "NSIndexPath+Additions.h"

@interface UICollectionView ()
@end

@implementation UICollectionView (CellSwapSupport)

- (void)startCellSwapFromIndexPath:(NSIndexPath *)fromIndexPath
                  inCollectionView:(UICollectionView *)collectionView
                        toLocation:(CGPoint)location {
    DLog(@"%s", __PRETTY_FUNCTION__);

    self.cellSwapDestination = [self indexPathAtLocation:location];
    self.cellSwapOrigin = self.cellSwapDestination;

    if ([collectionView canMoveIndexPath:fromIndexPath to:self.cellSwapDestination withDestination:self]) {
        [collectionView moveIndexPath:fromIndexPath to:self.cellSwapDestination withDestination:self];

        [self insertVacancyAtIndexPath:self.cellSwapDestination animated:YES];
    }
    else {
        [self resetAfterSwap];
    }
}

- (void)continueCellSwap:(CGPoint)location {
    if (!self.cellSwapDestination && !self.cellSwapOrigin) return;
    
    self.cellSwapDestination = [self indexPathAtLocation:location];

    if (![self.cellSwapOrigin isIndexPath:self.cellSwapDestination]) {

        BOOL canMove = YES;
        if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)])
            canMove = [self.dataSource collectionView:self canMoveItemAtIndexPath:self.cellSwapOrigin];
        
        if (canMove && [self.dataSource respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toIndexPath:)])
            [self.dataSource collectionView:self moveItemAtIndexPath:self.cellSwapOrigin toIndexPath:self.cellSwapDestination];

        [self insertVacancyAtIndexPath:self.cellSwapDestination animated:YES];
    }

    self.cellSwapOrigin = self.cellSwapDestination;
}


- (void)reverseCellSwapFromIndexPath:(NSIndexPath *)fromIndexPath inCollectionView:(UICollectionView *)collectionView {
    DLog(@"%s", __PRETTY_FUNCTION__);
    if (!self.cellSwapDestination && !self.cellSwapOrigin) return;

    [self layoutCollectionViewAnimated:YES completion:nil];

    if ([self canMoveIndexPath:self.cellSwapOrigin to:fromIndexPath withDestination:collectionView]) {
        [self moveIndexPath:self.cellSwapOrigin to:fromIndexPath withDestination:collectionView];
    }
}

#pragma mark -

- (void)insertCellAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [UIView setAnimationsEnabled:NO];
    [self insertItemsAtIndexPaths:@[indexPath]];
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
    [UIView setAnimationsEnabled:YES];
    
    [self resetAfterSwap];
}

- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath {
    [UIView setAnimationsEnabled:NO];
    [self deleteItemsAtIndexPaths:@[indexPath]];
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
    [UIView setAnimationsEnabled:YES];
}

#pragma mark -

- (void)resetAfterSwap {
    DLog(@"%s", __PRETTY_FUNCTION__);

    self.cellSwapOrigin = nil;
    self.cellSwapDestination = nil;
}

#pragma mark - Cell Rearrangement

- (BOOL)shouldAcceptCellSwapFrom:(UICollectionView *)source {
    DLog(@"%s", __PRETTY_FUNCTION__);
    return (self.cellSwapOrigin && self.cellSwapDestination);
}

// Future support for selective cell swaps...
- (BOOL)canMoveIndexPath:(NSIndexPath *)fromIndexPath to:(NSIndexPath *)toIndexPath withDestination:(UICollectionView *)destination {
    
    NSObject <UICollectionViewDataSource_CellSwapSupport> *dataSource = (NSObject <UICollectionViewDataSource_CellSwapSupport> *)destination.dataSource;
    
    if ([dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:toCollectionView:toIndexPath:)])
        return [dataSource collectionView:self canMoveItemAtIndexPath:fromIndexPath toCollectionView:destination toIndexPath:toIndexPath];

    return YES;
}

- (void)moveIndexPath:(NSIndexPath *)fromIndexPath to:(NSIndexPath *)toIndexPath withDestination:(UICollectionView *)destination {

    NSObject <UICollectionViewDataSource_CellSwapSupport> *dataSource = (NSObject <UICollectionViewDataSource_CellSwapSupport> *)self.dataSource;
    
    if ([dataSource respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toCollectionView:toIndexPath:)])
        [dataSource collectionView:self moveItemAtIndexPath:fromIndexPath toCollectionView:destination toIndexPath:toIndexPath];
}

- (void)insertVacancyAtIndexPath:(NSIndexPath *)toIndexPath animated:(BOOL)animated {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){

            CGRect frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;

            if ([indexPath isAfterIndexPath:toIndexPath] || [indexPath isIndexPath:toIndexPath])
                frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:[indexPath indexPathByIncrementingRow]].frame;

            [self cellForItemAtIndexPath:indexPath].frame = frame;
        }];
        
    } completion:NULL];
}

- (void)layoutCollectionViewAnimated:(BOOL)animated completion:(dispatch_block_t)completion {
    DLog(@"%s", __PRETTY_FUNCTION__);

    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [[self indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop){
            CGRect frame = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
            [self cellForItemAtIndexPath:indexPath].frame = frame;
        }];
        
    } completion:^(BOOL finished){
        if (completion)
            completion();
    }];
}

#pragma mark - Helpers

- (NSIndexPath *)indexPathAtLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:location];
    if (!indexPath) indexPath = [self findClosestIndexPathToPoint:location];
    return indexPath;
}

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
