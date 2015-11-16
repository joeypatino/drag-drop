//
//  UICollectionView+InteractiveMovementSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+InteractiveMovementSupport.h"
#import "UICollectionView+DropSupport.h"
#import "DragDropController.h"

@interface UICollectionView ()
@property (nonatomic, strong) DragDropController *dragDropController;

@property (nonatomic, assign) NSIndexPath *originIndexPath;
@property (nonatomic, assign) NSIndexPath *destinationIndexPath;
@property (nonatomic, strong) NSMutableArray *dragEnabledCells;

@property (nonatomic, assign) BOOL isDroppingCell;
@end

@implementation UICollectionView (InteractiveMovementSupport)

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

- (BOOL)isCollectionView:(UIView *)sourceView
       outCollectionView:(inout UICollectionView **)collectionView {
    
    if ([sourceView isKindOfClass:[UICollectionView class]]){
        *collectionView = (UICollectionView *)sourceView;
        return YES;
    }
    
    return NO;
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(DragAction *)drag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(DragAction *)drag
                  animated:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.isDroppingCell = YES;
}

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragAction *)drag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.originIndexPath = nil;
    self.destinationIndexPath = nil;
    self.isDroppingCell = NO;
    
    [UIView setAnimationsEnabled:NO];
    [self reloadItemsAtIndexPaths:[self indexPathsForVisibleItems]];
    [UIView setAnimationsEnabled:YES];
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
      didStartDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (![controller isEqual: destination]) {
        return [self dragDropController:controller
                 didBeginDragAtLocation:location
                          inDestination:destination];
    }

    if (self.originIndexPath == nil)
        self.originIndexPath = [self indexPathForItemAtPoint:location];

    if (self.destinationIndexPath == nil)
        self.destinationIndexPath = [self indexPathForItemAtPoint:location];
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {

    if (![controller isEqual: destination]) {
        return [self dragDropController:controller
                  didMoveDragAtLocation:location
                          inDestination:destination];
    }

    NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];
    if (!indexPathAtDragLocation) return;

    
    NSIndexPath *toIndexPath = indexPathAtDragLocation;
    NSIndexPath *fromIndexPath = self.destinationIndexPath
    ? self.destinationIndexPath
    : self.originIndexPath ;
    
    if (!fromIndexPath ||
        [fromIndexPath compare:indexPathAtDragLocation] == NSOrderedSame) return;
    
//    if (self.isUpdatingCells) return;
    self.destinationIndexPath = toIndexPath;

    [self.dataSource collectionView:self
                moveItemAtIndexPath:fromIndexPath
                        toIndexPath:toIndexPath];

    [self makeSpaceForCellFromIndexPath:self.originIndexPath
                            toIndexPath:toIndexPath
                               animated:YES];
}

- (void)dragDropController:(DragDropController *)controller
        didEndDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {

    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (![controller isEqual: destination]) {
        return [self dragDropController:controller
                   didEndDragAtLocation:location
                          inDestination:destination];
    }

    if (self.isDroppingCell) {
        self.originIndexPath = nil;
    }
    else {
        [self removeSpaceForCellAtIndexPath:self.originIndexPath animated:YES];
    }

    self.destinationIndexPath = nil;
}

#pragma mark - DragDropController Datasource

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination {
    
    UICollectionView *collectionView = self;

    if ([self isCollectionView:destination.dropTargetView outCollectionView:&collectionView] &&
        ![controller isEqual: destination]) {

        return [self dragDropController:controller
                           frameForCell:(UICollectionViewCell *)view
                       inCollectionView:collectionView];
    }

    return [self layoutAttributesForItemAtIndexPath:self.destinationIndexPath].frame;
}

#pragma mark -

- (void)applyAttributesToCell:(UICollectionViewCell *)cell inCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewLayoutAttributes *attributes = nil;
    CGRect frame = cell.frame;
    @try {
        attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
        frame = attributes.frame;
    }
    @catch (NSException *exception) {
        NSLog(@"exception: %@", exception);
    }
    @finally {
        cell.frame = frame;
    }
}

- (void)insertSpaceForCellAtIndexPath:(NSIndexPath *)toIndexPath
                     inCollectionView:(UICollectionView *)collectionView
                             animated:(BOOL)animated {
//    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.isUpdatingCells = YES;
    NSArray *visibleCellIndexPaths = [collectionView indexPathsForVisibleItems];
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{

        for (int i = 0; i < [visibleCellIndexPaths count]; i++) {
            NSIndexPath *indexPath = visibleCellIndexPaths[i];
            
            NSComparisonResult toResult = [indexPath compare:toIndexPath];
            UICollectionViewCell *visibleCell = [collectionView cellForItemAtIndexPath:indexPath];
            NSIndexPath *nextIndexPath = [indexPath copy];
            
            if (toResult == NSOrderedAscending) {
                // nothing...
            }
            else if (toResult == NSOrderedDescending || toResult == NSOrderedSame) {
                // + 1
                nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row+1 inSection:nextIndexPath.section];
            }

            [self applyAttributesToCell:visibleCell inCollectionView:collectionView atIndexPath:nextIndexPath];

        }
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)removeSpaceForCellAtIndexPath:(NSIndexPath *)fromIndexPath
                             animated:(BOOL)animated {
   NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.isUpdatingCells = YES;
    NSArray *visibleCellIndexPaths = [self indexPathsForVisibleItems];
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        for (int i = 0; i < [visibleCellIndexPaths count]; i++) {
            NSIndexPath *indexPath = visibleCellIndexPaths[i];
            
            // do not adjust the cell that is being moved..
            if ([indexPath compare:fromIndexPath] == NSOrderedSame) continue;
            
            UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
            NSIndexPath *nextIndexPath = [indexPath copy];

            // if this cell is after/below our cell being moved, then move the cell "up"
            // one indexpath so that the "gap" is closed..
            if ([indexPath compare:fromIndexPath] == NSOrderedDescending) {
                nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1
                                                   inSection:indexPath.section];
            }
            
            [self applyAttributesToCell:visibleCell inCollectionView:self atIndexPath:nextIndexPath];
        }
        
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)layoutCollectionView:(UICollectionView *)collectionView
                    animated:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.isUpdatingCells = YES;
    NSArray *visibleCellIndexPaths = [collectionView indexPathsForVisibleItems];
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        for (int i = 0; i < [visibleCellIndexPaths count]; i++) {
            NSIndexPath *indexPath = visibleCellIndexPaths[i];

            UICollectionViewCell *visibleCell = [collectionView cellForItemAtIndexPath:indexPath];

            [self applyAttributesToCell:visibleCell inCollectionView:collectionView atIndexPath:indexPath];
        }

    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)makeSpaceForCellFromIndexPath:(NSIndexPath *)fromIndexPath
                          toIndexPath:(NSIndexPath *)toIndexPath
                             animated:(BOOL)animated {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.isUpdatingCells = YES;
    NSArray *visibleCellIndexPaths = [self indexPathsForVisibleItems];
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{

        for (int i = 0; i < [visibleCellIndexPaths count]; i++) {
            NSIndexPath *indexPath = visibleCellIndexPaths[i];
            
            NSComparisonResult toResult = [indexPath compare:toIndexPath];
            NSComparisonResult fromResult = [indexPath compare:fromIndexPath];
            
            UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
            NSIndexPath *nextIndexPath = [indexPath copy];
            
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
                    nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row-1 inSection:nextIndexPath.section];
                }
            }
            else if (toResult == NSOrderedDescending) {
                if (fromResult == NSOrderedAscending) {
                    // + 1
                    nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row+1 inSection:nextIndexPath.section];
                }
            }
            else if (toResult == NSOrderedSame) {
                NSComparisonResult toFromResult = [toIndexPath compare:fromIndexPath];
                if (toFromResult == NSOrderedAscending) {
                    // + 1
                    nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row+1 inSection:nextIndexPath.section];
                }
                else if (toFromResult == NSOrderedDescending) {
                    // - 1
                    nextIndexPath = [NSIndexPath indexPathForRow:nextIndexPath.row-1 inSection:nextIndexPath.section];
                }
            }
            
            [self applyAttributesToCell:visibleCell inCollectionView:self atIndexPath:nextIndexPath];
        }
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
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

- (void)setIsDroppingCell:(BOOL)isDroppingCell {
    objc_setAssociatedObject(self, @selector(isDroppingCell), [NSNumber numberWithBool:isDroppingCell], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isDroppingCell {
    NSNumber *isDroppingCell = objc_getAssociatedObject(self, @selector(isDroppingCell));
    return [isDroppingCell boolValue];
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
