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
@property (nonatomic, weak) UIView *dragRepresentation; // this is the dragging representation of the view.

@property (nonatomic, assign) CGRect frame;             // this is the views frame in its original superviews coordinate.
@property (nonatomic, assign) CGPoint currentLocation;  // this is the current position of the view as it is being dragged.
@property (nonatomic, assign) CGPoint firstTouchOffset; // the offset (in the views coordinates) of the touch that started the drag.

@end