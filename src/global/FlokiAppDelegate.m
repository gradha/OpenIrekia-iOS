//
// OpenIrekia v2.0 Cliente iOS
//
// Copyright 2009-2010 eFaber, S.L.
// Copyright 2009-2010 Ejie, S.A.
// Copyrigth 2009-2010 Dirección de Gobierno Abierto y Comunicación en Internet; 
//    Gobernu Irekirako eta Interneteko Komunikaziorako Zuzendaritza; Lehendakaritza.
//    Gobierno Vasco – Eusko Jaurlaritza 
// Licencia con arreglo a la EUPL, Versión 1.1 o –en cuanto sean aprobadas 
// por la Comisión Europea– versiones posteriores de la EUPL (la Licencia);
// Solo podrá usarse esta obra si se respeta la Licencia. Puede obtenerse una 
// copia de la Licencia en: http://ec.europa.eu/idabc/eupl 
// Salvo cuando lo exija la legislación aplicable o se acuerde por escrito, 
// el programa distribuido con arreglo a la Licencia se distribuye TAL CUAL,
// SIN GARANTÍAS NI CONDICIONES DE NINGÚN TIPO, ni expresas ni implícitas.
// Véase la Licencia en el idioma concreto que rige los permisos y limitaciones 
// que establece la Licencia
//
//  http://open.irekia.net, openirekia@efaber.net
#import "global/FlokiAppDelegate.h"

#import "categories/NSDictionary+Floki.h"
#import "controllers/FLBootstrap_controller.h"
#import "controllers/FLContent_view_controller.h"
#import "controllers/FLTab_controller.h"
#import "global/FLDB.h"
#import "global/FLGloss_rectangle.h"
#import "global/FLSharekit_configuration.h"
#import "global/FLi18n.h"
#import "global/settings.h"
#import "ipad/FLIBlank_view_controller.h"
#import "ipad/FLISplit_view_controller.h"
#import "net/FLCached_connection.h"
#import "net/FLRemote_connection.h"
#import "protocols/FLTab_protocol.h"
#import "structures/FLRegex_match.h"

#import "ELHASO.h"
#import "NSArray+ELHASO.h"
#import "UINavigationController+ELHASO.h"
#import "FLReachability.h"
#import "SBJSon.h"
#import "ShareKit/Core/SHK.h"
#import "ShareKit/Configuration/SHKConfiguration.h"

#import <UIKit/UIKit.h>

#import <assert.h>
#import <time.h>
#import <utime.h>

/** \mainpage Floki
 *
 * \section meta Meta
 *
 * You are reading the autogenerated Doxygen documentation extracted
 * from Floki's source code. However, you are probably more interested
 * in the manually crafted reference documents of the docs subdirectory,
 * where the application protocol and other stuff is described.
 *
 * This internal documentation is just to make it pretty and let
 * people new to the source code browse easily the maze of classes
 * and hierarchies. If you run "make" and "make install" inside the
 * directory where the html documentation is generated, you will
 * create Xcode documentation. The nice thing about that is that you
 * get search for method and function names. There are other output
 * formats, check http://www.stack.nl/~dimitri/doxygen/starting.html
 * for the full information.
 *
 * To start browsing the documentation and the code, just go to the
 * "Classes" section above and select the hierarchy view.
 *
 * \section structure Floki's internal structure
 *
 * Floki is rather structure-less, there are few predefined behaviours
 * due to its dynamic nature. It provides a foundation rather than
 * the application behaviour. So there's the application delegate
 * named FlokiAppDelegate, which initialises the application, but
 * part of the initialisation consists of downloading the application
 * specification from a network location.
 *
 * During the downloading of the initial application specification,
 * the FLBootstrap_controller is in charge of displaying the \c
 * Default.png file along with an internationalized "loading..."
 * message. The FLBootstrap_controller may not even be shown if you are
 * running the application a second time and everything is cached on
 * disk.
 *
 * Once the application specification is downloaded, Floki
 * constructs the initial tabs of the application using the
 * FLTab_controller and that's it, it gives control to the classes you
 * have put in charge of those tabs.  But what classes are they? Usually
 * you will have a FLNews_view_controller, FLGallery_view_controller or
 * FLWeb_view_controller. There are a few more which can be put directly
 * as tab controllers, like the FLMovie_view_controller, but that's
 * rather limited and useless in real life.
 *
 * \section i18n Internationalization
 * This is tricky. Apple provides some tools to internationalize
 * the source code, but they are not so good when your messages can't
 * be compiled in because they depend on the runtime data downloaded
 * from the network. Also, while they are good to easily support the
 * languages also supported by the operative system, I think we will
 * die before seeing iOS in Euskara. Therefore, we rewrote the
 * wheel into a square peg.
 *
 * Internationalization messages are separated in two classes: those
 * that have to be embedded into the application and those that will
 * be downloaded from the net. Both are handled by the FLi18n class.
 *
 * Embedded messages are stored in <tt>resources/i18n/str_??.plist</tt>
 * files in the source tree and included in the final binary. These
 * are simple plists with arrays, which contain sequential strings.
 * The strings are retrieved in the code through their position in
 * the array using FLi18n::embeded_string:, or the faster to type _e()
 * macro.
 *
 * For the runtime messages of the application, where applicable,
 * you can use FLi18n::string_by_number: or the faster to type _()
 * macro. Note that the runtime messages depend on them having been
 * loaded previously, usually through initialisation of the class
 * with FLi18n::init_with_langs:.
 *
 * Due to both types of strings having a different loading mechanism,
 * please read the details of their methods to know what will be
 * returned by each.
 *
 * \section protocols Available protocols
 *
 * Doxygen doesn't group easily protocols in the class page. Here
 * is a manual list:
 * - FLContainer_protocol
 * - FLTab_protocol
 * - FLTap_delegate
 *
 * \section categories Categories
 *
 * Doxygen doesn't group easily class categories. Here is a manual
 * list:
 * - NSDictionary
 * - NSString
 *
 * \section external-libs External libraries
 * Just a moment ago we mentioned the disk cache. It is controlled
 * through the singleton like FLDB class built on top of the EGODatabase
 * (http://developers.enormego.com/code/egodatabase/) from enormego
 * (http://enormego.com/). You can access this class through
 * FlokiAppDelegate::get_db.
 *
 * The communication between server and client, usually done through
 * a subclass of FLContent_item, uses JSON (http://json.org/). For the
 * parsing and generation of JSON Floki uses the SBJson framework
 * (https://github.com/gradha/json-framework).
 *
 * Fragments of code from a private library by Grzegorz Adam
 * Hankiewicz from Electric Hands Software (http://elhaso.com/) have
 * made it to Floki for hardware UDID detection. See licensing
 * information under \c external/egf/readme.txt.
 *
 * Snippets of code from https://github.com/gradha/ELHASO-iOS-snippets are
 * included, MIT license mostly and public domain. See its readme.
 *
 * To be aware of the state of the network and show informative
 * messages to the user we use Apple's Reachability class
 * (http://developer.apple.com/iphone/library/samplecode/Reachability/index.html).
 * The class was renamed to FLReachability to avoid possible future
 * clashes with third party libraries which linked into Floki might
 * give problems due to including themselves a copy of the Reachability
 * class. Unfortunately in objective c there are no namespaces and
 * everybody has to suck it down and use ugly prefixes. Hah, just
 * look at the mess Apple did with the internal Message class in
 * their MessageUI framework. Madness.
 *
 * The section headers don't use prerendered graphics, they are drawn on
 * demand. This is accomplished using the RRClossCausticShader class
 * (https://github.com/royratcliffe/gloss-caustic-shader). The sections use
 * square graphic images, so the FLGloss_rectangle class draws the UIImage
 * required for the section button backgrounds.
 *
 * For the purpose of parsing regular expressions, the RegexKitLite 4 library
 * is used under a BSD license. You can get it from
 * http://regexkit.sourceforge.net/. The library doesn't exist in github
 * officially, so we include the extracted tarball directly.
 *
 * Sharing on social networks (twitter and facebook) is done with the Sharekit
 * library from https://github.com/gradha/community_sharekit. This library
 * includes further depencencies with their documentation, like JSONKit and
 * json-framework (again!).
 */

/// Global constants.
NSThread *serial_background_thread;


/// Private pseudo constants.
static const float CHECK_CACHED_DATA_DELAY = 3;

#define FILE_APP_DATA			@"app_data"
#define FILE_BEACON_DATA		@"beacon_data"


/// Function forward declarations.
static NSDictionary *_get_disk_app_data(NSString *name);
static void _update_timestamp(const char *path);


@interface FlokiAppDelegate ()
- (void)fetch_app_beacon;
- (void)animate_tab_controller;
- (NSTimeInterval)secondsToCacheExpiration;
- (void)register_tab:(NSString*)name unique_id:(int)unique_id;
- (void)close_database;
- (void)register_tables;
- (BOOL)save_as_beacon:(NSString*)data;
- (void)clear_cache;
- (void)update_cache_size_setting;
- (void)preserve_old_files;
@end

@implementation FlokiAppDelegate

@synthesize active_downloads = active_downloads_;
@synthesize db = db_;
@synthesize reachability_alert = reachability_alert_;
@synthesize tab_controller = tab_controller_;
@synthesize window = window_;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	window_.backgroundColor = [UIColor whiteColor];

	/** Set up the reachability class. This works slowly, so let it be first. */
	[FLReachability init_with_host:get_reachability_host()];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(reachability_changed:)
		name:kReachabilityChangedNotification object: nil];

	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

	// Create background thread with runloop.
	serial_background_thread = [[NSThread alloc] initWithTarget:self
		selector:@selector(start_background_runloop:) object:nil];
	background_thread_alive_ = YES;
	[serial_background_thread start];

	// Init sharekit configuration.
	DefaultSHKConfigurator* configurator = [FLSharekit_configuration new];
	[SHKConfiguration sharedInstanceWithConfigurator:configurator];
	[configurator release];

	// Try to preserve old cache files.
	[self preserve_old_files];

	FLTab_controller *tab_controller = [FLTab_controller new];
	self.tab_controller = tab_controller;
	[tab_controller release];
	if (!IS_IPAD) {
		[self.window addSubview:self.tab_controller.view];
	} else {
		split_view_ = [[FLISplit_view_controller alloc]
			init_with_master:self.tab_controller];
		[self.window addSubview:split_view_.view];
	}
	[self.window makeKeyAndVisible];

	if (IS_IPAD)
		[SHK setRootViewController:split_view_];
	else
		[SHK setRootViewController:self.tab_controller];

	/* Do we force cleaning the cache? */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	const BOOL clear_cache = [defaults boolForKey:DEFAULTS_CLEAR_CACHE_ON_BOOT];
	const BOOL lang_changed = [FLi18n did_last_used_language_change];
	const BOOL beacon_changed = did_beacon_url_change();
	const BOOL device_changed =
		([defaults integerForKey:LAST_DEVICE_ID] != get_device_identifier());
	if (clear_cache || lang_changed || beacon_changed || device_changed)
		[self clear_cache];

	/* Store for later the current device identifier and beacon url. */
	[defaults setInteger:get_device_identifier() forKey:LAST_DEVICE_ID];
	[defaults setObject:get_beacon_url() forKey:LAST_BEACON_URL];

	/* Check application data cache and start up fetching process. */
	NSDictionary *app_data = _get_disk_app_data(FILE_APP_DATA);
	if (![self.tab_controller init_app_data:app_data]) {
		FLBootstrap_controller *splash = [FLBootstrap_controller new];
		UIViewController *root = split_view_ ?
			(id)split_view_ : (id)self.tab_controller;
		[root presentModalViewController:splash animated:NO];
		[splash release];
		[self performSelector:@selector(fetch_app_beacon)
			withObject:nil afterDelay:0.0];
	} else {
		DLOG(@"All data loaded from disk, starting application.");
		[self animate_tab_controller];
		[self performSelector:@selector(check_cached_data)
			withObject:nil afterDelay:CHECK_CACHED_DATA_DELAY];
	}
}

- (void)dealloc
{
	[self close_database];
	[reachability_alert_ release];
	[beacon_string_ release];
	[connection_ cancel];
	[connection_ release];
	[tab_controller_ release];
	[db_ release];
	[window_ release];
	[super dealloc];
}

/** Application shutdown. Save cache and stuff...
 * Note that the method could be called even during initialisation,
 * so you can't make any guarantees about objects being available.
 **/
- (void)applicationWillTerminate:(UIApplication *)application
{
	background_thread_alive_ = NO;
	/* Remove languages, see FLi18n::fixup_unsupported_languages. */
	[[NSUserDefaults standardUserDefaults]
		removeObjectForKey:DEFAULTS_APPLE_LANGUAGES];

	[[FLDB get_db] close];

	/* Save the selected tab and posisbly viewed item. */
	if (split_view_)
		[split_view_ remember_current_tab_and_item];
	else
		[self.tab_controller remember_current_tab_and_item];

	/* Saving the cache settings will sync the defaults. */
	[self update_cache_size_setting];

	// TODO: Review if this is right.
	//[FLCached_connection save_cache];
	[FLi18n set:nil];
}

/** Oops, we are being bad. Try to free as much memory as possible.
 */
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	DLOG(@"applicationDidReceiveMemoryWarning");
	[FLCached_connection didReceiveMemoryWarning];
	[FLGloss_rectangle didReceiveMemoryWarning];
}

/** Handle reporting of errors to the user.
 * Pass as first object the NSError, NSString or whatever you want
 * to be appended to the user message. If abort_if_needed is set
 * YES and the app has not been yet initialised, closing the
 * alert will exit the application.
 */
- (void)handle_error:(NSString*)message with_message:(NSString*)error
	 abort_if_needed:(BOOL)abort_if_needed
{
	const BOOL will_abort = (abort_if_needed && !app_is_initialised_);

	NSString *title = will_abort ? _e(0) : _e(1);
	NSString *button = will_abort ? _e(2): _e(3);
	NSString *text = message;
	// _0: Aborting program
	// _1: Warning
	// _2: Abort
	// _3: Ignore

	if (error)
		text = [NSString stringWithFormat:@"%@\n%@", message, error];

	abort_after_alert_ = will_abort;

	/* Ignore connection errors if we are telling the user already. */
	if (!will_abort && self.reachability_alert)
		return;

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
		message:text delegate:self cancelButtonTitle:button
		otherButtonTitles:nil];
	[alert show];
	[alert release];
	DLOG(@"%@: %@", title, text);
}

/** Wrapper to extract error attribute.
 */
- (void)handle_error:(NSString*)message with_error:(NSError*)error
	 abort_if_needed:(BOOL)abort_if_needed
{
	[self handle_error:message with_message:error.localizedDescription
		abort_if_needed:abort_if_needed];
}

/** Perverted version of handle_error. Always closes the application.
 * The behaviour is forced by calling the normal function but earlier
 * setting the app_is_initialised_ to NO so it will always explode.
 *
 * The abort_always parameter is not used, only as named parameter
 * to remind the caller this is equivalent of calling abort().
 */
- (void)handle_error:(NSError*)error
	message:(NSString*)message abort_always:(BOOL)p
{
	app_is_initialised_ = NO;
	[self handle_error:message with_error:error abort_if_needed:YES];
}

/** Starts up the connection that retrieves the beacon data.
 */
- (void)fetch_app_beacon
{
	connection_ = [[FLRemote_connection alloc]
		init_with_action:@selector(did_receive_beacon_data:error:) target:self];
	[connection_ request:[FLContent_view_controller
		prettify_request_url:get_beacon_url()]];
}

/** Handles receiving beacon data.
 * If the application is already initialised, this function has
 * been called to check the net and see if the application data has
 * to be refreshed. So in this case the function will compare the
 * version field.
 *
 * Otherwise, the function is called because there is no cache,
 * first time run, so it inconditionally requests feching application
 * data.
 */
- (void)did_receive_beacon_data:(id)response error:(NSError*)error
{
	if (error) {
		[self handle_error:_e(4) with_error:error abort_if_needed:YES];
		// _4: Error getting app beacon
		return;
	}
	// _

	NSString *response_string = [[[NSString alloc]
		initWithData:[connection_ data] encoding:NSUTF8StringEncoding]
		autorelease];

	NSDictionary *result = [response_string JSONValue];
	if (!result) {
		[self handle_error:_e(5) with_message:response_string
			abort_if_needed:YES];
		// _5: Invalid app beacon JSON
		return;
	}

	static NSString *required_keys[] = {@"url", @"v", @"ttl", 0};
	for (int f = 0; required_keys[f]; f++) {
		if (![result objectForKey:required_keys[f]]) {
			[self handle_error:_e(6) with_message:required_keys[f]
				abort_if_needed:YES];
			// _6: Missing beacon key
			return;
		}
	}

	/* Store the beacon string for saving later. We don't want
	 * to save the beacon with the new app data version until the
	 * real app data has been downloaded. Otherwise a cache
	 * inconsistency could be generated and the world would implode
	 * into itself. Oh the horror!
	 */
	[beacon_string_ release];
	beacon_string_ = [response_string retain];

	BOOL fetch_data = NO;
	if (app_is_initialised_) {
		const int online_version = [result get_int:@"v" def:-1];
		if (beacon_cached_version_ != online_version) {
			DLOG(@"Version of data changed, refetching.");
			fetch_data = YES;
		} else {
			/* Everything OK. Refresh the beacon string and app data files. */
			const char *path = [get_path(FILE_APP_DATA, DIR_CACHE)
				cStringUsingEncoding:1];
			_update_timestamp(path);

			if (![self save_as_beacon:response_string])
				return;

			[self performSelector:@selector(check_cached_data)
				withObject:nil afterDelay:CHECK_CACHED_DATA_DELAY];
		}
	} else {
		DLOG(@"Fetching data application because its the first time.");
		fetch_data = YES;
	}

	if (fetch_data) {
		[connection_ release];
		connection_ = [[FLRemote_connection alloc]
			init_with_action:@selector(did_receive_app_data:error:)
			target:self];
		[connection_ request:[FLContent_view_controller
			prettify_request_url:[result objectForKey:@"url"]]];
	}
}

/** Handles receiving and parsing app data from the net.
 * The function gets the JSON data and either uses it to initialise
 * the FLTab_controller, or validates it. In the latter case, the
 * function will not update the view, but the data will be stored on
 * the disk cache. Therefore, a user relaunching the application will
 * now get the new version of the app.
 */
- (void)did_receive_app_data:(id)response error:(NSError*)error
{
	if (error) {
		[self handle_error:_e(7) with_error:error abort_if_needed:YES];
		// _7: Error getting app data
		return;
	}

	NSString *response_string = [[[NSString alloc]
		initWithData:[connection_ data] encoding:NSUTF8StringEncoding]
		autorelease];

	NSDictionary *result = [response_string JSONValue];
	if (!result) {
		[self handle_error:_e(8) with_message:response_string
			abort_if_needed:YES];
		// _8: Invalid app data JSON
		return;
	}

	if (app_is_initialised_) {
		if (![self.tab_controller validate_app_data:result]) {
			[self handle_error:_e(9) with_message:nil abort_if_needed:YES];
			// _9: Error parsing app data 2
			return;
		}
	} else {
		if (![self.tab_controller init_app_data:result]) {
			[self handle_error:_e(10) with_message:nil abort_if_needed:YES];
			// _10: Error parsing app data 1
			return;
		}
	}

	/* Save the string to a file for cached persistence. */
	NSString *path = get_path(FILE_APP_DATA, DIR_CACHE);
	NSError *write_error = nil;
	BOOL valid = [response_string writeToFile:path atomically:YES
		encoding:NSUTF8StringEncoding error:&write_error];
	if (!valid) {
		[self handle_error:_e(11) with_error:error abort_if_needed:YES];
		// _11: Couldn't save app data
		return;
	}

	/* Save NOW the beacon data stored in the class. */
	if (![self save_as_beacon:beacon_string_])
		return;
	[beacon_string_ release];
	beacon_string_ = nil;

	if (!app_is_initialised_) {
		[self animate_tab_controller];
		if (IS_IPAD)
			[self performSelector:@selector(correct_ipad_landscape_startup)
				withObject:nil afterDelay:0.0];
	}

	[self performSelector:@selector(check_cached_data)
		withObject:nil afterDelay:CHECK_CACHED_DATA_DELAY];
}

/** Replaces the FLBootstrap_controller with the FLTab_controller.
 * Also modifies the app_is_initialised_ variable so that other
 * code knows that the app has once passed through here, meaning the
 * application is launched and cannot be updated live.
 *
 * Also initialises gloal SQLite database (see get_db).
 */
- (void)animate_tab_controller
{
	LASSERT(!app_is_initialised_, @"Uh oh, bad thing");
	LASSERT(!self.db, @"No internal db pointer?");
	app_is_initialised_ = YES;

	self.db = [FLDB open_database];
	if (!self.db) {
		[self handle_error:nil message:_e(12) abort_always:YES];
		// _12: Error opening database
		return;
	}

	[self register_tables];

	/* Restore the last open tab if available. */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	const int last_tab = [defaults integerForKey:LAST_TAB];
	if (last_tab > 0 && last_tab < self.tab_controller.viewControllers.count)
		self.tab_controller.selectedIndex = last_tab;

	/* Save the current application version to check version changes booting. */
	NSString* runtime_version = [[[NSBundle mainBundle] infoDictionary]
		objectForKey:@"CFBundleVersion"];
	[defaults setObject:runtime_version forKey:LAST_VERSION];

	[split_view_ recover_button_text];

	UIViewController *root = split_view_ ?
		(id)split_view_ : (id)self.tab_controller;
	if (root.modalViewController)
		[root dismissModalViewControllerAnimated:YES];
}

/** Really weird hack for first statup landscape launch.
 * So... apparently the first time you install the application on an ipad, and
 * launch it in landscape mode, the detail view will believe it is in portrait
 * mode. While cosmetically this doesn't matter, the problem is that the detail
 * view will show the normal popup button which shows the tabbed view
 * controllers.
 *
 * If the user touches then this button, the tab on the left disappears and
 * chaos ensues.
 *
 * And most weird of all, this only happens the first time after installation,
 * if you open the application later, the rotation of the view is set
 * correctly. Anyway, this method simply calls manually the methods which will
 * correctly hide the button and update the arrow to look rotated.
 */
- (void)correct_ipad_landscape_startup
{
	LASSERT(IS_IPAD, @"This should only be needed for ipad starting landscape");
	const CGRect rect = split_view_.view.frame;
	if (rect.size.width > rect.size.height) {
		DLOG(@"Hey! forcing landscape rotation post startup message");
		[split_view_ splitViewController:split_view_
			willShowViewController:nil invalidatingBarButtonItem:nil];
		// Simulate landscape rotation, any will do to correct the arrow.
		UIViewController *detail = [split_view_.viewControllers get:1];
		if ([detail isKindOfClass:[FLIBlank_view_controller class]])
			[detail willRotateToInterfaceOrientation:
				UIInterfaceOrientationLandscapeLeft duration:0];
	}
}

/** Sets the number of active downloads.
 * If bigger than zero, turns on the global activity indicator.
 */
- (void)setActive_downloads:(int)new_value
{
	if (active_downloads_ == new_value)
		return;

	[UIApplication sharedApplication].networkActivityIndicatorVisible =
		(0 != new_value);
	active_downloads_ = new_value;
	//DLOG(@"%d active downloads", active_downloads_);
}

/** Special method that runs a background thread forever.
 * This is initialized in the main application launch and can be used later by
 * the application to serialize background operations easily. See
 * http://stackoverflow.com/questions/6158397/equivalent-of-gcd-serial-dispatch-queue-in-ios-3-x/6589065#6589065
 * and
 * http://stackoverflow.com/questions/2584394/iphone-how-to-use-performselectoronthreadwithobjectwaituntildone-method/2615480#2615480
 */
- (void)start_background_runloop:(id)dummy
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSRunLoop *runloop = [NSRunLoop currentRunLoop];
	[runloop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];

	while (background_thread_alive_) {
		DLOG(@"start_background_runloop step");
		[runloop runMode:NSDefaultRunLoopMode
			beforeDate:[NSDate distantFuture]];
	}
	[pool release];
}

#pragma mark -
#pragma mark Controller spawning pools

/// Internal workhorse method for the spawn_*_controller methods.
+ (UIViewController*)spawn_controller:(FLRegex_match*)match selector:(SEL)selector
{
	FlokiAppDelegate *floki = (id)[[UIApplication sharedApplication] delegate];
	//for (UIViewController<FLTab_protocol> *controller in
	for (UINavigationController *nav in floki.tab_controller.viewControllers) {
		UIViewController<FLTab_protocol> *controller = (id)nav.rootController;
		RASSERT([controller respondsToSelector:@selector(unique_id)],
			@"Unexpected controller fails protocol!", continue);

		if ([controller unique_id] == match.controller_id &&
				[controller respondsToSelector:selector]) {
			return [controller performSelector:selector withObject:match];
		}
	}
	DLOG(@"Unable to spawn controller for %@", match);
	return nil;
}

/** Queries the tab controller of the app if any news controller can spawn.
 * The method queries all tabs for a coincidence in the unique id number. If
 * so, spawns a copy and fills it with the match information. At this level the
 * method only knows how to iterate the different tabs.
 * \return Returns nil if the correct controller was not found.
 */
+ (UIViewController*)spawn_tag_controller:(FLRegex_match*)match
{
	return [FlokiAppDelegate spawn_controller:match
		selector:@selector(spawn_tag:)];
}

/// Just like spawn_tag_controller but for video.
+ (UIViewController*)spawn_video_controller:(FLRegex_match*)match
{
	return [FlokiAppDelegate spawn_controller:match
		selector:@selector(spawn_video:)];
}

/// Just like spawn_tag_controller but for galleries.
+ (UIViewController*)spawn_gallery_controller:(FLRegex_match*)match
{
	return [FlokiAppDelegate spawn_controller:match
		selector:@selector(spawn_gallery:)];
}

#pragma mark -
#pragma mark UIAlertViewDelegate protocol

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (abort_after_alert_) {
		DLOG(@"User closed dialog which aborts program. Bye bye!");
		exit(1);
	}
}

#pragma mark -
#pragma mark Cache methods

/** Verifies the cached data and prepares net background updates.
 * Call this function when the application is completely loaded.
 * The function will check the disk cache of the beacon data and set
 * up the scheduling for the online checks according to the specified ttl.
 *
 * Note that the date of the ttl is calculated based on the data
 * modification time, even though the ttl comes in the beacon file.
 */
- (void)check_cached_data
{
	NSTimeInterval diff = [self secondsToCacheExpiration];
	if (diff <= 0) {
		DLOG(@"Local beacon cache says data expired. Refetching.");
		[self performSelector:@selector(fetch_app_beacon)
			withObject:nil afterDelay:0.0];
	} else {
		diff += 1;
		DLOG(@"Cache not expired, retrying in %0.2f seconds", diff);
		/* Cache hasn't expired. Reschedule for the next check. */
		[self performSelector:@selector(check_cached_data)
			withObject:nil afterDelay:diff];
	}
}

/** Returns the number of seconds until the cache expires.
 * Will return negative if the time has already expired and will
 * return zero if there was a problem calculating the time.
 */
- (NSTimeInterval)secondsToCacheExpiration
{
	NSDictionary *beacon_data = _get_disk_app_data(FILE_BEACON_DATA);
	beacon_cached_version_ = [beacon_data get_int:@"v" def:0];
	const int ttl = [beacon_data get_int:@"ttl" def:0];
	NSFileManager *manager = [NSFileManager defaultManager];
	/* Get the modification time of the actual data cache. */
	NSDictionary *attributes = [manager
		attributesOfItemAtPath:get_path(FILE_APP_DATA, DIR_CACHE) error:nil];
	NSDate *modified = [attributes objectForKey:NSFileModificationDate];
	NSDate *expiration = [modified addTimeInterval:ttl];

	return [expiration timeIntervalSinceDate:[NSDate date]];
}

/** Registers in the database the required table identifiers for each cache.
 * The function asks each tab to register its own cache URL. Once
 * this is done, and all table identifiers are allocated, the function
 * will remove all database data that is unregistered.
 */
- (void)register_tables
{
	NSMutableDictionary *used = [NSMutableDictionary dictionaryWithCapacity:10];
	for (UINavigationController *nav in self.tab_controller.viewControllers) {
		NSObject <FLTab_protocol> *controller = (id)[nav topViewController];
		id number = [NSNumber numberWithInt:[controller unique_id]];
		if ([controller respondsToSelector:@selector(name_for_cache)]) {
			NSString *name_for_cache = [controller name_for_cache];
			[self register_tab:name_for_cache unique_id:[number intValue]];
		}
		[used setValue:@"" forKey:number];
	}

	/* Check unused entries. */
	NSMutableArray *unused = [NSMutableArray new];
	EGODatabaseResult *result = [self.db
		executeQuery:@"SELECT id, name FROM Owners"];
	for (EGODatabaseRow *row in result) {
		NSNumber *number = [NSNumber numberWithInt:[row intForColumn:@"id"]];
		if (![used objectForKey:number])
			[unused addObject:number];
	}
	[self.db remove_tabs:unused];
	[unused release];
}

/** Used by the tabs when called by register_tables to register the table.
 * Forms the string for the cache and updates it in the database if it exists.
 */
- (void)register_tab:(NSString*)name unique_id:(int)unique_id
{
	LASSERT(name, @"Need a name");

	if (![self.db register_tab:name unique_id:unique_id]) {
		LOG(@"Couldn't register tab, critical failure");
		abort();
	}
}

/** Closes the global application database.
 */
- (void)close_database
{
	[self.db close];
	self.db = nil;
}

/** Small handler to save a string with the beacon path.
 * If the path cannot be saved, returns NO.
 */
- (BOOL)save_as_beacon:(NSString*)data
{
	NSError *error = nil;
	NSString *path = get_path(FILE_BEACON_DATA, DIR_CACHE);
	BOOL ret = [data writeToFile:path atomically:YES
		encoding:NSUTF8StringEncoding error:&error];
	if (!ret)
		[self handle_error:error message:_e(13) abort_always:YES];
	// _13: Error saving beacon data
	return ret;
}

/** Clears the file and database caches.
 * The database cache is cleared at the file level, no need to open or purge.
 * The function will also set the settings of the application to
 *  avoid another cache cleanup in the next run. It will also initialise
 *  the size variable.
 */
- (void)clear_cache
{
	DLOG(@"Requested clearing of cache.");
	[SHK logoutOfAll];

	LASSERT(!self.db, @"Souldn't have database open... I think");
	NSError *error = nil;
	NSFileManager *manager = [NSFileManager defaultManager];

	NSString *path = get_path(FILE_APP_DATA, DIR_CACHE);
	if ([manager removeItemAtPath:path error:&error])
		DLOG(@"Deleted %@", path);
	else
		DLOG(@"Couldn't unlink %@: %@", path, error);

	path = get_path(FILE_BEACON_DATA, DIR_CACHE);
	if ([manager removeItemAtPath:path error:&error])
		DLOG(@"Deleted %@", path);
	else
		DLOG(@"Couldn't unlink %@: %@", path, error);

	path = [FLDB path];
	if ([manager removeItemAtPath:path error:&error])
		DLOG(@"Deleted %@", path);
	else
		DLOG(@"Couldn't unlink %@: %@", path, error);

	/* Set the application settings to reflect the cache cleanup change. */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:NO forKey:DEFAULTS_CLEAR_CACHE_ON_BOOT];
	[defaults setInteger:-1 forKey:LAST_VIEWED_ID];
	[defaults setInteger:-1 forKey:LAST_TAB];
	[defaults setObject:@"0 kB" forKey:DEFAULTS_CACHE_SIZE];
	[defaults synchronize];
}

/** Updates the application's cache size setting for user information.
 * Just like clear_cache, this will store in the setting the actual
 * physical size of all file caches, so it is unlikely that a user
 * will ever get to see a cache size of zero with normal usage because
 * for the application to *work* it will regenerate those files.
 */
- (void)update_cache_size_setting
{
	unsigned long long total_size = 0;
	NSFileManager *manager = [NSFileManager defaultManager];

	NSString *path = get_path(FILE_APP_DATA, DIR_CACHE);
	total_size += [[manager attributesOfItemAtPath:path error:nil] fileSize];
	path = get_path(FILE_BEACON_DATA, DIR_CACHE);
	total_size += [[manager attributesOfItemAtPath:path error:nil] fileSize];
	path = [FLDB path];
	total_size += [[manager attributesOfItemAtPath:path error:nil] fileSize];

	/* Set the application settings to reflect the cache cleanup change. */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *value = [NSString stringWithFormat:@"%0.2f kB",
		(float)total_size / 1000.0f];
	[defaults setObject:value forKey:DEFAULTS_CACHE_SIZE];
	[defaults synchronize];
	DLOG(@"Updated cache size setting to '%@'", value);
}

/** Tries to move files from the docs subdirectory to the cache one.
 * This method is run every time the app launches, but it only really does
 * something if the user is maintaining an old cache from a version 2.2 or
 * previous. Even though most of the time this method won't do anything, we
 * still run it because it is expected to be very cheap.
 */
- (void)preserve_old_files
{
	static NSString *names[] = { @"appdb",
		FILE_APP_DATA, FILE_BEACON_DATA, nil };

	NSFileManager *manager = [NSFileManager defaultManager];
	for (int f = 0; names[f]; f++) {
		NSString *old_path = get_path(names[f], DIR_DOCS);
		if (![manager fileExistsAtPath:old_path])
	        continue;
		NSString *new_path = get_path(names[f], DIR_CACHE);

		NSError *error = nil;
		if ([manager moveItemAtPath:old_path toPath:new_path error:&error]) {
			DLOG(@"Moved from %@ to %@", old_path, new_path);
		} else {
			DLOG(@"Couldn't move from %@ to %@: %@", old_path, new_path,
				error);
		}
	}
}

#pragma mark -
#pragma mark FLReachability handler

- (void)reachability_changed:(NSNotification*)note
{
	static BOOL did_loose_reachability = NO;

	/** Ignore notifications from other possible objects of other libraries. */
	if (![[note object] respondsToSelector:@selector(currentReachabilityStatus)])
		return;

	FLReachability *new_reachability = [note object];
	if (NotReachable == [new_reachability currentReachabilityStatus]) {
		if (!self.reachability_alert) {
			UIAlertView *alert = [[UIAlertView alloc]
				initWithTitle:_e(14) message:_e(15) delegate:nil
				cancelButtonTitle:_e(20) otherButtonTitles:nil];
			self.reachability_alert = alert;
			// _14: Connection lost
			// _15: The connection with the server has been lost...
			// _20: Accept
			self.reachability_alert.delegate = self;
			[self.reachability_alert show];
			[alert release];
			/* Mark we lost reachability. Otherwise app starts look dorky. */
			did_loose_reachability = YES;
		}
	} else {
		[SHK flushOfflineQueue];

		if (did_loose_reachability) {
			if (self.reachability_alert) {
				[self.reachability_alert dismissWithClickedButtonIndex:0
					animated:YES];
				self.reachability_alert = nil;
			}
		}

		DLOG(@"Restored server connection");
	}
}

@end

#pragma mark -
#pragma mark Global functions

/// \file FlokiAppDelegate.m

/** Extended function of NSClassFromString.
 * The function will prepend to the parameter the letters FL if not
 * present, and then validate the string against a list of valid class
 * names. If the string is not there, nil is returned, and the debug
 * build crashes.
 */
Class FLClassFromString(NSString *class_name)
{
	assert(class_name && "Null class name?");
	assert(class_name.length > 2 && "Absurdly small class name");
	assert(class_name.length < 30 && "Absurdly long class name");
	if (class_name.length < 2)
		return nil;

	if (!('F' == [class_name characterAtIndex:0] &&
		  'L' == [class_name characterAtIndex:1])) {
		class_name = [NSString stringWithFormat:@"FL%@", class_name];
	}

	static NSArray *valid = nil;
	if (!valid)
		valid = [[NSArray arrayWithObjects:@"FLGallery_view_controller",
			 @"FLNews_view_controller", @"FLWeb_view_controller",
			 @"FLMovie_view_controller", @"FLItem_view_controller",
			 @"FLPhoto_view_controller", nil] retain];

	for (NSString *test in valid)
		if ([class_name isEqualToString:test])
			return NSClassFromString(class_name);

	LOG(@"Unrecognised FLClassFromString for %@", class_name);
	assert(0 && "Reached end of FLClassFromString!");
	return nil;
}

/** Retrieves from disk stored data as a dictionary.
 * Returns nil with problems or when the stored data has to be purged.
 * One of this situations would be to force refetching the application
 * data if the current binary application version doesn't match the
 * disk one.
 */
static NSDictionary *_get_disk_app_data(NSString *name)
{
	assert(name);
	NSString* runtime_version = [[[NSBundle mainBundle] infoDictionary]
		objectForKey:@"CFBundleVersion"];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* last_version = [defaults stringForKey:LAST_VERSION];
	DLOG(@"Version is %@, last %@", runtime_version, last_version);
	if (![runtime_version isEqualToString:last_version])
		return nil;

	NSString *path = get_path(name, DIR_CACHE);
	NSString *response_string = [NSString stringWithContentsOfFile:path
		encoding:NSUTF8StringEncoding error:nil];
	return [response_string JSONValue];
}

/** Touches a file.
 *
 * Touch me, touch me harder! Doesn't do anything if there is nobody
 * receiving the touches, other than logging.
 */
static void _update_timestamp(const char *path)
{
	DLOG(@"Updating cached data timestamp of '%s'", path);
	struct utimbuf new_times;
	new_times.actime = new_times.modtime = time(0);
	if (utime(path, &new_times))
		DLOG(@"Couldn't update file timestamp!");
}

