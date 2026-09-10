//
//  DragDropGesture.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/3/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropGesture.h"

@interface DragDropGesture ()
@property (nonatomic, assign, readwrite) CGPoint touchBeginOffset;
@property (nonatomic, assign) NSTimeInterval touchBeginTimestamp;
@end
@implementation DragDropGesture

- (id)initWithTarget:(id)target action:(SEL)action {
    self = [super initWithTarget:target action:action];
    self.gestureBeginDelay = 0;
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    self.state = UIGestureRecognizerStatePossible;
    self.touchBeginTimestamp = event.timestamp;
    self.touchBeginOffset = [self locationInView:self.view];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    NSTimeInterval touchMoveDelay = event.timestamp - self.touchBeginTimestamp;
    
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = (touchMoveDelay > self.gestureBeginDelay)
        ? UIGestureRecognizerStateBegan
        : UIGestureRecognizerStateFailed;
    }
    else {
        self.state = UIGestureRecognizerStateChanged;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset {
    self.touchBeginTimestamp = 0;
    self.state = UIGestureRecognizerStatePossible;
}

@end
