//
//  ViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropController.h"

#import "ViewController.h"
#import "Drag.h"
#import "DragAndDropView.h"

@interface ViewController ()  <DragDropControllerDatasource, DragDropControllerDatasource>
@property (nonatomic, strong) UIView *leftView1;
@property (nonatomic, strong) UIView *rightView1;

@property (nonatomic, strong) UIView *leftView2;
@property (nonatomic, strong) UIView *rightView2;

@property (nonatomic, strong) DragDropController *leftViewDdc1;
@property (nonatomic, strong) DragDropController *rightViewDdc1;

@property (nonatomic, strong) DragDropController *leftViewDdc2;
@property (nonatomic, strong) DragDropController *rightViewDdc2;

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
    self.leftViewDdc1.view = self.leftView1;
    [self applyLabel:@"TopLeft" toView:self.leftView1];
    

    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 + 5,
                                                              20,
                                                              self.view.frame.size.width / 2 - 10,
                                                              self.view.frame.size.height /2 - 40)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.view = self.leftView2;
    [self applyLabel:@"TopRight" toView:self.leftView2];
    
    
    self.rightView1 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 + 5,
                                                               self.view.frame.size.height /2,
                                                               self.view.frame.size.width / 2 - 10,
                                                               self.view.frame.size.height /2 - 40)];
    self.rightView1.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.rightView1];
    self.rightViewDdc1.view = self.rightView1;
    [self applyLabel:@"BottomRight" toView:self.rightView1];
    
    self.rightView2 = [[UIView alloc] initWithFrame:CGRectMake(5,
                                                               self.view.frame.size.height /2,
                                                               self.view.frame.size.width / 2 - 10,
                                                               self.view.frame.size.height /2 - 40)];
    self.rightView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.rightView2];
    self.rightViewDdc2.view = self.rightView2;
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
    self.leftViewDdc1.view = self.leftView1;
    [self applyLabel:@"Container" toView:self.leftView1];
    
    
    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(5, self.view.frame.size.height/2 + 5, self.view.frame.size.width - 20, self.view.frame.size.height/2 - 40)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.view = self.leftView2;
    [self applyLabel:@"Inner" toView:self.leftView2];

    self.leftView2.layer.borderColor = [UIColor blackColor].CGColor;
    self.leftView2.layer.borderWidth = 2.0;

    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.leftView2 withCount:3 andDragDropController:self.leftViewDdc2];
}

- (void)loadDoubleDragView {
    self.leftViewDdc1 = [self controller];
    self.leftViewDdc2 = [self controller];

    self.leftView1 = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)/2 + 10, CGRectGetWidth(self.view.frame) - 10, CGRectGetHeight(self.view.frame)/2 - 20)];
    self.leftView1.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView1];
    self.leftViewDdc1.view = self.leftView1;
    [self applyLabel:@"InsetSubview" toView:self.leftView1];
    
    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(5, 25, self.view.frame.size.width - 10, self.view.frame.size.height/2 - 60)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.view = self.leftView2;
    [self applyLabel:@"Normal" toView:self.leftView2];

    
    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.leftView2 withCount:3 andDragDropController:self.leftViewDdc2];
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
    self.leftViewDdc1.view = self.leftView1;
    [self applyLabel:@"InsetSubview" toView:self.leftView1];
    
    self.leftView2 = [[UIView alloc] initWithFrame:CGRectMake(5, 25, self.view.frame.size.width - 10, self.view.frame.size.height/2 - 60)];
    self.leftView2.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView2];
    self.leftViewDdc2.view = self.leftView2;
    [self applyLabel:@"Normal" toView:self.leftView2];
    
    
    [self populateView:self.leftView1 withCount:5 andDragDropController:self.leftViewDdc1];
    [self populateView:self.leftView2 withCount:3 andDragDropController:self.leftViewDdc2];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];

    [self load4By4DragViews];
//    [self load4EmbeddedDragViews];
//    [self loadDoubleEmbeddedDragView];
//    [self loadDoubleDragView];
    
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
        
        DragAndDropView *dragview = [[DragAndDropView alloc] init];
        dragview.dragDropController = dragDropController;
        dragview.frame = CGRectMake(xMargin, yMargin, width, height);
        dragview.backgroundColor = [UIColor blackColor];
        [view addSubview:dragview];
        
        xMargin += width + 5;
    }

}

#pragma mark - DragDropController Delegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(Drag *)drag
                  animated:(BOOL)animated {
    drag.dragRepresentation.transform = CGAffineTransformMakeScale(1.5, 1.5);
    drag.view.alpha = 0.0;
}

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(Drag *)drag {
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)view
                   atPoint:(CGPoint)point {
}

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(Drag *)drag
                  animated:(BOOL)animated {
}

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(Drag *)drag {
    drag.dragRepresentation.transform = CGAffineTransformIdentity;
    drag.view.alpha = 1.0;
}

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

@end
