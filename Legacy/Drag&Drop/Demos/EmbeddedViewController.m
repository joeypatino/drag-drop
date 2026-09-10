//
//  EmbeddedViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "EmbeddedViewController.h"
#import "DragDropController.h"

@interface EmbeddedViewController ()
@property (nonatomic, strong) DragDropController *containerController;
@property (nonatomic, strong) DragDropController *embeddedController;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *embeddedView;
@end

@implementation EmbeddedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadContent];
}

- (void)loadContent {
    self.containerController = [self controller];
    self.embeddedController = [self controller];
    
    CGRect frame = CGRectMake(20, 20, CGRectGetWidth(self.view.frame) - 40, CGRectGetHeight(self.view.frame) - 64 - 40);
    
    self.containerView = [[UIView alloc] initWithFrame:frame];
    self.containerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
    self.containerController.dropTargetView = self.containerView;
    [self applyLabel:@"Container" toView:self.containerView atOffset:CGPointMake(0, -120)];
    
    self.containerView.layer.borderColor = [UIColor blackColor].CGColor;
    self.containerView.layer.borderWidth = 2.0;
    
    self.embeddedView = [[UIView alloc] initWithFrame:CGRectMake(10, CGRectGetHeight(frame)/2 + 10,
                                                                 CGRectGetWidth(frame) - 20, CGRectGetHeight(frame)/2 - 20)];
    self.embeddedView.backgroundColor = [UIColor whiteColor];
    [self.containerView addSubview:self.embeddedView];
    self.embeddedController.dropTargetView = self.embeddedView;
    [self applyLabel:@"Embedded" toView:self.embeddedView atOffset:CGPointMake(0, 0)];
    
    self.embeddedView.layer.borderColor = [UIColor blackColor].CGColor;
    self.embeddedView.layer.borderWidth = 2.0;

    
    [self populateView:self.embeddedView withCount:3 andDragDropController:self.embeddedController];
    [self populateView:self.containerView withCount:5 andDragDropController:self.containerController];
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
}
- (void)dragDropController:(DragDropController *)controller
               dragDidMove:(DragAction *)drag
     destinationController:(DragDropController *)destination {
}
- (void)dragDropController:(DragDropController *)controller
               dragDidExit:(DragAction *)drag
     destinationController:(DragDropController *)destination {
    destination.dropTargetView.layer.borderColor = [UIColor clearColor].CGColor;
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
    if (destination == self.containerController) cnt--;
    
    return CGRectMake(5 + (cnt * CGRectGetWidth(view.frame) + (cnt * 5)), 5, CGRectGetWidth(view.frame), CGRectGetHeight(view.frame));
}

@end
