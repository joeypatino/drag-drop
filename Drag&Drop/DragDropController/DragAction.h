//
//  DragDrop.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DragAction : NSObject
@property (nonatomic, weak) UIView *view;               // this is the view that is being dragged.

@property (nonatomic, assign) CGPoint currentLocation;  // this is the current position of the view as it is being dragged.
@property (nonatomic, assign) CGPoint firstTouchOffset; // the offset (in the views coordinates) of the touch that started the drag.

+ (DragAction *)dragActionWithView:(UIView *)view;

@end