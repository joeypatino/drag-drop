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
    
    self.leftViewDragDropController = [[DragDropController alloc] init];
    self.leftViewDragDropController.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    self.leftViewDragDropController.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;
    
    self.rightViewDragDropController = [[DragDropController alloc] init];
    self.rightViewDragDropController.dragDropDataSource = (NSObject <DragDropControllerDatasource>*)self;
    self.rightViewDragDropController.dragDropDelegate = (NSObject <DragDropControllerDelegate>*)self;

    self.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width/2 - 10, self.view.frame.size.height)];
    self.leftView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.leftView];
    self.leftViewDragDropController.view = self.leftView;

    self.rightView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, 0, self.view.frame.size.width/2 - 10, self.view.frame.size.height)];
    self.rightView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.rightView];
    self.rightViewDragDropController.view = self.rightView;
    
    CGFloat width = 40;
    CGFloat height = 40;
    CGFloat xMargin = 5;
    CGFloat yMargin = 5;
    
    NSInteger viewCount = 10;
    
    for (int i = 0; i < viewCount; i++){
        if (xMargin + width > self.leftView.frame.size.width) {
            xMargin = 5;
            yMargin += height + 5;
        }

        DragView *view = [DragView new];
        view.dragDropController = self.leftViewDragDropController;
        view.frame = CGRectMake(xMargin, yMargin, width, height);
        view.backgroundColor = [UIColor blueColor];
        [self.leftView addSubview:view];
        
        xMargin += width + 5;
    }
    

    xMargin = 5;
    yMargin = 5;
    
    for (int i = 0; i < viewCount; i++){
        if (xMargin + width > self.rightView.frame.size.width) {
            xMargin = 5;
            yMargin += height + 5;
        }
        
        DragView *view = [DragView new];
        view.dragDropController = self.rightViewDragDropController;
        view.frame = CGRectMake(xMargin, yMargin, width, height);
        view.backgroundColor = [UIColor greenColor];
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"sourceView: %@", sourceView);
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
              isMovingView:(UIView *)view
            toNewSuperView:(UIView *)superview {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dragDropController:(DragDropController *)controller
         isDraggingAtPoint:(CGPoint)point {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dragDropController:(DragDropController *)controller
      didFinishDragAtPoint:(CGPoint)point {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - DragDropController Datasource

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
     animatingToNewSuperView:(UIView *)superview {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return CGRectZero;
}

- (CGRect)dragDropController:(DragDropController *)controller
                frameForView:(UIView *)view
              inNewSuperView:(UIView *)superview {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return CGRectZero;
}

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDragView:(UIView *)subview {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"subview: %@", subview);
    return YES;
}

- (UIView *)dragDropController:(DragDropController *)controller
           draggingViewAtPoint:(CGPoint)point
                        inView:(UIView *)baseView {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    return nil;
}

- (UIView *)dragDropController:(DragDropController *)controller
           dropRecieverAtPoint:(CGPoint)point {
    
    NSArray *controllers = @[self.leftViewDragDropController,
                             self.rightViewDragDropController];

    UIView *v = nil;
    for (DragDropController *c in controllers) {
        if (c == controller) continue;
        
        if (CGRectContainsPoint(c.view.frame, point)) {
            v = c.view;
            break;
        }
    }

    return v;
}

- (BOOL)dragDropController:(DragDropController *)controller
            shouldDropView:(UIView *)target
                    ToView:(UIView *)destination {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"target %@", target);
    NSLog(@"destination %@", destination);
    return NO;
}

@end
