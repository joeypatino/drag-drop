//
//  ExamplesTableViewController.m
//  Drag&Drop
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

#import "ExamplesTableViewController.h"

@interface ExamplesTableViewController ()
@property (nonatomic, strong) NSDictionary *examplesDictionary;
@end

@implementation ExamplesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ExampleCell"];
    self.examplesDictionary = @{@"titles": @[
                                        @"4x4",
                                        @"Container-Embedded",
                                        @"Container-2xEmbedded",
                                        @"Drop Target Embedded",
                                        @"Table View",
                                        @"Collection View"
                                        ],
                                @"segues":@[
                                        @"_x4ViewController",
                                        @"EmbeddedViewController",
                                        @"DoubleEmbeddedViewController",
                                        @"EmbeddedDropTargetViewController",
                                        @"NormalTableViewController",
                                        @"NormalCollectionViewController"
                                        ]};
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray *)self.examplesDictionary[@"titles"] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = [(NSArray *)self.examplesDictionary[@"titles"] objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExampleCell" forIndexPath:indexPath];
    cell.textLabel.text = title;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *segueName = [(NSArray *)self.examplesDictionary[@"segues"] objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:segueName sender:nil];
}

@end
