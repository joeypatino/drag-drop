//
//  DragDropController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropController.h"
#import "DragInteractionView.h"
#import "DragView.h"
#import "DragDrop.h"


#pragma mark - DragDropControllerManager

@interface DragDropControllerManager : NSObject
@property (nonatomic, strong) NSMutableArray *dragDropControllers;
+ (DragDropControllerManager *)sharedInstance;
@end

static DragDropControllerManager *instance = nil;

@implementation DragDropControllerManager
+ (DragDropControllerManager *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DragDropControllerManager alloc] init];
    });
    return instance;
}
- (id)init {
    self = [super init];
    self.dragDropControllers = [self mutableArrayUsingWeakReferences];
    return self;
}
- (void)addDragDropController:(DragDropController *)controller {
    [self.dragDropControllers addObject:controller];
}
- (void)removeDragDropController:(DragDropController *)controller {
    [self.dragDropControllers removeObject:controller];
}
- (NSArray *)allControllers {
    return [NSArray arrayWithArray:self.dragDropControllers];
}
- (id)mutableArrayUsingWeakReferences {
    return [self mutableArrayUsingWeakReferencesWithCapacity:0];
}
- (id)mutableArrayUsingWeakReferencesWithCapacity:(NSUInteger)capacity {
    CFArrayCallBacks callbacks = {0, NULL, NULL, CFCopyDescription, CFEqual};
    // We create a weak reference array
    return (id)CFBridgingRelease(CFArrayCreateMutable(0, capacity, &callbacks));
}
@end

#pragma mark - DragDropController

@interface DragDropController ()
@property (nonatomic, strong) DragInteractionView *dragInteractionView;
@end

@implementation DragDropController

#pragma mark -

- (id)init {
    self = [super init];
    [[DragDropControllerManager sharedInstance] addDragDropController:self];
    return self;
}

- (void)dealloc {
    [[DragDropControllerManager sharedInstance] removeDragDropController:self];
}

#pragma mark -

- (BOOL)dragDropStarted:(DragDrop *)dd {
    
    if ([self.dragDropDataSource dragDropController:self shouldDragView:dd.view]){
        self.isDragging = YES;
        self.isDropping = NO;

        dd.dragRepresentation.frame = [self.dragInteractionView convertRect:dd.view.frame fromView:dd.view.superview];
        [self.dragInteractionView addSubview:dd.dragRepresentation];
        
        [UIView animateWithDuration:kDragDropPickupAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                                 [self.dragDropDelegate dragDropController:self willStartDrag:dd animated:YES];
                         }
                         completion:^ (BOOL finished){
                             [self.dragDropDelegate dragDropController:self didStartDrag:dd];
                         }];
        
        return YES;
    }
    
    return NO;
}

- (void)dragDropMoved:(DragDrop *)dd {
    if (!self.isDragging) return;
    
    CGPoint location = dd.currentLocation;
    UIView *subview = [self.dragInteractionView hitTest:location withEvent:nil];
    
    if (subview) {
        
        [self.dragDropDelegate dragDropController:self
                                   isDraggingView:dd.view
                                          AtPoint:location];
        
        CGPoint adjustmentForTransform = CGPointZero;
        
        if (CGAffineTransformEqualToTransform(dd.dragRepresentation.transform, CGAffineTransformIdentity) == NO) {
            
            CGRect r = CGRectApplyAffineTransform(dd.view.frame, dd.dragRepresentation.transform);
            
            adjustmentForTransform = CGPointMake((r.size.width - CGRectGetWidth(dd.view.frame)) / 2,
                                                 (r.size.height - CGRectGetHeight(dd.view.frame)) / 2);
        }
        
        CGRect updatedFrame = CGRectMake(location.x - dd.firstTouchOffset.x - adjustmentForTransform.x,
                                         location.y - dd.firstTouchOffset.y - adjustmentForTransform.y,
                                         subview.frame.size.width,
                                         subview.frame.size.height);;
        
        subview.frame = updatedFrame;
    }
    
}

- (void)dragDropEnded:(DragDrop *)dd {

    if (!self.isDragging) return;
    
    self.isDropping = YES;

    CGRect firstStepFrame = CGRectZero;
    CGRect secondStepFrame = CGRectZero;
    void (^animationCompletionBlock)(BOOL) = NULL;
    __weak DragDropController *this = self;
    
    DragDropController *dropDestination = [self controllerForDropAtPoint:dd.currentLocation];

    if (dropDestination && [self.dragDropDataSource dragDropController:self
                                                           canDropView:dd.view
                                                         toDestination:dropDestination]) {
        
        // call the datasource and have them return the proper frames
        firstStepFrame = [self.dragDropDataSource dragDropController:self
                                                        frameForView:dd.view
                                                       inDestination:dropDestination];
        
        secondStepFrame = firstStepFrame;
        firstStepFrame = [dropDestination.view convertRect:firstStepFrame toView:nil];

        animationCompletionBlock = ^ (BOOL finished){
            this.isDragging = NO;
            this.isDropping = NO;
            
            dd.view.frame = [dropDestination.view convertRect:secondStepFrame toView:dropDestination.view];
            [dropDestination.view addSubview:dd.view];

            dd.view.dragDropController = dropDestination;
            [this.dragDropDelegate dragDropController:this didMoveView:dd.view toDestination:dropDestination];
        };
        
    }
    else {
        
        firstStepFrame = [dd.view.superview convertRect:dd.view.frame toView:self.dragInteractionView];

        animationCompletionBlock = ^ (BOOL finished){
            this.isDragging = NO;
            this.isDropping = NO;
        };
    }
    
    void (^commonCompletionBlock)(BOOL) = ^(BOOL finished){
    
        [this.dragDropDelegate dragDropController:this didEndDrag:dd];
        
        [dd.dragRepresentation removeFromSuperview];
        dd.dragRepresentation = nil;
        
        [_dragInteractionView removeFromSuperview];
        _dragInteractionView = nil;
    };

    
    [UIView animateWithDuration: kDropAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{

                         dd.dragRepresentation.frame = firstStepFrame;
                         [self.dragDropDelegate dragDropController:self
                                                       willEndDrag:dd
                                                          animated:YES];
                     }
                     completion:^(BOOL finished){
                         
                         if (animationCompletionBlock)
                             animationCompletionBlock(finished);
                         
                         commonCompletionBlock(finished);
                     }];
    
}

- (DragDropController *)controllerForDropAtPoint:(CGPoint)point {
    
    DragDropController *controller = nil;
    for (DragDropController *dragDropController in [[DragDropControllerManager sharedInstance] allControllers]) {
        if (CGRectContainsPoint(dragDropController.view.frame, point)) {
            controller = dragDropController;
            break;
        }
    }
    
    return controller;
}

#pragma mark -

- (DragInteractionView *)dragInteractionView {
    
    if (!_dragInteractionView) {
        
        UIViewController *top = [DragDropController topMostViewController];
        __weak DragDropController *this = self;
        _dragInteractionView = [[DragInteractionView alloc] initWithFrame:top.view.frame];
        [(DragInteractionView *)_dragInteractionView setHitTest: ^(CGPoint point, UIEvent *event){
            
            UIView *hitView = nil;
            for (UIView *subview in this.dragInteractionView.subviews) {
                hitView = subview;
            }
            
            //            if (hitView) [this.dragDropDelegate dragDropController:this isDraggingAtPoint:point];
            
            // we we found a view then we should return it so that it receives the
            // touch events.
            if (hitView) {
                return hitView;
            }
            
            return hitView;
        }];
        
        [top.view addSubview:_dragInteractionView];
    }
    
    return (DragInteractionView *)_dragInteractionView;
}

+ (UIViewController *) topMostViewController {
    
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    return topViewController;
}

@end
