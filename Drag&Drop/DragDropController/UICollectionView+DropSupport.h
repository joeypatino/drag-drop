//
//  UICollectionView+DropSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/15/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DragDropController;
@interface UICollectionView (DropSupport)

- (void)enableDropSupport;

- (void)dragDropController:(DragDropController *)controller
    didBeginDragAtLocation:(CGPoint)location inDestination:(DragDropController *)destination;

- (void)dragDropController:(DragDropController *)controller
     didMoveDragAtLocation:(CGPoint)location inDestination:(DragDropController *)destination;

- (void)dragDropController:(DragDropController *)controller
      didEndDragAtLocation:(CGPoint)location inDestination:(DragDropController *)destination;

- (CGRect)dragDropController:(DragDropController *)controller
                frameForCell:(UICollectionViewCell *)cell
               inCollectionView:(UICollectionView *)collectionView;

@end
