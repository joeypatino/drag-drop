//
//  DoubleCollectionViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/14/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DoubleCollectionViewController.h"
#import "UICollectionView+DragDropControllerSupport.h"

@interface DoubleCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *leftCollectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *leftLayout;
@property (nonatomic, strong) NSMutableArray *leftDataSource;


@property (nonatomic, strong) UICollectionView *rightCollectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *rightLayout;
@property (nonatomic, strong) NSMutableArray *rightDataSource;

@end

@implementation DoubleCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadContent];
}

- (void)loadContent {
    [self loadLeftContent];
    [self loadRightContent];

}

- (void)loadLeftContent {
    self.leftDataSource = [NSMutableArray array];
    for (int i = 0; i < 4; i++) {
        [self.leftDataSource addObject:@(i)];
    }

    self.leftLayout = [[UICollectionViewFlowLayout alloc] init];
    self.leftLayout.minimumInteritemSpacing = 4;
    self.leftLayout.minimumLineSpacing = 4;
    self.leftLayout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
    self.leftCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 20,
                                                                                 self.view.bounds.size.width/2,
                                                                                 self.view.bounds.size.height-20)
                               
                                                 collectionViewLayout:self.leftLayout];
    self.leftCollectionView.delegate = self;
    self.leftCollectionView.dataSource = self;
    [self.view addSubview:self.leftCollectionView];
    [self.leftCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CollectionViewCell"];
    
    [self.leftCollectionView reloadData];
}

- (void)loadRightContent {
    self.rightDataSource = [NSMutableArray array];
    for (int i = 1; i < 7; i++) {
        [self.rightDataSource addObject:@(i*10)];
    }

    self.rightLayout = [[UICollectionViewFlowLayout alloc] init];
    self.rightLayout.minimumInteritemSpacing = 4;
    self.rightLayout.minimumLineSpacing = 4;
    self.rightLayout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
    self.rightCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2, 20,
                                                                                 self.view.bounds.size.width/2,
                                                                                 self.view.bounds.size.height-20)
                               
                                                 collectionViewLayout:self.rightLayout];
    self.rightCollectionView.delegate = self;
    self.rightCollectionView.dataSource = self;
    [self.view addSubview:self.rightCollectionView];
    [self.rightCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CollectionViewCell"];
    
    [self.rightCollectionView reloadData];
}

#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (collectionView == self.leftCollectionView)
        return self.leftDataSource.count;
    
    return self.rightDataSource.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark -

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSNumber *n = nil;
    if (collectionView == self.rightCollectionView)
        n = self.rightDataSource[indexPath.row];
    else
        n = self.leftDataSource[indexPath.row];
    
    [self applyLabel:[NSString stringWithFormat:@"%li", (long)n.integerValue] toView:cell.contentView];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [collectionView enableDragAndDropForCell:cell];
}

- (BOOL)collectionView:(UICollectionView *)sourceCollectionView canMoveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
      toCollectionView:(UICollectionView *)destinationCollectionView toIndexPath:(NSIndexPath *)destinationIndexPath {
//    NSLog(@"%s", __PRETTY_FUNCTION__);

    id item = nil;
    if ([collectionView isEqual:self.leftCollectionView]) {
//        NSLog(@"REMOVE:leftCollectionView");
        item = [self.leftDataSource objectAtIndex:sourceIndexPath.row];
        [self.leftDataSource removeObject:item];
    }
    else if ([collectionView isEqual:self.rightCollectionView]) {
//        NSLog(@"REMOVE:rightCollectionView");
        item = [self.rightDataSource objectAtIndex:sourceIndexPath.row];
        [self.rightDataSource removeObject:item];
    }
    
    if ([destinationCollectionView isEqual:self.rightCollectionView]) {
//        NSLog(@"INSERT:rightCollectionView");
        [self.rightDataSource insertObject:item atIndex:destinationIndexPath.row];
    }
    else if ([destinationCollectionView isEqual:self.leftCollectionView]) {
//        NSLog(@"INSERT:leftCollectionView");
        [self.leftDataSource insertObject:item atIndex:destinationIndexPath.row];
    }

//    NSLog(@"%li -> %li", sourceIndexPath.row, destinationIndexPath.row);
//    
//    NSLog(@"L: %li - %@", self.leftDataSource.count, self.leftDataSource);
//    NSLog(@"R: %li -  %@", self.rightDataSource.count, self.rightDataSource);
//
//    NSLog(@"######################################");
}

#pragma mark -

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((collectionView.bounds.size.width/2)-6, 120);
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
//    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (collectionView == self.leftCollectionView) {
//        NSLog(@"leftCollectionView");
        NSObject *item = [self.leftDataSource objectAtIndex:sourceIndexPath.row];
        [self.leftDataSource removeObject:item];
        [self.leftDataSource insertObject:item atIndex:destinationIndexPath.row];
    }
    else if (collectionView == self.rightCollectionView) {
//        NSLog(@"rightCollectionView");
        NSObject *item = [self.rightDataSource objectAtIndex:sourceIndexPath.row];
        [self.rightDataSource removeObject:item];
        [self.rightDataSource insertObject:item atIndex:destinationIndexPath.row];
    }
    
//    NSLog(@"L: %li - %@", self.leftDataSource.count, self.leftDataSource);
//    NSLog(@"R: %li -  %@", self.rightDataSource.count, self.rightDataSource);
//
//    NSLog(@"######################################");
}

#pragma mark -

- (void)applyLabel:(NSString *)string toView:(UIView *)view {
    UILabel *l = [[UILabel alloc] init];
    l.text = string;
    [l sizeToFit];
    l.frame = CGRectMake(0, 0, CGRectGetWidth(l.frame), CGRectGetHeight(l.frame));
    [view addSubview:l];
}

@end
