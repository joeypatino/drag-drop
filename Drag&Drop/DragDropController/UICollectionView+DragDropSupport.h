//
//  UICollectionView+DragDropSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (DragDropSupport)
- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end
