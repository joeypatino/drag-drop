//
//  DragDrop.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragAction.h"

@interface DragAction ()
@property (nonatomic, assign) CGRect frame;     // this is the views frame in its original superviews coordinate.
@end

@implementation DragAction

+ (DragAction *)dragActionWithView:(UIView *)view {
    DragAction *drag = [[DragAction alloc] init];
    drag.view    = view;
    drag.frame = view.frame;
    return drag;
}

@end
