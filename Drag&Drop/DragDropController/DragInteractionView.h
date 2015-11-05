//
//  DragInteractionView.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/2/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef UIView* (^HitTestBlock)(CGPoint, UIEvent *);
@interface DragInteractionView : UIView
@property (nonatomic, copy) HitTestBlock hitTest;
@end