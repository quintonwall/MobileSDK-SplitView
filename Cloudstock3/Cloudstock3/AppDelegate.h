//
//  AppDelegate.h
//  Cloudstock3
//
//  Created by Quinton Wall on 3/9/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SFOAuthCoordinator.h"
#import "MasterViewController.h"
#import "DetailViewController.h"

@class SFAuthorizingViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, SFOAuthCoordinatorDelegate, UIAlertViewDelegate> {
	SFOAuthCoordinator *_coordinator;
    SFAuthorizingViewController *_authViewController;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) MasterViewController *masterViewController;

/**
 The SFOAuthCoordinator used for managing login/logout.
 */
@property (nonatomic, readonly) SFOAuthCoordinator *coordinator;

/**
 View controller that gives the app some view state while authorizing.
 */
@property (nonatomic, retain) SFAuthorizingViewController *authViewController;

/**
 Override this method to change the scopes that should be used,
 default value is:
 [NSSet setWithObjects:@"api",nil]
 
 @return The set of oauth scopes that should be requested for this app.
 */
+ (NSSet *)oauthScopes;


/**
 Kickoff the login process.
 */
- (void)login;

/**
 Sent whenever the use has been logged in using current settings.
 Be sure to call super if you override this.
 */
- (void)loggedIn;

/**
 Forces a logout from the current account.
 This throws out the OAuth refresh token.
 */
- (void)logout;

/**
 This disposes of any current data.
 */
- (void)clearDataModel;


/**
 Your subclass MUST override this method
 @return NSString the Remote Access object consumer key
 */
- (NSString*)remoteAccessConsumerKey;

/**
 Your subclass MUST override this method
 @return NSString the Remote Access object redirect URI
 */
- (NSString*)oauthRedirectURI;

/**
 By default this method obtains the login domain from Settings (see Settings.bundle)
 Your subclass MAY override this to lock logins to a particular domain.
 @return NSString the Remote Access object Login Domain
 */
- (NSString*)oauthLoginDomain;


/**
 Your subclass MAY override this method to provide an account identifier,
 such as the most-recently-used username.
 
 @return NSString An account identifier such as most recently used username.
 */
- (NSString*)userAccountIdentifier;


/**
 Your subclass MUST override this method to provide a root view controller.
 Create and return a new instance of your app's root view controlller.
 This should be the view controller loaded after login succeeds.
 @return UIViewController A view controller to be shown after login succeeds.
 */
- (UIViewController*)newRootViewController;


@end
