//
//  DetailViewController.h
//  Cloudstock3
//
//  Created by Quinton Wall on 3/9/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFRestAPI.h"

@interface DetailViewController : UIViewController <SFRestDelegate, UISplitViewControllerDelegate, UITableViewDelegate> 

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) NSString *detailDescription;
@property (strong, nonatomic) NSString *detailName;
@property (strong, nonatomic) NSString *detailPrice;
@property (strong, nonatomic) NSString *detailInventory;
@property (strong, nonatomic) NSString *detailVendor;
@property (strong, nonatomic) NSString *detailYear;

@property (retain, nonatomic) IBOutlet UILabel *lblName;
@property (retain, nonatomic) IBOutlet UILabel *lblInventory;
@property (retain, nonatomic) IBOutlet UILabel *lblVendor;
@property (retain, nonatomic) IBOutlet UILabel *lblYear;
@property (retain, nonatomic) IBOutlet UILabel *lblDescription;
@property (retain, nonatomic) IBOutlet UITableView *dataTable;


//Chatter
@property (nonatomic, retain) NSArray *newsFeed;
//@property (strong, nonatomic) NewsFeedViewController *newsFeedViewController;



@end
