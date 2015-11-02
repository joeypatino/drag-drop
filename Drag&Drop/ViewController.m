//
//  ViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropController.h"

#import "ViewController.h"
#import "DragDrop.h"
#import "DragView.h"

@interface ViewController ()  <DragDropControllerDatasource, DragDropControllerDatasource>
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIView *rightView;

@property (nonatomic, strong) DragDropController *rightViewDragDropController;
@property (nonatomic, strong) DragDropController *leftViewDragDropController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    self.leftViewDragDropController = [[DragDropController alloc] init];
    self.leftViewDragDropController.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    self.leftViewDragDropController.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    
    self.rightViewDragDropController = [[DragDropController alloc] init];
    self.rightViewDragDropController.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    self.rightViewDragDropController.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;

    self.leftView = [[UIView alloc] initWithFrame:CGRectMake(5, 20, self.view.frame.size.width/2 - 10, self.view.frame.size.height - 40)];
    self.leftView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.leftView];
    self.leftViewDragDropController.view = self.leftView;

    self.rightView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 + 5, 20, self.view.frame.size.width/2 - 10, self.view.frame.size.height - 40)];
    self.rightView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.rightView];
    self.rightViewDragDropController.view = self.rightView;
    
    CGFloat width = 40;
    CGFloat height = 40;
    CGFloat xMargin = 5;
    CGFloat yMargin = 5;
    
    NSInteger viewCount = 5;
    
    for (int i = 0; i < viewCount; i++){
        if (xMargin + width > self.leftView.frame.size.width) {
            xMargin = 5;
            yMargin += height + 5;
        }

        DragView *view = [[DragView alloc] init];
        view.dragDropController = self.leftViewDragDropController;
        view.frame = CGRectMake(xMargin, yMargin, width, height);
        view.backgroundColor = [UIColor blackColor];
        [self.leftView addSubview:view];
        
        xMargin += width + 5;
    }
    
    viewCount = 6;
    xMargin = 5;
    yMargin = 5;
    
    for (int i = 0; i < viewCount; i++){
        if (xMargin + width > self.rightView.frame.size.width) {
            xMargin = 5;
            yMargin += height + 5;
        }
        
        DragView *view = [[DragView alloc] init];
        view.dragDropController = self.rightViewDragDropController;
        view.frame = CGRectMake(xMargin, yMargin, width, height);
        view.backgroundColor = [UIColor blackColor];
        [self.rightView addSubview:view];
        
        xMargin += width + 5;
    }
}

#pragma mark - DragDropController Delegate

- (void)dragDropController:(DragDropController *)controller
             willStartDrag:(DragDrop *)dd
                  animated:(BOOL)animated {
    dd.dragRepresentation.transform = CGAffineTransformMakeScale(1.5, 1.5);
    dd.view.alpha = 0.0;
}

- (void)dragDropController:(DragDropController *)controller
              didStartDrag:(DragDrop *)dd {
}

- (void)dragDropController:(DragDropController *)controller
            isDraggingView:(UIView *)sourceView
                   AtPoint:(CGPoint)point {
}

- (void)dragDropController:(DragDropController *)controller
               willEndDrag:(DragDrop *)dd
                  animated:(BOOL)animated {
}

- (void)dragDropController:(DragDropController *)controller
                didEndDrag:(DragDrop *)dd {
    dd.dragRepresentation.transform = CGAffineTransformIdentity;
    dd.view.alpha = 1.0;
}

- (void)dragDropController:(DragDropController *)controller
               didMoveView:(UIView *)view
             toDestination:(DragDropController *)destination {
}

- (void)dragDropController:(DragDropController *)controller
         isDraggingAtPoint:(CGPoint)point {
}

- (void)dragDropController:(DragDropController *)controller
      didFinishDragAtPoint:(CGPoint)point {
}

#pragma mark - DragDropController Datasource

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)subview {
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
