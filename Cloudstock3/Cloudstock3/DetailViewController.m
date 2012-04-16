//
//  DetailViewController.m
//  split1
//
//  Created by Quinton Wall on 3/9/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "DetailViewController.h"
#import "SFOAuthCoordinator.h"
#import "SFOAuthCredentials.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
- (void)fetchChatterFeed;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;  //our id
@synthesize detailName = _detailName;
@synthesize detailDescription = _detailDescription;
@synthesize detailInventory = _detailInventory;
@synthesize detailPrice = _detailPrice;
@synthesize detailVendor = _detailVendor;
@synthesize detailYear = _detailYear;


@synthesize lblName = _lblName;
@synthesize lblInventory = _lblInventory;
@synthesize lblVendor = _lblVendor;
@synthesize lblYear = _lblYear;
@synthesize lblDescription = _lblDescription;


@synthesize masterPopoverController = _masterPopoverController;


//Add for Chatter
//@synthesize newsFeedViewController = _newsFeedViewController;
@synthesize newsFeed = _newsFeed;
@synthesize dataTable = _dataTable;

- (void)dealloc
{
	[_detailItem release];
	[_masterPopoverController release];
	[_lblName release];
	[_lblInventory release];
	[_lblVendor release];
	[_lblYear release];
	[_lblDescription release];

	[_dataTable release];
    [super dealloc];
}

#pragma mark - Demo step 3 (and 7)
- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        [_detailItem release]; 
        _detailItem = [newDetailItem retain]; 
		
        
		//fetch the data and handle response via didLoadResponse delegate method
		NSString *queryString =  [NSString stringWithFormat:@"%@%@%@", 
                                  @"select Name, Description__c, Price__c, Total_Inventory__c, Vendor__c, Year_of_Manufacturing__c from Merchandise__c where id = '", _detailItem,@"'"];
        
        SFRestRequest *request;
        request = [[SFRestAPI sharedInstance] requestForQuery:queryString];
        
        [[SFRestAPI sharedInstance] send:request delegate:self];
		
		[self fetchChatterFeed];
		
    }
	
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }      
	
	
}

#pragma mark - view
- (void)configureView
{
    // Update the user interface for the detail item.
	
	//we want the clear background for our feedtable.
	[self.dataTable setBackgroundView:nil];
	[self.dataTable setBackgroundView:[[[UIView alloc] init] autorelease]];
	[self.dataTable setBackgroundColor:UIColor.clearColor];
	
	//detailItem will only be set if we have results from the db
	if (self.detailItem) {
	    //self.detailDescriptionLabel.text = [self.detailItem description];
	
		
		 [_lblInventory setText:[NSString stringWithFormat:@"%@", _detailInventory]];
		
		if ([_detailName isEqual:[NSNull null]]) {
			[_lblName setText:@""];
		}
		else {
			[_lblName setText:_detailName];
		}
		
		if ([_detailVendor isEqual:[NSNull null]]) {
			[_lblVendor setText:@""];
		}
		else {
			[_lblVendor setText:_detailVendor];
		}
		
		if ([_detailYear isEqual:[NSNull null]]) {
			[_lblYear setText:@""];
		}
		else {
			[_lblYear setText:[NSString stringWithFormat:@"%@", _detailYear]];
		}
		
		if ([_detailDescription isEqual:[NSNull null]]) {
			[_lblDescription setText:@"No description available. Someone should really do something about that."];
			_lblDescription.lineBreakMode = UILineBreakModeWordWrap;
			self.lblDescription.numberOfLines = 0; //so we wrap
		}
		else {
			[_lblDescription setText:_detailDescription];
		}
	
		/*
		if (_detailPrice == 0) {
			[_lbl setText:@"Free!"];
		}
		[_lblPrice setText:[NSString stringWithFormat:@"$%@", _detailPrice]];
		 */
		
	}
}





#pragma mark - Demo step 4

- (void)request:(SFRestRequest *)request didLoadResponse:(id)response {
    
	//handling non-chatter response
	if ([response objectForKey:@"records"]) {
		//database.com returns additional information such as attributes and number of results
		//we want the actual response...
		NSMutableArray *allDetails = [response objectForKey:@"records"];
		NSDictionary *results = [allDetails objectAtIndex:0];
		
		
		//payload is returned as JSON. If the value of a textfield is null, Objective-C will represent this as a NSNull object.
		//Printing it to the console will show as "<null>". 
		//This is different from nil,so let's check for NSNull
		
		_detailName = [results objectForKey:@"Name"];
		_detailDescription = [results objectForKey:@"Description__c"];
		_detailPrice = [results objectForKey:@"Price__c"];
		_detailVendor = [results objectForKey:@"Vendor__c"];
		_detailInventory = [results objectForKey:@"Total_Inventory__c"];
		_detailYear = [results objectForKey:@"Year_of_Manufacturing__c"];
		
		[self configureView];
		
		//prep the news feed
		//if (!self.newsFeedViewController) {
		//	self.newsFeedViewController = [[[NewsFeedViewController alloc] initWithNibName:@"NewsFeedViewController" bundle:nil] autorelease];
		//self.newsFeedViewController.detailItem = self.detailItem;
		
	} else {   //handling chatter response - records come back in "items" vs. "records"
		NSArray *records = [response objectForKey:@"items"];
		NSLog(@"request:didLoadResponse: #records: %d", records.count);
		self.newsFeed = records;
		[_dataTable reloadData];
	}
	
	
    
   	
}


- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    
    //here is a sample of handling errors neatly.
    NSLog(@"RootViewController:didFailWithError: %@", error);
    
    // show alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Database.com Error" 
                                                    message:[NSString stringWithFormat:@"Problem retrieving data %@", error]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];
    [alert release];
}





#pragma mark - Chatter Fetch
- (void) fetchChatterFeed
{
	SFRestRequest* request = [[SFRestAPI sharedInstance] requestForResources];
	
	request.path = [NSString stringWithFormat:@"%@%@%@%@", request.path, @"/chatter/feeds/record/", _detailItem, @"/feed-items/"];
	
    [[SFRestAPI sharedInstance] send:request delegate:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	[self configureView];
}

- (void)viewDidUnload
{
	[self setLblName:nil];
	[self setLblInventory:nil];
	[self setLblVendor:nil];
	[self setLblYear:nil];
	[self setLblDescription:nil];
	[self setDataTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Detail", @"Detail");
    }
    return self;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.newsFeed count];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}



/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

//TODO: create a custom chatter feed UIView and use this for the cells.

// Customize the appearance of table view cells.
#pragma mark - Chatter Display
- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"CellIdentifier";
	
	// Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		
    }
	
	
	// Configure the cell to show the data.
	NSDictionary *obj = [self.newsFeed objectAtIndex:indexPath.row];
	
	//actor
	NSDictionary *actor = [obj objectForKey:@"actor"];
	
	//get profile pic
	NSDictionary *photo = [actor objectForKey:@"photo"];
	//we need the token to get the profile photos
	NSString *token = [SFRestAPI sharedInstance].coordinator.credentials.accessToken;
	NSString *profilePicUrl = [NSString stringWithFormat:@"%@%@%@", [photo objectForKey:@"smallPhotoUrl"], @"?oauth_token=", token];
	
	NSURL * imageURL = [NSURL URLWithString:profilePicUrl];
	NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
	UIImage * image = [UIImage imageWithData:imageData];
	cell.imageView.image = image;
	
	//UIImage *image = [UIImage imageNamed:@"barcode-28.png"];
	
	
	NSDictionary *body = [obj objectForKey:@"body"];
	cell.textLabel.text =  [NSString stringWithFormat:@"%@: %@", [actor objectForKey:@"name"], [body objectForKey:@"text"] ];
	
	//this adds the arrow to the right hand side.
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
	
}


@end
