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
#import "controllers/FLTab_controller.h"

#import "categories/NSDictionary+Floki.h"
#import "global/FLi18n.h"
#import "global/FlokiAppDelegate.h"
#import "global/settings.h"
#import "models/FLContent_item.h"
#import "protocols/FLTab_protocol.h"

#import "ELHASO.h"
#import "egf/hardware.h"

#import <UIKit/UIKit.h>

@interface FLTab_controller ()

- (NSArray*)build_tabs:(NSArray*)tab_data;
- (BOOL)init_or_validate:(NSDictionary*)data only_validate:(BOOL)only_validate;
- (void)process_delete_disk_cache:(NSArray*)strings;
- (void)process_slash_scaled:(NSArray*)strings;

@end


@implementation FLTab_controller

- (void)loadView
{
	[super loadView];
}

- (void)dealloc
{
	[super dealloc];
}

/** Assings the specified JSON data to the class.
 * You shouldn't do this more than once per life of the class.
 *
 * Returns NO if something went wrong.
 */
- (BOOL)init_app_data:(NSDictionary*)data
{
	return [self init_or_validate:data only_validate:NO];
}

/** Validates the passed dictionary as valid.
 * Internally the function does all the work of class
 * creation/initialisation, but without making it available to the
 * user. You can call this as many times as you want.
 *
 * Returns YES if the application would initialise correctly.
 */
- (BOOL)validate_app_data:(NSDictionary*)data
{
	return [self init_or_validate:data only_validate:YES];
}

/** The real code behind init_app_data and validate_app_data.
 * This will validate, and optionally init the app depending on the
 * value of only_validate. On top of that this will process the
 * global debug options in the protocol, like delete_disk_cache and
 * others.
 *
 * Returns YES if everything went fine.
 */
- (BOOL)init_or_validate:(NSDictionary*)data only_validate:(BOOL)only_validate
{
	if (only_validate)
		DLOG(@"Validation of app with %@", data);

	if (!data)
		return NO;

	FLi18n* langs = [[FLi18n alloc]
		init_with_langs:[data objectForKey:@"langs"]];
	if (!langs)
		return NO;

	if (only_validate) {
		[langs release];
	} else {
		[FLi18n set:langs];
		[langs release];
		LASSERT([[FLi18n get] current_langcode], @"Bad initialisation?");
	}

	NSArray *tabs = [self build_tabs:[data objectForKey:@"tabs"]];
	if (!tabs)
		return NO;

	if (!only_validate)
		self.viewControllers = tabs;

	/* Process the debug options of the protocol. */
	NSDictionary *misc = [data objectForKey:@"misc"];
	[self process_delete_disk_cache:[misc objectForKey:@"delete_disk_cache"]];
	[self process_slash_scaled:[misc objectForKey:@"slash_scaled_images"]];

	return YES;
}

/** Builds the tabs of the application from the input data.
 * Returns nil if something went wrong, or the tabs with the view controllers.
 */
- (NSArray*)build_tabs:(NSArray*)tab_data
{
	NSMutableArray *tabs = [NSMutableArray array];

	NSMutableDictionary *ids = [NSMutableDictionary new];
	for (NSDictionary *tab in tab_data) {
		NSString *long_title = [tab objectForKey:@"long_title"];
		NSString *short_title = [tab objectForKey:@"short_title"];
		if (!short_title)
			short_title = long_title;
		NSString *class_type = [tab objectForKey:@"class_type"];
		NSDictionary *data = [tab objectForKey:@"data"];
		LASSERT(long_title && short_title && class_type && data, @"Bad input");
		/* Verify presense and uniqueness of the tab key. */
		NSNumber *unique_id = [NSNumber numberWithInt:
			[tab get_int:@"unique_id" def:0]];
		LASSERT([unique_id intValue]> 0, @"Invalid or missing tab unique_id");
		NSString *unique_key = [NSString stringWithFormat:@"%d",
			unique_id.intValue];
		/* Abort if the unique_id is repeated. */
		if ([ids objectForKey:unique_key]) {
			LASSERT(0, @"Repeated unique_id value.");
			[tabs removeAllObjects];
			break;
		}
		[ids setObject:unique_id forKey:unique_key];

		/* Construct the navigation controller with view controller. */
		Class class = FLClassFromString(class_type);
		DLOG(@"Creating class from string '%@'", class_type);
		UIViewController *view_controller = [class new];
		if (!view_controller) {
			LASSERT(0, @"Couldn't create class from string.");
			[tabs removeAllObjects];
			break;
		}

		/* Trust classes to have init_with_data. */
		id <FLTab_protocol> protocol_cast = (id)view_controller;
		if (![protocol_cast init_with_data:data
				unique_id:[unique_id intValue]]) {
			[view_controller release];
			continue;
		}
		view_controller.title = _s(long_title);
		UINavigationController *navigation_controller =
			[[UINavigationController alloc]
				initWithRootViewController:view_controller];

		/* Extract base64 image for tabs. */
		UIImage *image = [tab get_image:@"tab_image" def:nil];

		UITabBarItem *item = [[UITabBarItem alloc]
			initWithTitle:_s(short_title) image:image tag:0];
		SET_ACCESSIBILITY_LANGUAGE(item);
		navigation_controller.tabBarItem = item;
		SET_ACCESSIBILITY_LANGUAGE(navigation_controller);
		[item release];

		[tabs addObject:navigation_controller];
		[navigation_controller release];
		[view_controller release];
	}

	[ids release];
	if ([tabs count] > 0)
		return [NSArray arrayWithArray:tabs];
	else
		return nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/** Pass an array of string with potential UDIDs to disable disck cache for.
 * If your current UDID is found in the array, the preferences
 * variable used to clear the cache in the next run will be set to
 * true. The special string simulator will also be recognised if you
 * are running on a simulator.
 */
- (void)process_delete_disk_cache:(NSArray*)strings
{
	Hardware_info *info = get_hardware_info();
	if (!info) {
		DLOG(@"Couldn't get hardware info!");
		return;
	}

	BOOL disable_cache = NO;
	if (HW_UNKNOWN == info->family || HW_SIMULATOR == info->family) {
		for (NSString *udid in strings) {
			if ([udid isEqualToString:@"simulator"]) {
				disable_cache = YES;
				break;
			}
		}
	} else {
		NSString *my_udid = [NSString stringWithUTF8String:info->udid];
		DLOG(@"Our udid is %@", my_udid);

		for (NSString *udid in strings) {
			if ([my_udid isEqualToString:udid]) {
				disable_cache = YES;
				break;
			}
		}
	}

	if (disable_cache) {
		DLOG(@"Setting %@ to YES!", DEFAULTS_CLEAR_CACHE_ON_BOOT);
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool:YES forKey:DEFAULTS_CLEAR_CACHE_ON_BOOT];
	}

	destroy_hardware_info(&info);
}

/** Pass an array of string with potential UDIDs to enable image slashing.
 * If your current UDID is found in the array, the global
 * gSlash_scaled_images will be turned on and most scaled images will
 * be slashed.
 */
- (void)process_slash_scaled:(NSArray*)strings
{
	Hardware_info *info = get_hardware_info();
	if (!info) {
		DLOG(@"Couldn't get hardware info!");
		return;
	}

	if (HW_UNKNOWN == info->family || HW_SIMULATOR == info->family) {
		for (NSString *udid in strings) {
			if ([udid isEqualToString:@"simulator"]) {
				gSlash_scaled_images = YES;
				break;
			}
		}
	} else {
		NSString *my_udid = [NSString stringWithUTF8String:info->udid];
		DLOG(@"Our udid is %@", my_udid);

		for (NSString *udid in strings) {
			if ([my_udid isEqualToString:udid]) {
				gSlash_scaled_images = YES;
				break;
			}
		}
	}

	if (gSlash_scaled_images)
		DLOG(@"Activating image debug mode: slashing scaled");

	destroy_hardware_info(&info);
}

/** Stores in the user defaults the currently used tab and item.
 * This method is called when the application is going to exit, so
 * it has to be quick. It simply stores the index of the currently
 * selected tab. Then sends a message to the selected tab to check
 * if the user is viewing a specific item and save that identifier
 * too.
 *
 * These saves are done for the purpose of recovering the previous
 * application state when the user returns.
 *
 * Note that this function doesn't explicitly sync the application
 * user defaults dictionary, you have to do it yourself.
 */
- (void)remember_current_tab_and_item
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:self.selectedIndex forKey:LAST_TAB];

	id tab = self.selectedViewController;
	UIViewController *controller = ASK_GETTER(tab, visibleViewController, nil);
	FLContent_item *item = ASK_GETTER(controller, item, nil);
	NSNumber *item_id = ASK_GETTER(controller, item_id, nil);
	int id_to_save = item ? item.id_ : (item_id ? [item_id intValue] : -1);

	DLOG(@"Saving last viewed id to %d", id_to_save);
	[defaults setInteger:id_to_save forKey:LAST_VIEWED_ID];
}

/** Returns the index of the tab showing this item identifier.
 * This function will iterate through all available tabs and ask
 * each controller if it holds a pointer to the specified item. If
 * yes, the tab index will be returned. If the item is not found on
 * any tab, a negative value is returned.
 */
- (int)tab_for_item_id:(int)item_id
{
	int index = 0;
	for (id tab_controller in self.viewControllers) {
		index++;
		NSArray *controllers = ASK_GETTER(tab_controller, viewControllers, nil);
		for (id controller in controllers) {
			if (![controller respondsToSelector:@selector(items)])
				continue;

			NSArray *items = [controller items];
			for (FLContent_item *item in items)
				if (item_id == item.id_)
					return index - 1;
		}
	}

	return -1;
}

@end
