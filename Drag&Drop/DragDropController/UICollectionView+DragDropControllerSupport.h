//
//  UICollectionView+DragDropControllerSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DragDropController;
@interface UICollectionView (DragDropControllerSupport)
@property (nonatomic, strong) DragDropController *dragDropController;
@property (nonatomic, assign) BOOL isDroppingCell;
@property (nonatomic, assign) BOOL isUpdatingCells;

- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell;
- (void)disableDragAndDropForCell:(UICollectionViewCell *)cell;

@end
