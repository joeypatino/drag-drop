//
//  UICollectionView+DropSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol UICollectionViewDataSource_DropSupport <UICollectionViewDataSource>

- (BOOL)collectionView:(UICollectionView *)sourceCollectionView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath;

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath;
@end


@interface UICollectionView (DropSupport)
@property (nonatomic, strong) NSIndexPath *cellSwapOrigin;
@property (nonatomic, strong) NSIndexPath *cellSwapDestination;

- (void)startCellSwapFrom:(UICollectionView *)collectionView atLocation:(CGPoint)location;
- (void)continueCellSwap:(CGPoint)location;
- (void)endCellSwap:(UICollectionView *)collectionView;

- (void)didFinishCellSwapWithDestination:(UICollectionView *)destination;

@end
