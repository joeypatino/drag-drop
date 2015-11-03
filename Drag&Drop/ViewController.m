//
//  ViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropController.h"
#import "ViewController.h"

@interface ViewController ()  <DragDropControllerDatasource, DragDropControllerDatasource, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIView *leftView1;
@property (nonatomic, strong) UIView *rightView1;

@property (nonatomic, strong) UIView *leftView2;
@property (nonatomic, strong) UIView *rightView2;

@property (nonatomic, strong) DragDropController *leftViewDdc1;
@property (nonatomic, strong) DragDropController *rightViewDdc1;

@property (nonatomic, strong) DragDropController *leftViewDdc2;
@property (nonatomic, strong) DragDropController *rightViewDdc2;

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray *tableCellDragControllers;
@end

@implementation ViewController

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

- (void)load4By4DragViews {
    
    self.leftViewDdc1 = [self controller];
    self.rightViewDdc1 = [self controller];
    self.leftViewDdc2 = [self controller];
    self.rightViewDdc2 = [self controller];

    self.leftView1 = [[UIView alloc] initWithFrame:CGRectMake(5,
                                                              20,
                                                              self.view.frame.size.width / 2 - 10,
                                                              self.view.frame.size.height /2 - 40)];
    self.leftView1.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView1];
    self.leftViewDdc1.dropTargetView = self.leftView1;
    [self applyLabel:@"TopLeft" toView:self.leftView1];
    

    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 + 5,
                                                              20,
                                                              self.view.frame.size.width / 2 - 10,
                                                              self.view.frame.size.height /2 - 40)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.dropTargetView = self.leftView2;
    [self applyLabel:@"TopRight" toView:self.leftView2];
    
    
    self.rightView1 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 + 5,
                                                               self.view.frame.size.height /2,
                                                               self.view.frame.size.width / 2 - 10,
                                                               self.view.frame.size.height /2 - 40)];
    self.rightView1.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.rightView1];
    self.rightViewDdc1.dropTargetView = self.rightView1;
    [self applyLabel:@"BottomRight" toView:self.rightView1];
    
    self.rightView2 = [[UIView alloc] initWithFrame:CGRectMake(5,
                                                               self.view.frame.size.height /2,
                                                               self.view.frame.size.width / 2 - 10,
                                                               self.view.frame.size.height /2 - 40)];
    self.rightView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.rightView2];
    self.rightViewDdc2.dropTargetView = self.rightView2;
    [self applyLabel:@"BottomLeft" toView:self.rightView2];
    
    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.rightView1 withCount:6 andDragDropController:self.rightViewDdc1];
    
    [self populateView:self.leftView2 withCount:4 andDragDropController:self.leftViewDdc2];
    [self populateView:self.rightView2 withCount:3 andDragDropController:self.rightViewDdc2];
}

- (void)load4EmbeddedDragViews {
    self.leftViewDdc1 = [self controller];
    self.leftViewDdc2 = [self controller];

    self.leftView1 = [[UIView alloc] initWithFrame:CGRectMake(5, 25, self.view.frame.size.width - 10, self.view.frame.size.height - 30)];
    self.leftView1.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView1];
    self.leftViewDdc1.dropTargetView = self.leftView1;
    [self applyLabel:@"Container" toView:self.leftView1];
    
    
    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(5, self.view.frame.size.height/2 + 5, self.view.frame.size.width - 20, self.view.frame.size.height/2 - 40)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.dropTargetView = self.leftView2;
    [self applyLabel:@"Inner" toView:self.leftView2];

    self.leftView2.layer.borderColor = [UIColor blackColor].CGColor;
    self.leftView2.layer.borderWidth = 2.0;

    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.leftView2 withCount:3 andDragDropController:self.leftViewDdc2];
}

- (void)loadDoubleDragView {
    self.leftViewDdc1 = [self controller];
    self.leftViewDdc2 = [self controller];
    self.rightViewDdc1 = [self controller];

    self.leftView1 = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)/2 + 10, CGRectGetWidth(self.view.frame) - 10, CGRectGetHeight(self.view.frame)/2 - 20)];
    self.leftView1.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView1];
    self.leftViewDdc1.dropTargetView = self.leftView1;
    [self applyLabel:@"InsetSubview" toView:self.leftView1];
    
    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(5, 25, self.view.frame.size.width - 10, self.view.frame.size.height/2 - 60)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.dropTargetView = self.leftView2;
    [self applyLabel:@"Normal" toView:self.leftView2];

    
    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.leftView2 withCount:3 andDragDropController:self.leftViewDdc2];
    
    self.rightViewDdc1.dropTargetView = self.leftView1.subviews[1];
}

- (void)loadDoubleEmbeddedDragView {
    self.leftViewDdc1 = [self controller];
    self.leftViewDdc2 = [self controller];

    UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(5, CGRectGetHeight(self.view.frame)/2, CGRectGetWidth(self.view.frame) - 10, CGRectGetHeight(self.view.frame)/2)];
    dummyView.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:dummyView];

    self.leftView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 10, CGRectGetWidth(dummyView.frame), CGRectGetHeight(dummyView.frame) - 20)];
    self.leftView1.backgroundColor = [UIColor whiteColor];
    [dummyView addSubview:self.leftView1];
    self.leftViewDdc1.dropTargetView = self.leftView1;
    [self applyLabel:@"InsetSubview" toView:self.leftView1];
    
    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(5, 25, self.view.frame.size.width - 10, self.view.frame.size.height/2 - 60)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.dropTargetView = self.leftView2;
    [self applyLabel:@"Normal" toView:self.leftView2];
    
    
    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.leftView2 withCount:3 andDragDropController:self.leftViewDdc2];
}

- (void)loadDoubleDoubleEmbeddedDragView {
    self.leftViewDdc1 = [self controller];
    self.leftViewDdc2 = [self controller];
    
    UIView *dummyView1 = [[UIView alloc] initWithFrame:CGRectMake(5,
                                                                  CGRectGetHeight(self.view.frame)/2,
                                                                  CGRectGetWidth(self.view.frame) - 10,
                                                                  CGRectGetHeight(self.view.frame)/2)];
    dummyView1.backgroundColor = [UIColor blackColor];
    [self.view addSubview:dummyView1];

    UIView *dummyView2 = [[UIView alloc] initWithFrame:CGRectInset(dummyView1.bounds, 10, 10)];
    dummyView2.backgroundColor = [UIColor whiteColor];
    [dummyView1 addSubview:dummyView2];

    self.leftView1 = [[UIView alloc] initWithFrame:CGRectInset(dummyView2.bounds, 10, 10)];
    self.leftView1.backgroundColor = [UIColor orangeColor];
    [dummyView2 addSubview:self.leftView1];
    self.leftViewDdc1.dropTargetView = self.leftView1;
    [self applyLabel:@"Double-Inset Subview" toView:self.leftView1];
    
    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(5, 25, self.view.frame.size.width - 10, self.view.frame.size.height/2 - 60)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.dropTargetView = self.leftView2;
    [self applyLabel:@"Normal" toView:self.leftView2];
    
    
    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.leftView2 withCount:3 andDragDropController:self.leftViewDdc2];
}

- (void)loadTableDragView {
    self.rightViewDdc1 = [self controller];
    self.tableCellDragControllers = [NSMutableArray array];
    
    self.table = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                               20,
                                                               CGRectGetWidth(self.view.frame) * .75,
                                                               CGRectGetHeight(self.view.frame) - 20)
                                              style:UITableViewStylePlain];
    
    self.table.separatorColor = [UIColor blackColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    self.table.delegate = self;
    self.table.dataSource = self;
    [self.view addSubview:self.table];
    [self.table reloadData];
    
    self.rightView1 = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) * .75,
                                                              20,
                                                              CGRectGetWidth(self.view.frame) * .25,
                                                              self.view.frame.size.height - 20)];
    self.rightView1.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.rightView1];
    self.rightViewDdc1.dropTargetView = self.rightView1;
    [self applyLabel:@"Right" toView:self.rightView1];
    
    self.leftViewDdc1 = [self controller];
    self.leftViewDdc1.dropTargetView = self.table;

}

- (void)loadRandomDragDropView {
    self.leftViewDdc1 = [self controller];
    
    UIView *dummyView1 = [[UIView alloc] initWithFrame:CGRectInset(CGRectMake(5,
                                                                              CGRectGetHeight(self.view.frame)/2,
                                                                              CGRectGetWidth(self.view.frame) - 10,
                                                                              CGRectGetHeight(self.view.frame)/2), 80, 80)];
    dummyView1.backgroundColor = [UIColor blackColor];
    [self.view addSubview:dummyView1];

    [self.leftViewDdc1 enableDragActionForView:dummyView1];
    
    self.leftViewDdc2 = [self controller];
    

    UIView *dummyView2 = [[UIView alloc] initWithFrame:CGRectInset(CGRectMake(5,
                                                                              25,
                                                                              CGRectGetWidth(self.view.frame) - 10,
                                                                              CGRectGetHeight(self.view.frame)/2), 100, 100)];
    dummyView2.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:dummyView2];
    self.leftViewDdc2.dropTargetView = dummyView2;

}

#pragma mark -

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
    [self.tableCellDragControllers addObject:c];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];

//    [self load4By4DragViews];
//    [self load4EmbeddedDragViews];
//    [self loadDoubleEmbeddedDragView];
//    [self loadDoubleDragView];
//    [self loadDoubleDoubleEmbeddedDragView];
    [self loadTableDragView];
//    [self loadRandomDragDropView];
}

- (void)populateView:(UIView *)view withCount:(NSInteger)viewCount andDragDropController:(DragDropController *)dragDropController {
    CGFloat width = 40;
    CGFloat height = 40;
    CGFloat xMargin = 5;
    CGFloat yMargin = 5;
    
    for (int i = 0; i < viewCount; i++){
        if (xMargin + width > view.frame.size.width) {
            xMargin = 5;
            yMargin += height + 5;
        }
        
        UIView *dragview = [[UIView alloc] init];
        [dragDropController enableDragActionForView:dragview];
        dragview.frame = CGRectMake(xMargin, yMargin, width, height);
        dragview.backgroundColor = [UIColor blackColor];
        [view addSubview:dragview];
        
        xMargin += width + 5;
    }
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
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
}

- (void)dragDropController:(DragDropController *)controller
        didEndDraggingView:(UIView *)view
                atLocation:(CGPoint)location
           withDestination:(DragDropController *)destination {
    destination.dropTargetView.layer.borderColor = [UIColor clearColor].CGColor;
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
    return view.frame;
}

- (UIView *)dragDropController:(DragDropController *)controller dragRepresentationForView:(UIView *)view {
    UIView *dragView = [[UIView alloc] initWithFrame:view.bounds];
    dragView.backgroundColor = [UIColor redColor];
    return dragView;
}


@end
