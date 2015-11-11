//
//  UICollectionView+DragDropSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+DragDropSupport.h"
#import "DragDropController.h"

@interface UICollectionView ()
@property (nonatomic, strong) DragDropController *dragDropController;

@property (nonatomic, assign) BOOL isUpdatingCells;

@property (nonatomic, assign) NSIndexPath *originIndexPath;
@property (nonatomic, assign) NSIndexPath *destinationIndexPath;
@property (nonatomic, strong) NSMutableArray *dragEnabledCells;
@end

@implementation UICollectionView (DragDropSupport)

#pragma mark -

- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (!self.dragDropController) self.dragDropController = [self controller];
    if (!self.dragEnabledCells) self.dragEnabledCells = [NSMutableArray array];

    if (![self.dragEnabledCells containsObject:cell]) {
        [self.dragDropController enableDragActionForView:cell];
        [self.dragEnabledCells addObject:cell];
    }
}

- (void)disableDragAndDropForCell:(UICollectionViewCell *)cell {
    if ([self.dragEnabledCells containsObject:cell]){
        [self.dragDropController disableDragActionForView:cell];
        [self.dragEnabledCells removeObject:cell];
    }
}

#pragma mark -

- (DragDropController *)controller {
    DragDropController *d = [[DragDropController alloc] init];
    d.dropTargetView = self;
    d.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    d.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    
    return d;
}

#pragma mark - DragDropController Delegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragAction *)drag
                  animated:(BOOL)animated {
    
}

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragAction *)drag {
    
    [UIView setAnimationsEnabled:NO];
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
    [UIView setAnimationsEnabled:YES];
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
      didStartDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {

    destination.dropTargetView.layer.borderColor = [UIColor redColor].CGColor;
    destination.dropTargetView.layer.borderWidth = 2.0;

    self.originIndexPath = [self indexPathForItemAtPoint:location];
    self.destinationIndexPath = [self indexPathForItemAtPoint:location];
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    
    NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];
    if (!indexPathAtDragLocation) return;

    
    NSIndexPath *toIndexPath = indexPathAtDragLocation;
    NSIndexPath *fromIndexPath = self.destinationIndexPath
    ? self.destinationIndexPath
    : self.originIndexPath ;
    
    if (!fromIndexPath || [fromIndexPath compare:indexPathAtDragLocation] == NSOrderedSame) return;
    
    if (self.isUpdatingCells) return;
    self.isUpdatingCells = YES;
    self.destinationIndexPath = toIndexPath;
    
    [self.dataSource collectionView:self
                moveItemAtIndexPath:fromIndexPath
                        toIndexPath:toIndexPath];

    [UIView animateWithDuration:.3 animations:^{
        [self cascadeUpdateCellsFrom:self.originIndexPath to:toIndexPath];
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)dragDropController:(DragDropController *)controller
        didEndDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {

    destination.dropTargetView.layer.borderColor = [UIColor clearColor].CGColor;
    destination.dropTargetView.layer.borderWidth = 0.0;

    self.originIndexPath = nil;
    self.destinationIndexPath = nil;
}

#pragma mark - DragDropController Datasource

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination {
    return [self layoutAttributesForItemAtIndexPath:self.destinationIndexPath].frame;
}

#pragma mark -

- (void)cascadeUpdateCellsFrom:(NSIndexPath *)fromIndexPath to:(NSIndexPath *)toIndexPath {
    
    NSArray *visibleCellIndexPaths = [self indexPathsForVisibleItems];
    
    for (NSIndexPath *indexPath in visibleCellIndexPaths) {
        NSComparisonResult toResult = [indexPath compare:toIndexPath];
        NSComparisonResult fromResult = [indexPath compare:fromIndexPath];
        
        UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
        NSIndexPath *nextIndexPath = indexPath;
        
        if ([indexPath compare:fromIndexPath] == NSOrderedSame) {
            
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:toIndexPath];
            CGRect r = visibleCell.frame;
            r.size = attributes.size;
            visibleCell.frame = r;
            continue;
        }
        
        if (toResult == NSOrderedAscending) {
            if (fromResult == NSOrderedDescending) {
                // - 1
                nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row-1 inSection:0];
            }
        }
        else if (toResult == NSOrderedDescending) {
            if (fromResult == NSOrderedAscending) {
                // + 1
                nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row+1 inSection:0];
            }
        }
        else if (toResult == NSOrderedSame) {
            NSComparisonResult toFromResult = [toIndexPath compare:fromIndexPath];
            if (toFromResult == NSOrderedAscending) {
                // + 1
                nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row+1 inSection:0];
            }
            else if (toFromResult == NSOrderedDescending) {
                // - 1
                nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row-1 inSection:0];
            }
        }
        
        visibleCell.frame = [self layoutAttributesForItemAtIndexPath:nextIndexPath].frame;
    }
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


- (void)setDestinationIndexPath:(NSIndexPath *)destinationIndexPath {
    objc_setAssociatedObject(self, @selector(destinationIndexPath), destinationIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)destinationIndexPath {
    return objc_getAssociatedObject(self, @selector(destinationIndexPath));
}


- (void)setOriginIndexPath:(NSIndexPath *)originIndexPath {
    objc_setAssociatedObject(self, @selector(originIndexPath), originIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)originIndexPath {
    return objc_getAssociatedObject(self, @selector(originIndexPath));
}

- (void)setDragEnabledCells:(NSMutableArray *)dragEnabledCells {
    objc_setAssociatedObject(self, @selector(dragEnabledCells), dragEnabledCells, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)dragEnabledCells {
    return objc_getAssociatedObject(self, @selector(dragEnabledCells));
}


@end
