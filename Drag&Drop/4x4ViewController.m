//
//  4x4ViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "4x4ViewController.h"
#import "DragDropController.h"


@interface _x4ViewController ()
@property (nonatomic, strong) UIView *topLeftView;
@property (nonatomic, strong) UIView *bottomRightView;

@property (nonatomic, strong) UIView *topRightView;
@property (nonatomic, strong) UIView *bottomLeftView;

@property (nonatomic, strong) DragDropController *topLeftController;
@property (nonatomic, strong) DragDropController *bottomRightController;

@property (nonatomic, strong) DragDropController *topRightController;
@property (nonatomic, strong) DragDropController *bottomLeftController;

@end

@implementation _x4ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    [self loadContent];
}
- (void)loadContent {
    
    self.topLeftController = [self controller];
    self.bottomRightController = [self controller];
    self.topRightController = [self controller];
    self.bottomLeftController = [self controller];
    
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds)/2, CGRectGetHeight(self.view.bounds)/2 - 32);
    frame = CGRectInset(frame, 10, 10);
    
    self.topLeftView = [[UIView alloc] initWithFrame:CGRectOffset(frame, 0, 0)];
    self.topLeftView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.topLeftView];
    self.topLeftController.dropTargetView = self.topLeftView;
    [self applyLabel:@"TopLeft" toView:self.topLeftView];
    
    
    self.topRightView = [[UIView alloc] initWithFrame:CGRectOffset(frame, CGRectGetWidth(frame) + 20, 0)];
    self.topRightView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.topRightView];
    self.topRightController.dropTargetView = self.topRightView;
    [self applyLabel:@"TopRight" toView:self.topRightView];
    
    self.bottomLeftView = [[UIView alloc] initWithFrame:CGRectOffset(frame, 0, CGRectGetHeight(frame) + 20)];
    self.bottomLeftView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.bottomLeftView];
    self.bottomLeftController.dropTargetView = self.bottomLeftView;
    [self applyLabel:@"BottomLeft" toView:self.bottomLeftView];
    
    self.bottomRightView = [[UIView alloc] initWithFrame:CGRectOffset(frame, CGRectGetWidth(frame) + 20,
                                                                      CGRectGetHeight(frame) + 20)];
    self.bottomRightView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.bottomRightView];
    self.bottomRightController.dropTargetView = self.bottomRightView;
    [self applyLabel:@"BottomRight" toView:self.bottomRightView];
    
    
    [self populateView:self.topLeftView withCount:5 andDragDropController:self.topLeftController];
    [self populateView:self.bottomRightView withCount:6 andDragDropController:self.bottomRightController];
    
    [self populateView:self.topRightView withCount:4 andDragDropController:self.topRightController];
    [self populateView:self.bottomLeftView withCount:3 andDragDropController:self.bottomLeftController];
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

- (CGRect)frameForCount:(NSInteger)cnt inView:(UIView *)view {
    CGFloat width = 40;
    CGFloat height = 40;
    CGFloat xMargin = 5;
    CGFloat yMargin = 5;
    CGRect f = CGRectZero;
    for (int i = 0; i <= cnt; i++){
        if (xMargin + width > view.frame.size.width) {
            xMargin = 5;
            yMargin += height + 5;
        }
        
        f = CGRectMake(xMargin, yMargin, width, height);

        xMargin += width + 5;
    }
    return f;
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
    NSInteger cnt = destination.dropTargetView.subviews.count -1;
    return [self frameForCount:cnt inView:destination.dropTargetView];
}
- (UIView *)dragDropController:(DragDropController *)controller
     dragRepresentationForView:(UIView *)view {
    
    UIView *dragView = [[UIView alloc] initWithFrame:view.bounds];
    dragView.backgroundColor = [UIColor redColor];
    
    return dragView;
}

@end
