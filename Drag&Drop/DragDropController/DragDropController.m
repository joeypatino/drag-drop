//
//  DragDropController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropController.h"
#import "DragInteractionView.h"
#import "DragAction.h"
#import "DragDropGesture.h"

#pragma mark - DragDropControllerManager

/*
 * DragDropControllerManager automatically tracks all created DragDropControllers
 * You should not use this class yourself, but the DragDropController uses this internally.
 */
@interface DragDropControllerManager : NSObject
@property (nonatomic, strong) NSMutableArray *dragDropControllers;
+ (DragDropControllerManager *)sharedInstance;
- (void)addDragDropController:(DragDropController *)controller;
- (void)removeDragDropController:(DragDropController *)controller;
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

#pragma mark -

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

#pragma mark -

- (NSArray *)allControllers {
    return [NSArray arrayWithArray:self.dragDropControllers];
}

#pragma mark -

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
@property (nonatomic, strong) DragInteractionView *dragInteractionView; // the view that our drag representations are translated across.
@property (nonatomic, weak) DragDropController *currentDragDestination; // populated when the drag operation is above a drop target. otherwise nil
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isDropping;

- (BOOL)startDrag:(DragAction *)drag;   // Returns YES if the drag was successfuly started.. Otherwise returns NO.
- (void)dragMoved:(DragAction *)drag;
- (void)endDrag:(DragAction *)drag;

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

- (void)enableDragActionForView:(UIView *)view {
    
    // The DragDropGesture is responsible for translating the view across the screen in response to the users touch
    DragDropGesture *gest = [[DragDropGesture alloc] initWithTarget:self action:@selector(handleDragDropGesture:)];
    [view addGestureRecognizer:gest];
    
    // Add a delay on the gesture begin when embedded in a tableview, or tableview cell.
    // This prevents the table from scrolling before the drag has begun..
    UIView *tv = [self scrollingSuperViewOfView:view];
    if (tv) gest.gestureBeginDelay = kDragPickupBeginDelay;
    
}

- (void)disableDragActionForView:(UIView *)view {
    
    // Remove any existing drag gestures.
    NSMutableArray *dragAndDrop = [NSMutableArray array];
    for (UIGestureRecognizer *r in [view gestureRecognizers]){
        [dragAndDrop addObject:r];
    }
    
    for (UIGestureRecognizer *r in dragAndDrop) {
        [view removeGestureRecognizer:r];
    }
}

#pragma mark -

- (void)handleDragDropGesture:(DragDropGesture *)gesture {
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self touchBegan:gesture];
            break;
        case UIGestureRecognizerStateChanged:
            [self touchMoved:gesture];
            break;
        case UIGestureRecognizerStateEnded:
            [self touchEnded:gesture];
            break;
        case UIGestureRecognizerStateCancelled:
            [self touchEnded:gesture];
            break;
        default:
            break;
    }
}

- (void)touchBegan:(DragDropGesture *)gesture {
    DragAction *d = [DragAction dragActionWithView:gesture.view];
    
    // On the start of the drag, we should create a drag representation view..
    // this is done through our datasouce.
    d.dragRepresentation = [self dragRepresentationViewForDrag:d];

    // we store the drag representation on the gesture, then
    // on gesture moved, we can grab the drag representation view
    // and translate it across the screen..
    gesture.dragRepresentation = d.dragRepresentation;
    

    BOOL startedDrag = [self startDrag:d];
    d.dragRepresentation.hidden = !startedDrag;
}

- (void)touchMoved:(DragDropGesture *)gesture {
    [self dragMoved:[self dragWithGesture:gesture]];
}

- (void)touchEnded:(DragDropGesture *)gesture {
    [self endDrag:[self dragWithGesture:gesture]];
}

// Helper method to create DragAction on touch move/end
- (DragAction *)dragWithGesture:(DragDropGesture *)gesture {

    DragAction *d = [DragAction dragActionWithView:gesture.view];

    // Set the drags current location to the location of the drag in the window's coordinates..
    d.currentLocation = [gesture locationInView:nil];
    
    // Copy over the existing drag representation from the drag.
    // This was originally created when the drag began.
    d.dragRepresentation = gesture.dragRepresentation;
    
    // Copy over the existing drag touch begin offset
    // This was originally set when the drag began.
    d.firstTouchOffset = gesture.touchBeginOffset;
    
    return d;
}

#pragma mark -

// Loads the Drag representation from the datasource.
- (UIView *)dragRepresentationViewForDrag:(DragAction *)drag {
    
    UIView *dragView = [self.dragDropDataSource dragDropController:self dragRepresentationForView:drag.view];
    
    // start with the drag representation hidden, it will
    // unhide when/if the drag starts
    dragView.hidden = YES;
    [drag.view addSubview:dragView];
    
    return dragView;
}

#pragma mark -

- (BOOL)startDrag:(DragAction *)drag {
    if (self.isDragging || self.isDropping) return NO;
    
    // make sure the datasource allows dragging this view..
    // This check allows the datasource to have more granular control
    BOOL canDrag =
    ([self.dragDropDataSource respondsToSelector:@selector(dragDropController:shouldDragView:)])
    ? [self.dragDropDataSource dragDropController:self shouldDragView:drag.view]
    : YES;
    
    if (canDrag){
        self.isDragging = YES;
        self.isDropping = NO;
        
        // convert the drag representation's frame to our interaction view,
        // then add it as a subview.
        
        // All drag movement actually occurs on the interaction view..
        drag.dragRepresentation.frame = [self.dragInteractionView convertRect:drag.view.frame fromView:drag.view.superview];
        [self.dragInteractionView addSubview:drag.dragRepresentation];
        
        // Allow the delegate to respond to the start of the drag sequence.
        [UIView animateWithDuration:kDragDropPickupAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             if ([self.dragDropDataSource respondsToSelector:@selector(dragDropController:willStartDrag:animated:)])
                                 [self.dragDropDelegate dragDropController:self willStartDrag:drag animated:YES];
                         }
                         completion:^ (BOOL finished){
                             
                             // In case we have already dropped the view....
                             if (self.isDragging && !self.isDropping) {
                                 // if not, notify the delgate that the start of the drag has begun..
                                 if ([self.dragDropDataSource respondsToSelector:@selector(dragDropController:didStartDrag:)])
                                     [self.dragDropDelegate dragDropController:self didStartDrag:drag];
                             }
                         }];
        
        // return yes for a successful drag start..
        return YES;
    }
    
    
    // return no if the drag start did not succeed.
    return NO;
}

- (void)dragMoved:(DragAction *)drag {
    if (!self.isDragging || self.isDropping) return;
    
    CGPoint location = drag.currentLocation;
    
    // look for a draggable view within our drag interaction view. If one is not found, then something is wrong..
    UIView *subview = [self.dragInteractionView hitTest:location withEvent:nil];
    if (subview) {
        
        // notify any drop targets that the drag is occuring..
        [self notifyDropTarget:[self controllerForDropAtPoint:drag.currentLocation] ofDragAction:drag];
        
        CGPoint adjustmentForTransform = CGPointZero;
        
        
        // Apply an additional adjustment if the frame of our drag representation has been transformed.
        // This is non standard. It is added since the typical style when dragging and dropping is to scale
        // the view when it's picked up. I thinkk this only works for scale and transform
        if (CGAffineTransformEqualToTransform(drag.dragRepresentation.transform, CGAffineTransformIdentity) == NO) {
            
            CGRect r = CGRectApplyAffineTransform(drag.view.frame, drag.dragRepresentation.transform);
            
            adjustmentForTransform = CGPointMake((r.size.width - CGRectGetWidth(drag.view.frame)) / 2,
                                                 (r.size.height - CGRectGetHeight(drag.view.frame)) / 2);
        }
        
        
        // udpate the frame of the drag representation view based on the new location,
        // the adjustment above, and the offset of where we first touched the view.
        subview.frame = CGRectMake(location.x - drag.firstTouchOffset.x - adjustmentForTransform.x,
                                   location.y - drag.firstTouchOffset.y - adjustmentForTransform.y,
                                   subview.frame.size.width,
                                   subview.frame.size.height);
    }
    
}

- (void)endDrag:(DragAction *)drag {
    if (!self.isDragging || self.isDropping) return;
    self.isDropping = YES;
    
    CGRect firstStepFrame = CGRectZero;
    CGRect secondStepFrame = CGRectZero;
    void (^animationCompletionBlock)(BOOL) = NULL;
    __weak DragDropController *this = self;
    
    // Look for a dropTarget at our current drag location.
    DragDropController *dropDestination = [self controllerForDropAtPoint:drag.currentLocation];
    
    // Check if we can drop to the found reciever. The default behaviour is YES.
    BOOL canDrop =
    ([self.dragDropDataSource respondsToSelector:@selector(dragDropController:canDropView:toDestination:)])
    ? [self.dragDropDataSource dragDropController:self canDropView:drag.view toDestination:dropDestination]
    : YES;
    
    if (dropDestination && canDrop) {
        // In this case, we are moving the view to a different superview,
        // and to a different DragDropController.. Take the nesessary steps....
        
        // call the datasource and have them return the proper frames
        firstStepFrame = [self.dragDropDataSource dragDropController:self
                                                        frameForView:drag.view
                                                       inDestination:dropDestination];
        
        
        // The correct frame for the view in it's new superviews coordinates
        secondStepFrame = firstStepFrame;
        
        // The correct frame but adjusted to be in the current drag interaction views coordinates.
        // Used to animate the drag representation..
        firstStepFrame = [dropDestination.dropTargetView convertRect:firstStepFrame toView:nil];
        
        
        // After animating the drag representation view..
        animationCompletionBlock = ^ (BOOL finished){
            this.isDragging = NO;
            this.isDropping = NO;
            
            // when the animation of the drag representation view is complete,
            // set the real view's frame to that specified by our datasource,
            // andn then add the view as a subview.
            drag.view.frame = [dropDestination.dropTargetView convertRect:secondStepFrame toView:dropDestination.dropTargetView];
            [dropDestination.dropTargetView addSubview:drag.view];
            
            // now that the view belongs to another DragDropController,
            // we also should hand over responsiblity of drag/drop operations
            [self disableDragActionForView:drag.view];
            [dropDestination enableDragActionForView:drag.view];
            
            // and notify the delegate if they are listening..
            if ([this.dragDropDelegate respondsToSelector:@selector(dragDropController:didMoveView:toDestination:)])
                [this.dragDropDelegate dragDropController:this didMoveView:drag.view toDestination:dropDestination];
        };
        
    }
    else {
        // Here we are just animating the view back to it's original spot. No other changes take place..

        // the frame for the view is just it's original frame..
        firstStepFrame = [drag.view.superview convertRect:drag.view.frame toView:self.dragInteractionView];
        
        // After animating the drag representation view back to it's spot..
        animationCompletionBlock = ^ (BOOL finished){
            this.isDragging = NO;
            this.isDropping = NO;
        };
    }
    
    [self notifyDropTarget:nil ofDragAction:drag];
    [UIView animateWithDuration: kDropAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         // set the frame..
                         drag.dragRepresentation.frame = firstStepFrame;
                         
                         // notify the delegate if they are listening..
                         if ([self.dragDropDelegate respondsToSelector:@selector(dragDropController:willEndDrag:animated:)])
                             [self.dragDropDelegate dragDropController:self willEndDrag:drag animated:YES];
                     }
                     completion:^(BOOL finished){
                         
                         // call the animation complete block we set above..
                         if (animationCompletionBlock)
                             animationCompletionBlock(finished);
                         
                         // notify the delegate if they are listening..
                         if ([self.dragDropDelegate respondsToSelector:@selector(dragDropController:didEndDrag:)])
                             [self.dragDropDelegate dragDropController:self didEndDrag:drag];
                         
                         // On completion of a drag action we should clean up our mess.. this means..
                         
                         // remove the drag representation view..
                         [drag.dragRepresentation removeFromSuperview];
                         drag.dragRepresentation = nil;
                         
                         // and remove our drag interaction view since it's purpose is now fulfilled..
                         [_dragInteractionView removeFromSuperview];
                         _dragInteractionView = nil;
                     }];
    
}

#pragma mark - Helpers

- (void)notifyDropTarget:(DragDropController *)dropTarget ofDragAction:(DragAction *)drag {
    // Notifys the datasource when we start, continue, or end dragging above a valid dropTargetView.
    
    if (self.currentDragDestination && [self.currentDragDestination isEqual:dropTarget]) {
        
        CGPoint p = [dropTarget.dropTargetView convertPoint:drag.currentLocation fromView:nil];
        
        if ([self.dragDropDelegate respondsToSelector:@selector(dragDropController:isDraggingView:atLocation:withDestination:)]) {
            [self.dragDropDelegate dragDropController:self
                                       isDraggingView:drag.view
                                           atLocation:p
                                      withDestination:self.currentDragDestination];
        }
    }
    else {
        
        if (self.currentDragDestination) {
            CGPoint p = [self.currentDragDestination.dropTargetView convertPoint:drag.currentLocation fromView:nil];
            
            if ([self.dragDropDelegate respondsToSelector:@selector(dragDropController:didEndDraggingView:atLocation:withDestination:)]) {
                [self.dragDropDelegate dragDropController:self
                                       didEndDraggingView:drag.view
                                               atLocation:p
                                          withDestination:self.currentDragDestination];
            }
            
            self.currentDragDestination = nil;
        }
        
        if (dropTarget) {
            self.currentDragDestination = dropTarget;
            
            CGPoint p = [dropTarget.dropTargetView convertPoint:drag.currentLocation fromView:nil];
            
            if ([self.dragDropDelegate respondsToSelector:@selector(dragDropController:didStartDraggingView:atLocation:withDestination:)]) {
                [self.dragDropDelegate dragDropController:self
                                     didStartDraggingView:drag.view
                                               atLocation:p
                                          withDestination:self.currentDragDestination];
            }
        }
    }
}

#pragma mark -

- (DragDropController *)controllerForDropAtPoint:(CGPoint)point {
    // Looks for a valid dropTarget at the specified point..
    
    DragDropController *controller = nil;
    NSMutableArray *controllers = [NSMutableArray array];
    
    for (DragDropController *dragDropController in [[DragDropControllerManager sharedInstance] allControllers]) {
        
        CGRect r = [dragDropController.dropTargetView convertRect:dragDropController.dropTargetView.bounds toView:self.dragInteractionView];
        if (CGRectContainsPoint(r, point)) {
            [controllers addObject:dragDropController];
        }
    }
    
    if (controllers.count > 0) {
        if (controllers.count == 1) {
            controller = [controllers firstObject];
        }
        else {
            // when we have more than one available, we should give the inner most one priority
            
            for (DragDropController *c in controllers) {
                for (DragDropController *innerC in controllers) {
                    if ([innerC.dropTargetView isDescendantOfView:c.dropTargetView]){
                        controller = innerC;
                        break;
                    }
                }
            }
        }
    }
    
    return controller;
}

- (UIView *)scrollingSuperViewOfView:(UIView *)view {

    if ([view isKindOfClass:[UITableView class]] || [view isKindOfClass:[UICollectionView class]] ||
        [view isKindOfClass:[UITableViewCell class]] || [view isKindOfClass:[UICollectionViewCell class]] ||
        [view isKindOfClass:[UIScrollView class]]){
        return view;
    }
    
    if (!view.superview) return nil;
    
    return [self scrollingSuperViewOfView:view.superview];
}

#pragma mark -

- (DragInteractionView *)dragInteractionView {
    
    if (!_dragInteractionView) {
        
        UIViewController *top = [DragDropController topMostViewController];
        __weak DragDropController *this = self;
        _dragInteractionView = [[DragInteractionView alloc] initWithFrame:top.view.frame];
        [_dragInteractionView setHitTest: ^(CGPoint point, UIEvent *event){
            
            UIView *hitView = nil;
            for (UIView *subview in this.dragInteractionView.subviews) {
                hitView = subview;
            }
            
            return hitView;
        }];
        
        [top.view addSubview:_dragInteractionView];
    }
    
    return _dragInteractionView;
}

+ (UIViewController *)topMostViewController {
    
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    return topViewController;
}

@end
