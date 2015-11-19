//
//  UICollectionView+CellSwapSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UICollectionViewDataSource_CellSwapSupport <UICollectionViewDataSource>
- (BOOL)collectionView:(UICollectionView *)sourceCollectionView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath;
@end


@interface UICollectionView (CellSwapSupport)
@property (nonatomic, strong) NSIndexPath *cellSwapOrigin;
@property (nonatomic, strong) NSIndexPath *cellSwapDestination;

- (void)startCellSwapFrom:(UICollectionView *)collectionView atLocation:(CGPoint)location;
- (void)continueCellSwap:(CGPoint)location;
- (void)reverseCellSwapFrom:(UICollectionView *)collectionView;

- (void)insertSwappedCell;
- (void)deleteSwappedCell;

@end
