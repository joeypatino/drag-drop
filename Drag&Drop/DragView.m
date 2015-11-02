//
//  DragView.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragView.h"
#import "DragDrop.h"

@interface DragView ()
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, strong) UIView *dragRepresentationView;
@end

@implementation DragView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self commonInit];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self commonInit];
    return self;
}

- (void)commonInit {

}

- (UIView *)dragRepresentationView {
    
    if (!_dragRepresentationView) {
        _dragRepresentationView = [[UIView alloc] initWithFrame:self.bounds];
        _dragRepresentationView.backgroundColor = [UIColor yellowColor];
        _dragRepresentationView.hidden = YES;
        [self addSubview:_dragRepresentationView];
    }
    
    return _dragRepresentationView;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (![self canDrag]) return;
    self.isDragging = YES;
    
    DragDrop *d = [[DragDrop alloc] init];
    d.view = self;
    d.dragRepresentation = self.dragRepresentationView;

    d.currentLocation = [[touches anyObject] locationInView:self];
    d.frame = [self.dragDropController.dragInteractionView convertRect:self.frame fromView:self.superview];
    
    self.dragRepresentationView.hidden = NO;
    [self.dragDropController dragDropStarted:d];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (![self canDrag]) return;
    
    DragDrop *d = [[DragDrop alloc] init];
    d.view = self;
    d.dragRepresentation = self.dragRepresentationView;
    
    d.frame = self.frame;
    
    NSLog(@"S.D.D: %@", NSStringFromCGPoint([[touches anyObject] locationInView:self.dragDropController.dragInteractionView]));
    NSLog(@"NIL: %@", NSStringFromCGPoint([[touches anyObject] locationInView:nil]));
    
    d.currentLocation = [[touches anyObject] locationInView:self.dragDropController.dragInteractionView];
    
    [self.dragDropController dragDropMoved:d];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (![self canDrag]) return;
    
    DragDrop *d = [[DragDrop alloc] init];
    d.view = self;
    d.dragRepresentation = self.dragRepresentationView;
    
    d.frame = self.frame;
    d.currentLocation = [[touches anyObject] locationInView:self.dragDropController.dragInteractionView];
    
    [self.dragDropController dragDropEnded:d];
    self.isDragging = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (![self canDrag]) return;
    
    DragDrop *d = [[DragDrop alloc] init];
    d.view = self;
    d.dragRepresentation = self.dragRepresentationView;
    
    d.frame = self.frame;
    d.currentLocation = [[touches anyObject] locationInView:self.dragDropController.dragInteractionView];
    
    [self.dragDropController dragDropEnded:d];
    self.isDragging = NO;
}

- (BOOL)canDrag {
    return YES;
}

- (BOOL)beingDragged {
    return self.isDragging;
}

@end
