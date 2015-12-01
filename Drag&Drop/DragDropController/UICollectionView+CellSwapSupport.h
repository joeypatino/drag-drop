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
@required
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath;
@end


@interface UICollectionView (CellSwapSupport)
@property (nonatomic, strong) NSIndexPath *cellSwapOrigin;
@property (nonatomic, strong) NSIndexPath *cellSwapDestination;

- (BOOL)shouldAcceptCellSwapFrom:(UICollectionView *)collectionView;

- (void)startCellSwapFromIndexPath:(NSIndexPath *)fromIndexPath
                  inCollectionView:(UICollectionView *)collectionView
                        toLocation:(CGPoint)location;
- (void)continueCellSwap:(CGPoint)location;
- (void)reverseCellSwapFromIndexPath:(NSIndexPath *)fromIndexPath
                    inCollectionView:(UICollectionView *)collectionView;

- (void)insertCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)layoutCollectionViewAnimated:(BOOL)animated completion:(dispatch_block_t)completion;
@end
