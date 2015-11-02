//
//  DragView.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DragDropController.h"

@interface DragView : UIView
@property (nonatomic, weak) DragDropController *dragDropController;
@end
