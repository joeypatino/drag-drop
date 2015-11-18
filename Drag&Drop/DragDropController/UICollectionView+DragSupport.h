//
//  UICollectionView+DragSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DragDropController;
@interface UICollectionView (DragSupport)

@property (nonatomic, strong) NSIndexPath *cellRearrangeOrigin;
@property (nonatomic, strong) NSIndexPath *cellRearrangeDestination;

- (void)startCellRearrangement:(CGPoint)location;
- (void)continueCellRearrangement:(CGPoint)location;
- (void)endCellRearrangement;
- (void)cancelCellRearrangement;

- (void)resetAfterRearrange;
@end
