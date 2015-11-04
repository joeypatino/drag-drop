//
//  NormalCollectionViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "NormalCollectionViewController.h"
#import "DragDropController.h"

@interface NormalCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) DragDropController *collectionViewController;

@property (nonatomic, strong) UICollectionView *collection;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *collectionSource;

@end

@implementation NormalCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadContent];
}

- (void)loadContent {
    
    self.collectionViewController = [self controller];
    
    self.collectionSource = [NSMutableArray array];
    for (int i = 0; i < 300; i++) {
        [self.collectionSource addObject:@(i)];
    }
    
    self.layout = [[UICollectionViewFlowLayout alloc] init];
    self.layout.minimumInteritemSpacing = 10;
    self.layout.minimumLineSpacing = 10;
    
    self.collection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 20,
                                                                         self.view.bounds.size.width,
                                                                         self.view.bounds.size.height-20)
                       
                                         collectionViewLayout:self.layout];
    self.collection.delegate = self;
    self.collection.dataSource = self;
    [self.view addSubview:self.collection];
    [self.collection registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CollectionViewCell"];
    
    [self.collection reloadData];
    
    self.collectionViewController.dropTargetView = self.collection;
}
#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.collectionSource.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = nil;
    
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    UIView *dragView = [[UIView alloc] initWithFrame:cell.bounds];
    dragView.backgroundColor = [UIColor blueColor];
    [cell.contentView addSubview:dragView];
    
    [self.collectionViewController enableDragActionForView:dragView];
    
    NSNumber *n = self.collectionSource[indexPath.row];
    [self applyLabel:[NSString stringWithFormat:@"%li", (long)n.integerValue] toView:dragView];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(80, 80);
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.collectionSource exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
}

- (DragDropController *)controller {
    DragDropController *d = [[DragDropController alloc] init];
    d.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    d.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    return d;
}
- (void)applyLabel:(NSString *)string toView:(UIView *)view {
    UILabel *l = [[UILabel alloc] init];
    l.text = string;
    [l sizeToFit];
    l.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
    [view addSubview:l];
}

#pragma mark - DragDropController Delegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragAction *)drag
                  animated:(BOOL)animated {
    drag.dragRepresentation.transform = CGAffineTransformMakeScale(1.5, 1.5);
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
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
      didStartDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    destination.dropTargetView.layer.borderColor = [UIColor redColor].CGColor;
    destination.dropTargetView.layer.borderWidth = 2.0;
    
//    NSIndexPath *i = [self.collection indexPathForItemAtPoint:location];
//    self.collectionViewIndexPath = i.row;
//    self.startingCollectionViewIndexPath = i.row;
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    
//    NSIndexPath *i = [self.collection indexPathForItemAtPoint:location];
//    
//    if (i && self.collectionViewIndexPath != i.row && self.collectionViewIndexPath != -1) {
//        
//        NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:self.self.startingCollectionViewIndexPath inSection:0];
//        NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:i.row inSection:0];
//        if (fromIndexPath.row == toIndexPath.row) return;
//        
//        [self.collection.dataSource collectionView:self.collection
//                               moveItemAtIndexPath:fromIndexPath
//                                       toIndexPath:toIndexPath];
//        
//        [self.collection moveItemAtIndexPath:fromIndexPath
//                                 toIndexPath:toIndexPath];
//        
//        self.startingCollectionViewIndexPath = i.row;
//        self.collectionViewIndexPath = i.row;
//    }
}

- (void)dragDropController:(DragDropController *)controller
        didEndDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    destination.dropTargetView.layer.borderColor = [UIColor clearColor].CGColor;
    destination.dropTargetView.layer.borderWidth = 0.0;
    
//    [self.collection reloadItemsAtIndexPaths:[self.collection indexPathsForVisibleItems]];
//    self.collectionViewIndexPath = -1;
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    return view.frame;
//    return [self.collection cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.collectionViewIndexPath inSection:0]].frame;
}

- (UIView *)dragDropController:(DragDropController *)controller
     dragRepresentationForView:(UIView *)view {
    
    UIView *dragView = [[UIView alloc] initWithFrame:view.bounds];
    dragView.backgroundColor = [UIColor redColor];
    
    return dragView;
}

@end
