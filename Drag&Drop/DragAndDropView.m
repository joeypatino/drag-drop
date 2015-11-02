//
//  DragView.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "DragAndDropView.h"
#import "Drag.h"

@interface DragAndDropView ()
@property (nonatomic, assign) BOOL isDragging;
@property (nonatomic, strong) UIView *dragRepresentationView;
@property (nonatomic, assign) CGPoint firstTouchOffset;
@end

@implementation DragAndDropView

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
        _dragRepresentationView.backgroundColor = [UIColor redColor];
        _dragRepresentationView.hidden = YES;
        [self addSubview:_dragRepresentationView];
    }
    
    return _dragRepresentationView;
}

- (Drag *)dragForTouch:(UITouch *)touch {
    
    Drag *d = [[Drag alloc] init];
    d.view = self;
    d.dragRepresentation = self.dragRepresentationView;
    
    d.frame = self.frame;
    d.currentLocation = [touch locationInView:nil];
    d.firstTouchOffset = self.firstTouchOffset;
    
    return d;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (![self canDrag]) return;
    self.isDragging = YES;
    
    Drag *d = [[Drag alloc] init];
    d.view = self;
    d.dragRepresentation = self.dragRepresentationView;

    d.frame = self.frame;
    d.currentLocation = [[touches anyObject] locationInView:self];
    self.firstTouchOffset = d.currentLocation;
    
    BOOL startedDrag = [self.dragDropController dragStarted:d];
    self.dragRepresentationView.hidden = !startedDrag;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (![self canDrag]) return;
    
    [self.dragDropController dragMoved:[self dragForTouch:[touches anyObject]]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if (![self canDrag]) return;
    
    [self.dragDropController dragEnded:[self dragForTouch:[touches anyObject]]];
    self.isDragging = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (BOOL)canDrag {
    return YES;
}

@end
