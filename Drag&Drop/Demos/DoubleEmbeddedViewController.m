//
//  DoubleEmbeddedViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DoubleEmbeddedViewController.h"
#import "DragDropController.h"

@interface DoubleEmbeddedViewController ()
@property (nonatomic, strong) DragDropController *containerController;
@property (nonatomic, strong) DragDropController *embeddedController;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *embeddedView;

@end

@implementation DoubleEmbeddedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadContent];

}
- (void)loadContent {

    self.containerController = [self controller];
    self.embeddedController = [self controller];
    
    CGRect frame = CGRectMake(10, 10, CGRectGetWidth(self.view.frame) - 20, CGRectGetHeight(self.view.frame)/2 - 32 - 20);
    
    UIView *embeddedViewContainer = [[UIView alloc] initWithFrame:frame];
    embeddedViewContainer.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:embeddedViewContainer];
    [self applyLabel:@"Dummy Container View" toView:embeddedViewContainer atOffset:CGPointMake(0, -80)];
    
    self.embeddedView = [[UIView alloc] initWithFrame:CGRectOffset(CGRectInset(embeddedViewContainer.bounds, 20, 80), 0, 60)];
    self.embeddedView.backgroundColor = [UIColor whiteColor];
    [embeddedViewContainer addSubview:self.embeddedView];
    self.embeddedController.dropTargetView = self.embeddedView;
    [self applyLabel:@"Inset Subview" toView:self.embeddedView atOffset:CGPointMake(0,0)];

    self.embeddedView.layer.borderColor = [UIColor blackColor].CGColor;
    self.embeddedView.layer.borderWidth = 2.0;

    self.containerView = [[UIView alloc] initWithFrame:CGRectOffset(frame, 0, CGRectGetHeight(frame) + 20)];
    self.containerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
    self.containerController.dropTargetView = self.containerView;
    [self applyLabel:@"" toView:self.containerView atOffset:CGPointMake(0, 0)];
    
    self.containerView.layer.borderColor = [UIColor blackColor].CGColor;
    self.containerView.layer.borderWidth = 2.0;
    
    [self populateView:self.containerView withCount:5 andDragDropController:self.containerController];
    [self populateView:self.embeddedView withCount:3 andDragDropController:self.embeddedController];

}
- (DragDropController *)controller {
    DragDropController *d = [[DragDropController alloc] init];
    d.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    d.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    return d;
}
- (void)applyLabel:(NSString *)string toView:(UIView *)view atOffset:(CGPoint)offset {
    UILabel *l = [[UILabel alloc] init];
    l.text = string;
    [l sizeToFit];
    l.center = CGPointMake(view.frame.size.width/2 + offset.x, view.frame.size.height/2 + offset.y);
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

    if (destination == self.containerController || destination == self.embeddedController) {
        destination.dropTargetView.layer.borderColor = [UIColor blackColor].CGColor;
    }
    else {
        destination.dropTargetView.layer.borderColor = [UIColor clearColor].CGColor;
        destination.dropTargetView.layer.borderWidth = 0.0;
    }
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
    return CGRectMake(5 + (cnt * CGRectGetWidth(view.frame) + (cnt * 5)), 5, CGRectGetWidth(view.frame), CGRectGetHeight(view.frame));
}
- (UIView *)dragDropController:(DragDropController *)controller
     dragRepresentationForView:(UIView *)view {
    
    UIView *dragView = [[UIView alloc] initWithFrame:view.bounds];
    dragView.backgroundColor = [UIColor redColor];
    
    return dragView;
}

@end
