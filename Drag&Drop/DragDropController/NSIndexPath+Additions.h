//
//  NSIndexPath+Additions.h
//  Drag&Drop
//
//  Created by Joey Patino on 11/19/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSIndexPath (Additions)
- (NSIndexPath *)indexPathByIncrementingRow;
- (NSIndexPath *)indexPathByDecrementingRow;

- (BOOL)isBetweenIndexPath:(NSIndexPath *)indexPath1 andIndexPath:(NSIndexPath *)indexPath2;
- (BOOL)isBeforeIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isAfterIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isIndexPath:(NSIndexPath *)indexPath;
@end
