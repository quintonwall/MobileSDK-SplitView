//
//  MasterViewController.h
//  Cloudstock3
//
//  Created by Quinton Wall on 3/9/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFRestAPI.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <SFRestDelegate>
{
    
    NSMutableArray *dataRows;
    IBOutlet UITableView *tableView;    
	
}

@property (nonatomic, retain) NSArray *dataRows;

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
