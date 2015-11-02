//
//  DragDropController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "UIViewController+TopMostController.h"
#import "DragDropController.h"
#import "DragDrop.h"


typedef UIView * (^HitTestBlock)(CGPoint, UIEvent *);
@interface DragInteractionView : UIView
@property (nonatomic, copy) HitTestBlock hitTest;
@end

@implementation DragInteractionView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (self.hitTest) {
        UIView *hitView = self.hitTest(point, event);
        if (hitView) return hitView;
    }
    
    return [super hitTest:point withEvent:event];
}

@end


@interface DragDropController ()
@property (nonatomic, strong, readwrite) DragInteractionView *dragInteractionView;
@property (nonatomic, assign) CGPoint firstTouchOffset;
@end

@implementation DragDropController

- (DragInteractionView *)dragInteractionView {
    
    if (!_dragInteractionView) {
        
        UIViewController *top = [UIViewController topMostController];
        __weak DragDropController *this = self;
        _dragInteractionView = [[DragInteractionView alloc] initWithFrame:top.view.frame];
        [(DragInteractionView *)_dragInteractionView setHitTest: ^(CGPoint point, UIEvent *event){
            
            UIView *hitView = nil;
            for (UIView *subview in this.dragInteractionView.subviews) {
                hitView = subview;
            }
            
            if (hitView) [this.dragDropDelegate dragDropController:this
                                                 isDraggingAtPoint:point];
            
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

- (void)dragDropStarted:(DragDrop *)dd {
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if ([self.dragDropDataSource dragDropController:self
                                     shouldDragView:dd.view]){
        self.isDragging = YES;
        self.isDropping = NO;
        
        self.firstTouchOffset = dd.currentLocation;

//        dd.frame = [self.dragInteractionView convertRect:dd.view.frame fromView:dd.view.superview];
        dd.dragRepresentation.frame = dd.frame;
        [self.dragInteractionView addSubview:dd.dragRepresentation];
        
        [UIView animateWithDuration:kDragDropPickupAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             [self.dragDropDelegate dragDropController:self
                                                         willStartDrag:dd
                                                              animated:YES];
                         }
                         completion:^ (BOOL finished){
                             [self.dragDropDelegate dragDropController:self
                                                          didStartDrag:dd];
                         }];
    }
}

- (void)dragDropMoved:(DragDrop *)dd {
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
    

    CGPoint location = dd.currentLocation;
    UIView *subview = [self.dragInteractionView hitTest:location
                                                  withEvent:nil];
    
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
        
        CGRect updatedFrame = CGRectMake(location.x - self.firstTouchOffset.x - adjustmentForTransform.x, location.y - self.firstTouchOffset.y - adjustmentForTransform.y,
                                         subview.frame.size.width, subview.frame.size.height);;
        
        subview.frame = updatedFrame;
    }
    
}

- (void)dragDropEnded:(DragDrop *)dd {
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.isDropping = YES;
    
    UIView *dragDropDestination = [self.dragDropDataSource dragDropController:self
                                                          dropRecieverAtPoint:dd.currentLocation];

    
    DragDrop *drop = [[DragDrop alloc] init];
    drop.view = dd.view;
    drop.dragRepresentation = dd.dragRepresentation;
    drop.currentLocation = dd.currentLocation;
    drop.dragDropTarget = dragDropDestination;
    
    CGRect firstStepFrame = CGRectZero;
    //    CGRect secondStepFrame = CGRectZero;
    void (^animationCompletionBlock)(BOOL) = NULL;
    
    // there are two cases here.
    if ([self.dragDropDataSource dragDropController:self
                                     shouldDropView:drop.view
                                             ToView:drop.dragDropTarget]) {
        
        // call the datasource and have them return the proper frames
        firstStepFrame = [self.dragDropDataSource dragDropController:self
                                                        frameForView:drop.view
                                             animatingToNewSuperView:drop.dragDropTarget];
        
        //        secondStepFrame = [self.dragDropDataSource dragDropController:self
        //                                                         frameForView:drop.view
        //                                                       inNewSuperView:drop.dragDropTarget];
        
        animationCompletionBlock = ^ (BOOL finished){
            self.isDragging = NO;
            self.isDropping = NO;
            
            [drop.dragDropTarget addSubview:drop.dragRepresentation];
            
            [self.dragDropDelegate dragDropController:self isMovingView:drop.view
                                       toNewSuperView:drop.dragDropTarget];
            [self.dragDropDelegate dragDropController:self didEndDrag:drop];
        };
        
    }
    else {
        
        firstStepFrame = [drop.view.superview convertRect:drop.view.frame
                                                   toView:self.dragInteractionView];
        //        secondStepFrame = drop.view.bounds;
        
        animationCompletionBlock = ^ (BOOL finished){
            self.isDragging = NO;
            self.isDropping = NO;
            
            [self.dragDropDelegate dragDropController:self didEndDrag:drop];
            
            [drop.dragRepresentation removeFromSuperview];
            drop.dragRepresentation = nil;

            [_dragInteractionView removeFromSuperview];
            _dragInteractionView = nil;
        };
    }
    
    [UIView animateWithDuration:kDropAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         // firstStepFrame
                         
                         drop.dragRepresentation.frame = firstStepFrame;
                         [self.dragDropDelegate dragDropController:self
                                                       willEndDrag:drop
                                                          animated:YES];
                         
                     }
                     completion:animationCompletionBlock];
    
}



@end
