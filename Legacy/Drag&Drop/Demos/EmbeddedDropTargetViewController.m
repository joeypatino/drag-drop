//
//  EmbeddedDropTargetViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "EmbeddedDropTargetViewController.h"
#import "DragDropController.h"

@interface EmbeddedDropTargetViewController ()
@property (nonatomic, strong) DragDropController *containerController;
@property (nonatomic, strong) DragDropController *outerEmbeddedController;
@property (nonatomic, strong) DragDropController *innerEmbeddedController;

@property (nonatomic, strong) UIView *upperView;
@property (nonatomic, strong) UIView *lowerView;

@end

@implementation EmbeddedDropTargetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadContent];
}

- (void)loadContent {
    self.containerController = [self controller];
    self.outerEmbeddedController = [self controller];
    self.innerEmbeddedController = [self controller];

    CGRect frame = CGRectMake(10, 10, CGRectGetWidth(self.view.frame) - 20, CGRectGetHeight(self.view.frame)/2-32 - 20);
    
    self.upperView = [[UIView alloc] initWithFrame:frame];
    self.upperView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.upperView];
    self.containerController.dropTargetView = self.upperView;
    [self applyLabel:@"Upper View" toView:self.upperView];
    
    self.upperView.layer.borderColor = [UIColor blackColor].CGColor;
    self.upperView.layer.borderWidth = 2.0;
    
    self.lowerView = [[UIView alloc] initWithFrame:CGRectOffset(frame, 0, CGRectGetHeight(frame) + 20)];
    self.lowerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.lowerView];
    self.outerEmbeddedController.dropTargetView = self.lowerView;
    [self applyLabel:@"Lower View \n(Contains Embedded Drop Target)" toView:self.lowerView];
    
    self.lowerView.layer.borderColor = [UIColor blackColor].CGColor;
    self.lowerView.layer.borderWidth = 2.0;
    
    [self populateView:self.upperView withCount:5 andDragDropController:self.containerController];
    [self populateView:self.lowerView withCount:3 andDragDropController:self.outerEmbeddedController];
    
    self.innerEmbeddedController.dropTargetView = self.lowerView.subviews[1];
}

- (DragDropController *)controller {
    DragDropController *d = [[DragDropController alloc] init];
    d.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    d.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    return d;
}
- (void)applyLabel:(NSString *)string toView:(UIView *)view {
    UILabel *l = [[UILabel alloc] init];
    l.numberOfLines = 2;
    l.textAlignment = NSTextAlignmentCenter;
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

    if (destination.dropTargetView == self.upperView || destination.dropTargetView == self.lowerView){
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

    if (destination == self.innerEmbeddedController)
        return destination.dropTargetView.bounds;

    NSInteger cnt = destination.dropTargetView.subviews.count -1;
    return CGRectMake(5 + (cnt * CGRectGetWidth(view.frame) + (cnt * 5)), 5, CGRectGetWidth(view.frame), CGRectGetHeight(view.frame));
}

@end
