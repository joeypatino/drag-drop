//
//  UICollectionView+DragDropControllerSupport.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <objc/runtime.h>

#import "UICollectionView+DragDropControllerSupport.h"
#import "DragDropController.h"

@interface UICollectionView ()
@property (nonatomic, strong) DragDropController *dragDropController;


@property (nonatomic, strong) NSMutableArray *dragEnabledCells;

@property (nonatomic, assign) BOOL isUpdatingCells;
@property (nonatomic, assign) BOOL isDroppingCell;

@end

@implementation UICollectionView (InteractiveMovementSupport)

#pragma mark -

- (void)enableDragAndDropForCell:(UICollectionViewCell *)cell {
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

- (UICollectionView *)dragDropCollectionView:(DragDropController *)controller {
    
    UICollectionView *collectionView = nil;
    if ([self isCollectionView:controller.dropTargetView outCollectionView:&collectionView]) return collectionView;
    
    return nil;
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
}

#pragma mark -

- (void)moveCellFromSource:(DragDropController *)source {

    BOOL canMove = YES;
    UICollectionView *sourceCollectionView = [self dragDropCollectionView:source];

    if ([(NSObject <UICollectionViewDataSource_DropSupport> *)sourceCollectionView.delegate respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:toCollectionView:toIndexPath:)]){
        
//        NSLog(@"%@ %li", sourceCollectionView.name, (long)self.destinationIndexPath.row);
        
        NSIndexPath *indexPath = (sourceCollectionView.destinationIndexPath == nil) ? sourceCollectionView.originIndexPath : sourceCollectionView.destinationIndexPath;
        
        NSLog(@"%@", sourceCollectionView.destinationIndexPath);
        NSLog(@"%@", sourceCollectionView.originIndexPath);
        
        canMove = [(NSObject <UICollectionViewDataSource_DropSupport> *)sourceCollectionView.delegate collectionView:sourceCollectionView
                                                                                              canMoveItemAtIndexPath:indexPath
                                                                                                    toCollectionView:self
                                                                                                         toIndexPath:self.dropDestinationIndexPath];
    }
    
    if (canMove) {

        NSIndexPath *indexPath = (sourceCollectionView.destinationIndexPath == nil) ? sourceCollectionView.originIndexPath : sourceCollectionView.destinationIndexPath;
        if ([(NSObject <UICollectionViewDataSource_DropSupport> *)sourceCollectionView.delegate respondsToSelector:@selector(collectionView:moveItemAtIndexPath:toCollectionView:toIndexPath:)]){
            [(NSObject <UICollectionViewDataSource_DropSupport> *)sourceCollectionView.delegate collectionView:sourceCollectionView
                                                                                           moveItemAtIndexPath:indexPath
                                                                                              toCollectionView:self
                                                                                                   toIndexPath:self.dropDestinationIndexPath];
        }
    }
}

- (void)didStartCellTransferAtLocation:(CGPoint)location fromSource:(DragDropController *)source {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.dropDestinationIndexPath = [self indexPathForItemAtPoint:location];
    self.layer.borderColor = [UIColor redColor].CGColor;
    self.layer.borderWidth = 2.0;

    if (self.dropDestinationIndexPath) [self moveCellFromSource:source];
}

- (void)didMoveCellTransferToLocation:(CGPoint)location fromSource:(DragDropController *)source {

    NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];
    if (!indexPathAtDragLocation)
        return;
    
    if (self.dropDestinationIndexPath && [self.dropDestinationIndexPath compare:indexPathAtDragLocation] == NSOrderedSame) {
        return;
    }
    
    if (self.isUpdatingCells) return;
    self.dropDestinationIndexPath = indexPathAtDragLocation;

    [self moveCellFromSource:source];
    [self insertSpaceForCellAtIndexPath:self.dropDestinationIndexPath
                               animated:YES];

}

- (void)didEndCellTransferFromSource:(DragDropController *)source {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    UICollectionView *sourceCollectionView = [self dragDropCollectionView:source];

    if (!sourceCollectionView.isDroppingCell)
        [self layoutCollectionViewAnimated:YES];
    
    self.layer.borderColor = [UIColor clearColor].CGColor;
    self.layer.borderWidth = 0.0;
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
      didStartDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    UICollectionView *sourceCollectionView = [self dragDropCollectionView:controller];
    UICollectionView *destinationCollectionView = [self dragDropCollectionView:destination];
    
    if (![sourceCollectionView isEqual: destinationCollectionView]) {
        return [destinationCollectionView didStartCellTransferAtLocation:location fromSource:controller];
    }
    else {
        if (self.originIndexPath == nil)
            self.originIndexPath = [self indexPathForItemAtPoint:location];
        
        if (self.destinationIndexPath == nil)
            self.destinationIndexPath = [self indexPathForItemAtPoint:location];
    }
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    
    UICollectionView *sourceCollectionView = [self dragDropCollectionView:controller];
    UICollectionView *destinationCollectionView = [self dragDropCollectionView:destination];
    
    if (![sourceCollectionView isEqual: destinationCollectionView]) {
        return [destinationCollectionView didMoveCellTransferToLocation:location fromSource:controller];
    }
    else {
        NSIndexPath *indexPathAtDragLocation = [self indexPathForItemAtPoint:location];
        if (!indexPathAtDragLocation) return;
        
        NSIndexPath *toIndexPath = indexPathAtDragLocation;
        NSIndexPath *fromIndexPath = self.destinationIndexPath
        ? self.destinationIndexPath
        : self.originIndexPath ;
        
        if (!fromIndexPath ||
            [fromIndexPath compare:indexPathAtDragLocation] == NSOrderedSame) return;
        
        if (self.isUpdatingCells) return;
        self.destinationIndexPath = toIndexPath;
        
        [self.dataSource collectionView:self
                    moveItemAtIndexPath:fromIndexPath
                            toIndexPath:toIndexPath];
        
        [self makeSpaceForCellFromIndexPath:self.originIndexPath
                                toIndexPath:toIndexPath
                                   animated:YES];
    }
}

- (void)dragDropController:(DragDropController *)controller
        didEndDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    UICollectionView *sourceCollectionView = [self dragDropCollectionView:controller];
    UICollectionView *destinationCollectionView = [self dragDropCollectionView:destination];
    
    if (![sourceCollectionView isEqual: destinationCollectionView]) {
        return [destinationCollectionView didEndCellTransferFromSource:controller];
    }
    else {
        if (self.isDroppingCell) {
            self.originIndexPath = nil;
            self.destinationIndexPath = nil;
        }
        else {
            [self removeSpaceForCellAtIndexPath:self.originIndexPath animated:YES];
        }
    }
}

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - DragDropController Datasource

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination {
    
    UICollectionView *sourceCollectionView = [self dragDropCollectionView:controller];
    UICollectionView *destinationCollectionView = [self dragDropCollectionView:destination];

    UICollectionView *collectionView = nil;
    NSIndexPath *indexPath = nil;
    
    if (![sourceCollectionView isEqual: destinationCollectionView]) {
        collectionView = destinationCollectionView;
        indexPath = destinationCollectionView.dropDestinationIndexPath;
    }
    else {
        collectionView = sourceCollectionView;
        indexPath = self.destinationIndexPath;
    }
    
    return [collectionView layoutAttributesForItemAtIndexPath:indexPath].frame;
}

#pragma mark -

- (void)iterateVisibleCellsWithBlock:(void (^)(NSIndexPath *, UICollectionViewCell *))blockName {

    NSArray *visibleCellIndexPaths = [[self indexPathsForVisibleItems] sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *idx1, NSIndexPath *idx2){
        return [idx1 compare:idx2];
    }];
    
    for (int i = 0; i < [visibleCellIndexPaths count]; i++) {
        NSIndexPath *indexPath = visibleCellIndexPaths[i];
        UICollectionViewCell *visibleCell = [self cellForItemAtIndexPath:indexPath];
        
        blockName(indexPath, visibleCell);
    }
}

- (void)insertSpaceForCellAtIndexPath:(NSIndexPath *)toIndexPath
                             animated:(BOOL)animated {
    
    self.isUpdatingCells = YES;
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [self iterateVisibleCellsWithBlock:^(NSIndexPath *indexPath, UICollectionViewCell *visibleCell){
            
            NSComparisonResult toResult = [indexPath compare:toIndexPath];
            NSIndexPath *nextIndexPath = indexPath;
            
            if (toResult == NSOrderedAscending) {
                // nothing...
                nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
            }
            else if (toResult == NSOrderedDescending || toResult == NSOrderedSame) {
                // + 1
                nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
            }
            
            [self applyAttributesToCell:visibleCell atIndexPath:nextIndexPath];
        }];

    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)removeSpaceForCellAtIndexPath:(NSIndexPath *)fromIndexPath
                             animated:(BOOL)animated {
    
    self.isUpdatingCells = YES;
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [self iterateVisibleCellsWithBlock:^(NSIndexPath *indexPath, UICollectionViewCell *visibleCell){
            // do not adjust the cell that is being moved..
            if ([indexPath compare:fromIndexPath] == NSOrderedSame) return;
            
            NSIndexPath *nextIndexPath = indexPath;
            
            // if this cell is after/below our cell being moved, then move the cell "up"
            // one indexpath so that the "gap" is closed..
            if ([indexPath compare:fromIndexPath] == NSOrderedDescending) {
                nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1
                                                   inSection:indexPath.section];
            }
            
            [self applyAttributesToCell:visibleCell atIndexPath:nextIndexPath];
        }];
        
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)layoutCollectionViewAnimated:(BOOL)animated {
    
    self.isUpdatingCells = YES;
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [self iterateVisibleCellsWithBlock:^(NSIndexPath *indexPath, UICollectionViewCell *visibleCell){
            [self applyAttributesToCell:visibleCell atIndexPath:indexPath];
        }];
        
    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)makeSpaceForCellFromIndexPath:(NSIndexPath *)fromIndexPath
                          toIndexPath:(NSIndexPath *)toIndexPath
                             animated:(BOOL)animated {
    
    self.isUpdatingCells = YES;
    [UIView animateWithDuration:animated ? .3 : 0.0 animations:^{
        
        [self iterateVisibleCellsWithBlock:^(NSIndexPath *indexPath, UICollectionViewCell *visibleCell){
            
            NSComparisonResult toResult = [indexPath compare:toIndexPath];
            NSComparisonResult fromResult = [indexPath compare:fromIndexPath];
            NSIndexPath *nextIndexPath = indexPath;
            
            if ([indexPath compare:fromIndexPath] == NSOrderedSame) {
                
                UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:toIndexPath];
                CGRect r = visibleCell.frame;
                r.size = attributes.size;
                visibleCell.frame = r;
                return;
            }
            
            if (toResult == NSOrderedAscending) {
                if (fromResult == NSOrderedDescending) {
                    // - 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
                }
            }
            else if (toResult == NSOrderedDescending) {
                if (fromResult == NSOrderedAscending) {
                    // + 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
                }
            }
            else if (toResult == NSOrderedSame) {
                NSComparisonResult toFromResult = [toIndexPath compare:fromIndexPath];
                if (toFromResult == NSOrderedAscending) {
                    // + 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
                }
                else if (toFromResult == NSOrderedDescending) {
                    // - 1
                    nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
                }
            }
            
            [self applyAttributesToCell:visibleCell atIndexPath:nextIndexPath];
        }];

    } completion:^(BOOL finsihed){
        self.isUpdatingCells = NO;
    }];
}

- (void)applyAttributesToCell:(UICollectionViewCell *)cell
                  atIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row < [self.dataSource collectionView:self numberOfItemsInSection:indexPath.section]) {
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        cell.frame = attributes.frame;
    }
}

#pragma mark -

- (void)setDragDropController:(DragDropController *)dragDropController {
    objc_setAssociatedObject(self, @selector(dragDropController), dragDropController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (DragDropController *)dragDropController {
    return objc_getAssociatedObject(self, @selector(dragDropController));
}

- (void)setName:(NSString *)name {
    objc_setAssociatedObject(self, @selector(name), name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)name {
    return objc_getAssociatedObject(self, @selector(name));
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

- (void)setDropDestinationIndexPath:(NSIndexPath *)dropDestinationIndexPath {
    objc_setAssociatedObject(self, @selector(dropDestinationIndexPath), dropDestinationIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)dropDestinationIndexPath {
    return objc_getAssociatedObject(self, @selector(dropDestinationIndexPath));
}



- (void)setDragEnabledCells:(NSMutableArray *)dragEnabledCells {
    objc_setAssociatedObject(self, @selector(dragEnabledCells), dragEnabledCells, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)dragEnabledCells {
    return objc_getAssociatedObject(self, @selector(dragEnabledCells));
}

@end
