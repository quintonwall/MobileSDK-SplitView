//
//  AppDelegate.m
//  Cloudstock3
//
//  Created by Quinton Wall on 3/9/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "AppDelegate.h"

#import "MasterViewController.h"

#import "DetailViewController.h"


#import "SFOAuthCredentials.h"
#import "SFAuthorizingViewController.h"
#import "SFRestAPI.h"


// Fill these in when creating a new Remote Access client on Force.com 
//currently points to dbworkbook demo org
static NSString *RemoteAccessConsumerKey = nil;// = @"YOUR_CONSUMER_KEY";
static NSString *OAuthRedirectURI = nil;// = @"YOUR_REDIRECT_URI";


static NSString * const kSFMobileSDKVersion = @"1.0.2";


// Key for storing the user's configured login host.
NSString * const kLoginHostUserDefault = @"login_host_pref";

// Key for the primary login host, as defined in the app settings.
NSString * const kPrimaryLoginHostUserDefault = @"primary_login_host_pref";

// Key for the custom login host value in the app settings.
NSString * const kCustomLoginHostUserDefault = @"custom_login_host_pref";

// Value for kPrimaryLoginHostUserDefault when a custom host is chosen.
NSString * const kPrimaryLoginHostCustomValue = @"CUSTOM";

// Key for whether or not the user has chosen the app setting to logout of the
// app when it is re-opened.
NSString * const kAccountLogoutUserDefault = @"account_logout_pref";

/// Value to use for login host if user never opens the app settings.
NSString * const kDefaultLoginHost = @"login.salesforce.com";

@interface AppDelegate (private)

- (NSString *)getUserAgentString;

/**
 Initializes the app settings, in the event that the user has not configured
 them before the first launch of the application.
 */
+ (void)ensureAccountDefaultsExist;

/**
 @return  YES if  user requested a logout in Settings.
 */
- (BOOL)checkForUserLogout;

/**
 Gets the primary login host value from app settings, initializing it to a default
 value first, if a valid one did not previously exist.
 @return The login host value from the app settings.
 */
+ (NSString *)primaryLoginHost;

/**
 Update the configured login host based on the user-defined app settings. 
 @return  YES if login host has changed in the app settings, NO otherwise. 
 */
+ (BOOL)updateLoginHost;


/**
 Set the SFAuthorzingViewController as the root view controller.
 */
- (void)setupAuthorizingViewController;

@end


@implementation AppDelegate

@synthesize window = _window;
@synthesize splitViewController = _splitViewController;
@synthesize detailViewController = detailViewController;
@synthesize masterViewController = masterViewController;
@synthesize authViewController=_authViewController;
@synthesize  coordinator = _coordinator;

#pragma mark - Remote Access / OAuth configuration


#pragma mark - init/dealloc

- (id) init
{	
    self = [super init];
    if (nil != self) {
        //Replace the app-wide HTTP User-Agent before the first UIWebView is created
        NSString *uaString = [self getUserAgentString];
        NSDictionary *appUserAgent = [[NSDictionary alloc] initWithObjectsAndKeys:uaString, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appUserAgent];
        [appUserAgent release];
        
        [[self class] ensureAccountDefaultsExist];
    }
    return self;
}

#pragma mark - Demo Step 1
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
	//setup our oauth view
    NSLog(@"didFinishLaunching");
    
	[self setupAuthorizingViewController];
	
	
	
	
    return YES;
}

#pragma mark - Demo Step 2
- (void)applicationDidBecomeActive:(UIApplication *)application
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    //Apparently when app is foregrounded, NSUserDefaults can be stale
	[defs synchronize];
    
    BOOL shouldLogout = [self checkForUserLogout] ;
    if (shouldLogout) {
        [self logout];
        [self clearDataModel];
        
        [defs setBool:NO forKey:kAccountLogoutUserDefault];
        [defs synchronize];
        [self setupAuthorizingViewController];
    } else {
        BOOL loginHostChanged = [[self class] updateLoginHost];
        if (loginHostChanged) {
            [_coordinator setDelegate:nil];
            [_coordinator release]; _coordinator = nil;
            
            [self clearDataModel];
            [self setupAuthorizingViewController];
        }
    }
    
	// refresh session or login for the first time
	[self login];
}


#pragma mark - App lifecycle

- (void)dealloc
{
	self.authViewController = nil;
    
    [_coordinator setDelegate:nil];
    [_coordinator release]; _coordinator = nil;
	[_window release];
	[_splitViewController release];
    [super dealloc];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}



- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSLog(@"handleOpenUrl");
    if (!url) {  return NO; }
    
    NSString * consumerKey = [url host];
    NSString * redirectUrl = [url absoluteString];
    
    NSRange index = [redirectUrl rangeOfString:@"="];
    
    NSInteger loc =index.location;
    redirectUrl = [redirectUrl substringFromIndex:loc+1];
    
    OAuthRedirectURI = redirectUrl;
    RemoteAccessConsumerKey = consumerKey;
    
    [[NSUserDefaults standardUserDefaults] setObject:consumerKey forKey:@"consumerKey"];
    [[NSUserDefaults standardUserDefaults] setObject:redirectUrl forKey:@"redirectUrl"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

#pragma mark - Salesforce.com login helpers


- (SFOAuthCoordinator*)coordinator {
    //create a new coordinator if we don't already have one
    if (nil == _coordinator) {
        
        OAuthRedirectURI = [[NSUserDefaults standardUserDefaults] objectForKey:@"redirectUrl"];
        RemoteAccessConsumerKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"consumerKey"];
        
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        NSString *loginDomain = [self oauthLoginDomain];
        NSString *accountIdentifier = [self userAccountIdentifier];
        //here we use the login domain as part of the identifier
        //to distinguish between eg  sandbox and production credentials
        NSString *fullKeychainIdentifier = [NSString stringWithFormat:@"%@-%@-%@",appName,accountIdentifier,loginDomain];
        
        
        SFOAuthCredentials *creds = [[SFOAuthCredentials alloc] 
                                     initWithIdentifier:fullKeychainIdentifier  
                                     clientId: [self remoteAccessConsumerKey] ];
        
        
        creds.domain = loginDomain;
        creds.redirectUri = [self oauthRedirectURI];
        
        SFOAuthCoordinator *coord = [[SFOAuthCoordinator alloc] initWithCredentials:creds];
        [creds release];
        coord.scopes = [[self class] oauthScopes]; 
        
        coord.delegate = self;
        _coordinator = coord;        
    } 
    
    return _coordinator;
}

- (void)login {
    //kickoff authentication
    [self.coordinator authenticate];
}


- (void)logout {
    [self.coordinator revokeAuthentication];
    [self.coordinator authenticate];
}

- (void)loggedIn {
    //provide the Rest API with a reference to the coordinator we used for login
    [[SFRestAPI sharedInstance] setCoordinator:self.coordinator];
	//[[SFRestAPI sharedInstance] setApiVersion:@"24.0"];
    
	masterViewController = [[[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil] autorelease];
	UINavigationController *masterNavigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
	
	detailViewController = [[[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil] autorelease];
	UINavigationController *detailNavigationController = [[[UINavigationController alloc] initWithRootViewController:detailViewController] autorelease];
	
	//default splitview template doesn't set the detailViewController to the masterViewController -- wtf?
	self.masterViewController.detailViewController = detailViewController;
	
	self.splitViewController = [[[UISplitViewController alloc] init] autorelease];
	self.splitViewController.delegate = detailViewController;
	self.splitViewController.viewControllers = [NSArray arrayWithObjects:masterNavigationController, detailNavigationController, nil];
	self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];

	/*
    // now show the true app view controller if it's not already shown
    if (nil != self.authViewController) {
        self.authViewController = nil;
    }
    
    if (nil == self.splitViewController) {
        UIViewController *rootVC = [self newRootViewController];
        self.splitViewController = rootVC;
        [rootVC release];
        self.window.rootViewController = self.splitViewController;
        [self.window makeKeyAndVisible];
    }
	 */
}

- (UIViewController*)newRootViewController {
    NSLog(@"You must override this method in your subclass");
    [self doesNotRecognizeSelector:@selector(newRootViewController)];
    return nil;
}


- (NSString *)getUserAgentString {
    //set a user agent string based on the mobile sdk version
    //We are building a user agent of the form:
    //SalesforceMobileSDK/1.0 iPhone OS/3.2.0 (iPad)
    
    UIDevice *curDevice = [UIDevice currentDevice];
    NSString *myUserAgent = [NSString stringWithFormat:
                             @"SalesforceMobileSDK/%@ %@/%@ (%@)",
                             kSFMobileSDKVersion,
                             [curDevice systemName],
                             [curDevice systemVersion],
                             [curDevice model]
                             ];
    
    
    return myUserAgent;
}


- (void)clearDataModel {
    self.splitViewController = nil;
}

+ (NSSet *)oauthScopes {
    return [NSSet setWithObjects:@"visualforce",@"api",nil] ; 
}


- (void)setupAuthorizingViewController {
    
    //clear all children of the existing window, if any
    if (nil != self.window) {
        NSLog(@"SFNativeRestAppDelegate clearing self.window");
        [self.window.subviews  makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.window = nil;
    }
    
    //(re)init window
    CGRect screenBounds = [ [ UIScreen mainScreen ] bounds ];
    UIWindow *rootWindow = [[UIWindow alloc] initWithFrame:screenBounds];
	self.window = rootWindow;
    [rootWindow release];
    
    // Set up a view controller for the authentication process.
    SFAuthorizingViewController *authVc = [[SFAuthorizingViewController alloc] initWithNibName:@"SFAuthorizingViewController" bundle:nil];
    self.authViewController = authVc;
    self.window.rootViewController = self.authViewController;
    self.window.autoresizesSubviews = YES;
    [authVc release];
    
    [self.window makeKeyAndVisible];
    
}

#pragma mark - SFOAuthCoordinatorDelegate

- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator willBeginAuthenticationWithView:(UIWebView *)view {
    NSLog(@"oauthCoordinator:willBeginAuthenticationWithView");
}


- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didBeginAuthenticationWithView:(UIWebView *)view {
    NSLog(@"oauthCoordinator:didBeginAuthenticationWithView");
    
    if (nil != self.authViewController) {
        // We're in the initialization of the app.  Make sure the auth view is in the foreground.
        [self.window bringSubviewToFront:self.authViewController.view];
        [self.authViewController setOauthView:view];
    }
    else
        [self.splitViewController.view addSubview:view];
}

- (void)oauthCoordinatorDidAuthenticate:(SFOAuthCoordinator *)coordinator {
    NSLog(@"oauthCoordinatorDidAuthenticate for userId: %@", coordinator.credentials.userId);
    [coordinator.view removeFromSuperview];
    [self loggedIn];
}


- (void)oauthCoordinator:(SFOAuthCoordinator *)coordinator didFailWithError:(NSError *)error {
    NSLog(@"oauthCoordinator:didFailWithError: %@", error);
    [coordinator.view removeFromSuperview];
    
    if (error.code == kSFOAuthErrorInvalidGrant) {  //invalid cached refresh token
        //restart the login process asynchronously
        NSLog(@"Logging out because oauth failed with error code: %d",error.code);
        [self performSelector:@selector(logout) withObject:nil afterDelay:0];
    }
    else {
        // show alert and retry
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Salesforce Error" 
                                                        message:[NSString stringWithFormat:@"Can't connect to salesforce: %@", error]
                                                       delegate:self
                                              cancelButtonTitle:@"Retry"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.coordinator authenticate];    
}


#pragma mark - Public 

#pragma mark - Remote Access / OAuth configuration


- (NSString*)remoteAccessConsumerKey {
    return RemoteAccessConsumerKey;
}

- (NSString*)oauthRedirectURI {
    return OAuthRedirectURI;
}

- (NSString*)oauthLoginDomain {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *loginHost = [defs objectForKey:kLoginHostUserDefault];
    
    return loginHost;
}

- (NSString*)userAccountIdentifier {
    //OAuth credentials can have an identifier associated with them,
    //such as an account identifier.  For this app we only support one
    //"account" but you could provide your own means (eg NSUserDefaults) of 
    //storing which account the user last accessed, and using that here
    return @"Default";
}



#pragma mark - Settings utilities

+ (BOOL)updateLoginHost
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs synchronize];
    
	NSString *previousLoginHost = [defs objectForKey:kLoginHostUserDefault];
	NSString *currentLoginHost = [self primaryLoginHost];
	NSLog(@"Hosts before update: previousLoginHost=%@ currentLoginHost=%@", previousLoginHost, currentLoginHost);
    
    // Update the previous app settings value to current.
	[defs setValue:currentLoginHost forKey:kLoginHostUserDefault];
    
	BOOL hostnameChanged = (nil != previousLoginHost && ![previousLoginHost isEqualToString:currentLoginHost]);
	if (hostnameChanged) {
		NSLog(@"updateLoginHost detected a host change in the app settings, from %@ to %@.", previousLoginHost, currentLoginHost);
	}
	
	return hostnameChanged;
}


+ (NSString *)primaryLoginHost
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs synchronize];
    NSString *primaryLoginHost = [defs objectForKey:kPrimaryLoginHostUserDefault];
    
    // If the primary host value is nil/empty, it's never been set.  Initialize it to default and return it.
    if (nil == primaryLoginHost || [primaryLoginHost length] == 0) {
        [defs setValue:kDefaultLoginHost forKey:kPrimaryLoginHostUserDefault];
        [defs synchronize];
        return kDefaultLoginHost;
    }
    
    // If a custom login host value was chosen and configured, return it.  If a custom value is
    // chosen but the value is *not* configured, reset the primary login host to a sane
    // value and return that.
    if ([primaryLoginHost isEqualToString:kPrimaryLoginHostCustomValue]) {  // User specified to use a custom host.
        NSString *customLoginHost = [defs objectForKey:kCustomLoginHostUserDefault];
        if (nil != customLoginHost && [customLoginHost length] > 0) {
            // Custom value is set.  Return that.
            return customLoginHost;
        } else {
            // The custom host value is empty.  We'll try to set a previous user-defined
            // value for the primary first, and if we can't set that, we'll just set it to the default host.
            NSString *prevUserDefinedLoginHost = [defs objectForKey:kLoginHostUserDefault];
            if (nil != prevUserDefinedLoginHost && [prevUserDefinedLoginHost length] > 0) {
                // We found a previously user-defined value.  Use that.
                [defs setValue:prevUserDefinedLoginHost forKey:kPrimaryLoginHostUserDefault];
                [defs synchronize];
                return prevUserDefinedLoginHost;
            } else {
                // No previously user-defined value either.  Use the default.
                [defs setValue:kDefaultLoginHost forKey:kPrimaryLoginHostUserDefault];
                [defs synchronize];
                return kDefaultLoginHost;
            }
        }
    }
    
    // If we got this far, we have a primary host value that exists, and isn't custom.  Return it.
    return primaryLoginHost;
}

+ (void)ensureAccountDefaultsExist
{
    
    // Getting primary login host will initialize it to a proper value if it isn't already
    // set.
	NSString *currentHostValue = [self primaryLoginHost];
    
    // Make sure we initialize the user-defined app setting as well, if it's not already.
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs synchronize];
    NSString *userDefinedLoginHost = [defs objectForKey:kLoginHostUserDefault];
    if (nil == userDefinedLoginHost || [userDefinedLoginHost length] == 0) {
        [defs setValue:currentHostValue forKey:kLoginHostUserDefault];
        [defs synchronize];
    }
}

- (BOOL)checkForUserLogout {
	return [[NSUserDefaults standardUserDefaults] boolForKey:kAccountLogoutUserDefault];
}



@end
