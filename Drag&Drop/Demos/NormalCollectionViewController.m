//
//  NormalCollectionViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "NormalCollectionViewController.h"
#import "UICollectionView+InteractiveMovementSupport.h"

@interface NormalCollectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collection;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *collectionSource;
@property (nonatomic, strong) NSMutableArray *collectionHeights;

@end

@implementation NormalCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadContent];
}

- (void)loadContent {
    
    self.collectionSource = [NSMutableArray array];
    self.collectionHeights = [NSMutableArray array];
    
    for (int i = 0; i < 300; i++) {
        [self.collectionSource addObject:@(i)];
        int n = arc4random() % 120;
        if (n < 40) n = 40;
        [self.collectionHeights addObject:@(n)];
    }
    

    self.layout = [[UICollectionViewFlowLayout alloc] init];
    self.layout.minimumInteritemSpacing = 4;
    self.layout.minimumLineSpacing = 4;
    self.layout.sectionInset = UIEdgeInsetsMake(4, 4, 4, 4);
    self.collection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 20,
                                                                         self.view.bounds.size.width,
                                                                         self.view.bounds.size.height-20)
                       
                                         collectionViewLayout:self.layout];
    self.collection.delegate = self;
    self.collection.dataSource = self;
    [self.view addSubview:self.collection];
    [self.collection registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CollectionViewCell"];
    
    [self.collection reloadData];
}

#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.collectionSource.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSNumber *n = self.collectionSource[indexPath.row];
    [self applyLabel:[NSString stringWithFormat:@"%li", (long)n.integerValue] toView:cell.contentView];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [collectionView enableDragAndDropForCell:cell atIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake((self.view.bounds.size.width/2)-6, [self.collectionHeights[indexPath.row] integerValue]);
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
    
    NSObject *item = [self.collectionSource objectAtIndex:sourceIndexPath.row];
    [self.collectionSource removeObject:item];
    [self.collectionSource insertObject:item atIndex:destinationIndexPath.row];
}

- (void)applyLabel:(NSString *)string toView:(UIView *)view {
    UILabel *l = [[UILabel alloc] init];
    l.text = string;
    [l sizeToFit];
    l.frame = CGRectMake(0, 0, CGRectGetWidth(l.frame), CGRectGetHeight(l.frame));
    [view addSubview:l];
}

@end
