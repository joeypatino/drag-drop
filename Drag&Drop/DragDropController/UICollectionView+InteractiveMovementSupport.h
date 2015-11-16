//
//  UICollectionView+InteractiveMovementSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (InteractiveMovementSupport)
@property (nonatomic, assign) BOOL isUpdatingCells;;

- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell
                     atIndexPath:(NSIndexPath *)indexPath;
- (void)disableDragAndDropForCell:(UICollectionViewCell *)cell;


- (BOOL)isCollectionView:(UIView *)sourceView
       outCollectionView:(inout UICollectionView **)collectionView;

- (void)insertSpaceForCellAtIndexPath:(NSIndexPath *)toIndexPath
                     inCollectionView:(UICollectionView *)collectionView
                             animated:(BOOL)animated;
- (void)removeSpaceForCellAtIndexPath:(NSIndexPath *)fromIndexPath
                             animated:(BOOL)animated;
- (void)makeSpaceForCellFromIndexPath:(NSIndexPath *)fromIndexPath
                          toIndexPath:(NSIndexPath *)toIndexPath
                             animated:(BOOL)animated;
- (void)layoutCollectionView:(UICollectionView *)collectionView
                    animated:(BOOL)animated;
@end
