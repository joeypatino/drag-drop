//
//  DragDropGesture.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/3/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface DragDropGesture : UIGestureRecognizer
@property (nonatomic, assign, readonly) CGPoint touchBeginOffset;
@property (nonatomic, assign) NSTimeInterval gestureBeginDelay;
@property (nonatomic, weak) UIView *dragRepresentation;

@end
