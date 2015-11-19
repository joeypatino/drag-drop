//
//  NSIndexPath+Additions.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/19/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "NSIndexPath+Additions.h"

@implementation NSIndexPath (Additions)
- (BOOL)isBetweenIndexPath:(NSIndexPath *)indexPath1 andIndexPath:(NSIndexPath *)indexPath2 {
    NSComparisonResult toResult = [self compare:indexPath1];
    NSComparisonResult fromResult = [self compare:indexPath2];
    return (toResult == NSOrderedDescending && fromResult == NSOrderedAscending);
}

- (BOOL)isBeforeIndexPath:(NSIndexPath *)indexPath {
    return ([self compare:indexPath] == NSOrderedAscending);
}

- (BOOL)isAfterIndexPath:(NSIndexPath *)indexPath {
    return ([self compare:indexPath] == NSOrderedDescending);
}

- (BOOL)isIndexPath:(NSIndexPath *)indexPath {
    return ([self compare:indexPath] == NSOrderedSame);
}

- (NSIndexPath *)indexPathByIncrementingRow {
    return [NSIndexPath indexPathForRow:self.row + 1 inSection:self.section];
}

- (NSIndexPath *)indexPathByDecrementingRow {
    return [NSIndexPath indexPathForRow:self.row - 1 inSection:self.section];
}

@end
