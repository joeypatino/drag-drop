//
//  DragInteractionView.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/2/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragInteractionView.h"

@implementation DragInteractionView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (self.hitTest) {
        UIView *hitView = self.hitTest(point, event);
        if (hitView) return hitView;
    }

    return [super hitTest:point withEvent:event];
}
@end
