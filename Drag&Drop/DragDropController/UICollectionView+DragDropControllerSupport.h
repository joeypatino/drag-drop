//
//  UICollectionView+DragDropControllerSupport.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICollectionView+DragSupport.h"
#import "UICollectionView+DropSupport.h"

@interface UICollectionView (DragDropControllerSupport)
@property (nonatomic, strong) NSIndexPath *originIndexPath;
@property (nonatomic, strong) NSIndexPath *destinationIndexPath;
@property (nonatomic, strong) NSIndexPath *dropDestinationIndexPath;
@property (nonatomic, strong) NSString *name;

- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell;
- (void)disableDragAndDropForCell:(UICollectionViewCell *)cell;

@end
