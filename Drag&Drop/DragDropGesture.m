//
//  DragDropGesture.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/3/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragDropGesture.h"

@interface DragDropGesture ()
@property (nonatomic, assign) NSTimeInterval diff;
@property (nonatomic, assign) CGPoint start;
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
    self.diff = event.timestamp;
    self.start = [[touches anyObject] locationInView:nil];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    NSTimeInterval i = event.timestamp - self.diff;
    if (self.state == UIGestureRecognizerStatePossible) {
        if (i > self.gestureBeginDelay) {
            self.state = UIGestureRecognizerStateBegan;
        }
        else {
            self.state = UIGestureRecognizerStateFailed;
        }
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
    self.diff = 0;
    self.state = UIGestureRecognizerStatePossible;
}

@end
