//
//  UICollectionView+DropSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/15/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+InteractiveMovementSupport.h"
#import "UICollectionView+DropSupport.h"
#import "DragDropController.h"

@interface UICollectionView ()
@property (nonatomic, strong) DragDropController *dropController;

@property (nonatomic, assign) NSIndexPath *dropDestinationIndexPath;

@end

@implementation UICollectionView (DropSupport)

- (void)enableDropSupport {
    if (!self.dropController) self.dropController = [self controller];
}

- (DragDropController *)controller {
    DragDropController *d = [[DragDropController alloc] init];
    d.dropTargetView = self;
    d.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    d.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    
    return d;
}

- (void)dragDropController:(DragDropController *)controller
    didBeginDragAtLocation:(CGPoint)location
             inDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    UICollectionView *collectionView = nil;
    
    if ([self isCollectionView:destination.dropTargetView outCollectionView:&collectionView]) {
        self.dropDestinationIndexPath = [collectionView indexPathForItemAtPoint:location];
        
        collectionView.layer.borderColor = [UIColor redColor].CGColor;
        collectionView.layer.borderWidth = 2.0;
    }
}

- (void)dragDropController:(DragDropController *)controller
     didMoveDragAtLocation:(CGPoint)location
             inDestination:(DragDropController *)destination {

    UICollectionView *collectionView = nil;
    
    if ([self isCollectionView:destination.dropTargetView outCollectionView:&collectionView]) {

        NSIndexPath *indexPathAtDragLocation = [collectionView indexPathForItemAtPoint:location];
        
        if (!indexPathAtDragLocation) return;
        if (self.isUpdatingCells) return;
        
        self.dropDestinationIndexPath = indexPathAtDragLocation;
        
        [self insertSpaceForCellAtIndexPath:self.dropDestinationIndexPath
                           inCollectionView:collectionView
                                   animated:YES];

    }
}

- (void)dragDropController:(DragDropController *)controller
      didEndDragAtLocation:(CGPoint)location
             inDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    UICollectionView *collectionView = nil;
    if ([self isCollectionView:destination.dropTargetView outCollectionView:&collectionView]) {
        [self layoutCollectionView:collectionView
                          animated:YES];
        
        collectionView.layer.borderColor = [UIColor clearColor].CGColor;
        collectionView.layer.borderWidth = 0.0;
    }
}

- (CGRect)dragDropController:(DragDropController *)controller
                frameForCell:(UICollectionViewCell *)cell
            inCollectionView:(UICollectionView *)collectionView {

    return [collectionView layoutAttributesForItemAtIndexPath:self.dropDestinationIndexPath].frame;
}

#pragma mark -

- (void)setDropController:(DragDropController *)dropController {
    objc_setAssociatedObject(self, @selector(dropController), dropController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (DragDropController *)dropController {
    return objc_getAssociatedObject(self, @selector(dropController));
}

- (void)setDropDestinationIndexPath:(NSIndexPath *)dropDestinationIndexPath {
    objc_setAssociatedObject(self, @selector(dropDestinationIndexPath), dropDestinationIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)dropDestinationIndexPath {
    return objc_getAssociatedObject(self, @selector(dropDestinationIndexPath));
}


@end
