//
//  UICollectionView+DragDropSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/objc-runtime.h>

#import "UICollectionView+DragDropSupport.h"
#import "DragDropController.h"

@interface UICollectionView ()
@property (nonatomic, strong) DragDropController *dragDropController;

@property (nonatomic, assign) BOOL isUpdatingCells;
@property (nonatomic, assign) NSIndexPath *hoverIndexPath;
@property (nonatomic, assign) NSIndexPath *startingIndexPath;

@end

@implementation UICollectionView (DragDropSupport)

#pragma mark -

- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"%@", self.dragDropController);
    if (!self.dragDropController) {
        self.dragDropController = [self controller];
    }
    NSLog(@"%@", self.dragDropController);

    [self.dragDropController enableDragActionForView:cell];

    cell.hidden = (self.hoverIndexPath && [self.hoverIndexPath compare:indexPath] == NSOrderedSame) ? YES : NO;
}

#pragma mark - DragDropController Delegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragAction *)drag
                  animated:(BOOL)animated {
    drag.dragRepresentation.transform = CGAffineTransformMakeScale(1.1, 1.1);
    drag.view.alpha = 0.0;
}

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(DragAction *)drag {
}

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(DragAction *)drag
                  animated:(BOOL)animated {
}

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragAction *)drag {
    drag.dragRepresentation.transform = CGAffineTransformIdentity;
    drag.view.alpha = 1.0;
    
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
      didStartDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    destination.dropTargetView.layer.borderColor = [UIColor redColor].CGColor;
    destination.dropTargetView.layer.borderWidth = 2.0;
    
    self.hoverIndexPath = [self indexPathForItemAtPoint:location];
    self.startingIndexPath = [self indexPathForItemAtPoint:location];
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    
    NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];
    if (!indexPathAtDragLocation) return;
    
    NSIndexPath *toIndexPath = indexPathAtDragLocation;
    
    NSIndexPath *fromIndexPath = self.hoverIndexPath ? self.hoverIndexPath : self.startingIndexPath ;
    if (!fromIndexPath) return;
    
    if ([fromIndexPath compare:indexPathAtDragLocation] == NSOrderedSame) return;
    
    if (self.isUpdatingCells) return;
    self.isUpdatingCells = YES;
    
    self.hoverIndexPath = indexPathAtDragLocation;
    [self performBatchUpdates:^{
        [self.dataSource collectionView:self
                               moveItemAtIndexPath:fromIndexPath
                                       toIndexPath:toIndexPath];
        
        [self deleteItemsAtIndexPaths:@[fromIndexPath]];
        [self insertItemsAtIndexPaths:@[toIndexPath]];
    }
                              completion:^(BOOL finished){
                                  self.isUpdatingCells = NO;
                              }];
    
}

- (void)dragDropController:(DragDropController *)controller
        didEndDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    destination.dropTargetView.layer.borderColor = [UIColor clearColor].CGColor;
    destination.dropTargetView.layer.borderWidth = 0.0;
    
    self.hoverIndexPath = nil;
    self.startingIndexPath = nil;
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination {
}

#pragma mark - DragDropController Datasource

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)view {
    return YES;
}

- (BOOL)dragDropController:(DragDropController *)controller
               canDropView:(UIView *)target
             toDestination:(DragDropController *)destination {
    return YES;
}

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination {
    
    if (!self.hoverIndexPath)
        return view.frame;
    
    return [self cellForItemAtIndexPath:self.hoverIndexPath].frame;
}

- (UIView *)dragDropController:(DragDropController *)controller
     dragRepresentationForView:(UIView *)view {
    
    UIView *dragView = [[UIView alloc] initWithFrame:view.bounds];
    dragView.backgroundColor = [UIColor redColor];
    
    return dragView;
}

#pragma mark -

- (void)setDragDropController:(DragDropController *)dragDropController {
    objc_setAssociatedObject(self, @selector(dragDropController), dragDropController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (DragDropController *)dragDropController {
    return objc_getAssociatedObject(self, @selector(dragDropController));
}


- (void)setIsUpdatingCells:(BOOL)isUpdatingCells {
    objc_setAssociatedObject(self, @selector(isUpdatingCells), [NSNumber numberWithBool:isUpdatingCells], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isUpdatingCells {
    NSNumber *isUpdatingCells = objc_getAssociatedObject(self, @selector(isUpdatingCells));
    return [isUpdatingCells boolValue];
}


- (void)setHoverIndexPath:(NSIndexPath *)hoverIndexPath {
    objc_setAssociatedObject(self, @selector(hoverIndexPath), hoverIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)hoverIndexPath {
    return objc_getAssociatedObject(self, @selector(hoverIndexPath));
}


- (void)setStartingIndexPath:(NSIndexPath *)startingIndexPath {
    objc_setAssociatedObject(self, @selector(startingIndexPath), startingIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)startingIndexPath {
    return objc_getAssociatedObject(self, @selector(startingIndexPath));
}

#pragma mark -

- (DragDropController *)controller {
    DragDropController *d = [[DragDropController alloc] init];
    d.dropTargetView = self;
    d.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    d.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    return d;
}

@end
