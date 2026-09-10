//
//  NormalTableViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "NormalTableViewController.h"
#import "DragDropController.h"

@interface NormalTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) DragDropController *targetController;
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) UIView *targetView;
@property (nonatomic, strong) NSMutableArray *tableControllers;
@end

@implementation NormalTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadContent];
}

- (void)loadContent {
    self.targetController = [self controller];
    self.tableControllers = [NSMutableArray array];

    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame)/2, CGRectGetHeight(self.view.frame)-64);
    self.table = [[UITableView alloc] initWithFrame:frame
                                              style:UITableViewStylePlain];
    
    self.table.separatorColor = [UIColor blackColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    self.table.delegate = self;
    self.table.dataSource = self;
    [self.view addSubview:self.table];
    [self.table reloadData];
    
    self.targetView = [[UIView alloc] initWithFrame:CGRectOffset(CGRectInset(frame, 20, 20), CGRectGetWidth(frame), 0)];
    self.targetView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.targetView];
    self.targetController.dropTargetView = self.targetView;
    [self applyLabel:@"Drop Target" toView:self.targetView];

    self.targetView.layer.borderColor = [UIColor blackColor].CGColor;
    self.targetView.layer.borderWidth = 2.0;

}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIView *dragView = [[UIView alloc] init];
    dragView.frame = CGRectMake(10, 10, CGRectGetWidth(tableView.frame) - 20, 70);
    dragView.backgroundColor = [UIColor blueColor];
    [cell addSubview:dragView];
    
    DragDropController *c = [self controller];
    c.dropTargetView = cell;
    [c enableDragActionForView:dragView];
    [self.tableControllers addObject:c];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
}

#pragma mark -

- (void)dragDropController:(DragDropController *)controller
              dragDidEnter:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    destination.dropTargetView.layer.borderColor = [UIColor redColor].CGColor;
    destination.dropTargetView.layer.borderWidth = 2.0;
}
- (void)dragDropController:(DragDropController *)controller
               dragDidMove:(DragAction *)drag
     destinationController:(DragDropController *)destination {
}
- (void)dragDropController:(DragDropController *)controller
               dragDidExit:(DragAction *)drag
     destinationController:(DragDropController *)destination {

    if (destination.dropTargetView == self.targetView)
        destination.dropTargetView.layer.borderColor = [UIColor blackColor].CGColor;
    else
        destination.dropTargetView.layer.borderWidth = 0.0;
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
    if (controller == destination) return NO;
    return YES;
}
- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
               inDestination:(DragDropController *)destination {

    if (destination == self.targetController) {
        NSInteger cnt = destination.dropTargetView.subviews.count-1;
        return CGRectMake(5, cnt * CGRectGetHeight(view.frame) + ((cnt + 1) * 5),
                          CGRectGetWidth(destination.dropTargetView.frame) - 10, CGRectGetHeight(view.frame));
    }
    
    return CGRectInset(destination.dropTargetView.bounds, 10, 10);
}

@end
