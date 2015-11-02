//
//  DragDropController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropController.h"
#import "DragInteractionView.h"
#import "DragAndDropView.h"
#import "Drag.h"


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

- (BOOL)dragStarted:(Drag *)drag {

    if ([self.dragDropDataSource dragDropController:self shouldDragView:drag.view]){
        self.isDragging = YES;
        self.isDropping = NO;

        drag.dragRepresentation.frame = [self.dragInteractionView convertRect:drag.view.frame fromView:drag.view.superview];
        [self.dragInteractionView addSubview:drag.dragRepresentation];

        [UIView animateWithDuration:kDragDropPickupAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                                 [self.dragDropDelegate dragDropController:self willStartDrag:drag animated:YES];
                         }
                         completion:^ (BOOL finished){
                             [self.dragDropDelegate dragDropController:self didStartDrag:drag];
                         }];
        
        return YES;
    }
    
    return NO;
}

- (void)dragMoved:(Drag *)drag {
    if (!self.isDragging) return;
    
    CGPoint location = drag.currentLocation;
    UIView *subview = [self.dragInteractionView hitTest:location withEvent:nil];
    
    if (subview) {
        
        [self.dragDropDelegate dragDropController:self
                                   isDraggingView:drag.view
                                          atPoint:location];
        
        CGPoint adjustmentForTransform = CGPointZero;
        
        if (CGAffineTransformEqualToTransform(drag.dragRepresentation.transform, CGAffineTransformIdentity) == NO) {
            
            CGRect r = CGRectApplyAffineTransform(drag.view.frame, drag.dragRepresentation.transform);
            
            adjustmentForTransform = CGPointMake((r.size.width - CGRectGetWidth(drag.view.frame)) / 2,
                                                 (r.size.height - CGRectGetHeight(drag.view.frame)) / 2);
        }
        
        CGRect updatedFrame = CGRectMake(location.x - drag.firstTouchOffset.x - adjustmentForTransform.x,
                                         location.y - drag.firstTouchOffset.y - adjustmentForTransform.y,
                                         subview.frame.size.width,
                                         subview.frame.size.height);;
        
        subview.frame = updatedFrame;
    }
    
}

- (void)dragEnded:(Drag *)drag {

    if (!self.isDragging) return;
    self.isDropping = YES;

    CGRect firstStepFrame = CGRectZero;
    CGRect secondStepFrame = CGRectZero;
    void (^animationCompletionBlock)(BOOL) = NULL;
    __weak DragDropController *this = self;
    
    DragDropController *dropDestination = [self controllerForDropAtPoint:drag.currentLocation];

    if (dropDestination && [self.dragDropDataSource dragDropController:self
                                                           canDropView:drag.view
                                                         toDestination:dropDestination]) {
        
        // call the datasource and have them return the proper frames
        firstStepFrame = [self.dragDropDataSource dragDropController:self
                                                        frameForView:drag.view
                                                       inDestination:dropDestination];
        
        secondStepFrame = firstStepFrame;
        firstStepFrame = [dropDestination.view convertRect:firstStepFrame toView:nil];

        animationCompletionBlock = ^ (BOOL finished){
            this.isDragging = NO;
            this.isDropping = NO;
            
            drag.view.frame = [dropDestination.view convertRect:secondStepFrame toView:dropDestination.view];
            [dropDestination.view addSubview:drag.view];

            drag.view.dragDropController = dropDestination;
            [this.dragDropDelegate dragDropController:this didMoveView:drag.view toDestination:dropDestination];
        };
        
    }
    else {
        
        firstStepFrame = [drag.view.superview convertRect:drag.view.frame toView:self.dragInteractionView];

        animationCompletionBlock = ^ (BOOL finished){
            this.isDragging = NO;
            this.isDropping = NO;
        };
    }
    
    void (^commonCompletionBlock)(BOOL) = ^(BOOL finished){
    
        [this.dragDropDelegate dragDropController:this didEndDrag:drag];
        
        [drag.dragRepresentation removeFromSuperview];
        drag.dragRepresentation = nil;
        
        [_dragInteractionView removeFromSuperview];
        _dragInteractionView = nil;
    };

    
    [UIView animateWithDuration: kDropAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{

                         drag.dragRepresentation.frame = firstStepFrame;
                         [self.dragDropDelegate dragDropController:self
                                                       willEndDrag:drag
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
    NSMutableArray *controllers = [NSMutableArray array];

    for (DragDropController *dragDropController in [[DragDropControllerManager sharedInstance] allControllers]) {
//        CGRect r = [dragDropController.view convertRect:dragDropController.view.frame toView:self.dragInteractionView];
//        CGPoint p = [self.dragInteractionView convertPoint:point toView:nil];
        CGRect r = [dragDropController.view convertRect:dragDropController.view.bounds toView:self.dragInteractionView];
        CGPoint p = point;//[dragDropController.view convertPoint:point toView:dragDropController.view];
        
        NSLog(@"p: %@", NSStringFromCGPoint(p));
        NSLog(@"r: %@", NSStringFromCGRect(r));
        NSLog(@"-----");
        // works when embedded in subview...
//        r = [self.dragInteractionView convertRect:r fromView:dragDropController.view];
        
        // works when side by side views...
//        r = [self.dragInteractionView convertRect:r toView:self.dragInteractionView];

//        NSLog(@"r: %@", NSStringFromCGRect(r));

        if (CGRectContainsPoint(r, p)) {
            [controllers addObject:dragDropController];
        }
    }

    if (controllers.count > 0) {
        if (controllers.count == 1) {
            controller = [controllers firstObject];
        }
        else {
            for (DragDropController *c in controllers) {
                for (DragDropController *innerC in controllers) {
                    if ([innerC.view isDescendantOfView:c.view]){
                        controller = innerC;
                        break;
                    }
                }
            }
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
