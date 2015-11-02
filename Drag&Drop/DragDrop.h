//
//  DragDrop.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DragDrop : NSObject
@property (nonatomic, weak) UIView *view;
@property (nonatomic, weak) UIView *dragRepresentation;
@property (nonatomic, weak) UIView *dragDropTarget;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGPoint currentLocation;

@end


/*
 UIView *view;                  // this is the IconView instance.
 UIView *dragRepresentation;    // this is the dragging representation view.
 UIView *dragDropTarget;        // this view is set once the view is dropped. it is the view that baseView will move to.
 
 CGRect frame;                  // this is the views frame in its original superviews coordinate
 CGPoint currentLocation;       // this is the current position of the dragging view.
 
 */
