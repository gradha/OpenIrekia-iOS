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
#import "controllers/FLContent_view_controller.h"

#import "categories/NSString+Floki.h"
#import "controllers/FLSection_state.h"
#import "global/FLDB.h"
#import "global/FLi18n.h"
#import "global/settings.h"
#import "ipad/FLISplit_view_controller.h"
#import "models/FLContent_item.h"
#import "net/FLMeta_data_connection.h"

#import "ELHASO.h"
#import "UIActivity.h"

#import <QuartzCore/CALayer.h>


#define _ACTIVITY_SIZE				40
#define _SHIELD_TAG					666
#define _SHIELD_IMAGE_TAG			667
#define _SHIELD_LABEL_TAG			668


@interface FLContent_view_controller ()
- (void)reposition_activity_indicator;
- (NSString*)replace_tags:(NSString*)text item:(id)item;
@end


@implementation FLContent_view_controller

@synthesize base_url = base_url_;
@synthesize cache_token = cache_token_;
@synthesize forced_url = forced_url_;
@synthesize ignore_updates = ignore_updates_;
@synthesize items = items_;
@synthesize requested_url = requested_url_;
@synthesize right_button = right_button_;
@synthesize same_window_push = same_window_push_;

#pragma mark -
#pragma mark Methods

/** Handles creation of the view, pseudo constructor.
 */
- (void)loadView
{
	[super loadView];

	self.view.frame = self.view.bounds;

	/* Create a hidden loading indicator. */
	activity_indicator_ = [[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activity_indicator_.userInteractionEnabled = NO;
	activity_indicator_.frame = CGRectInset(activity_indicator_.bounds, -5, -5);
	activity_indicator_.center = self.view.center;
	activity_indicator_.autoresizingMask = FLEXIBLE_MARGINS;
	activity_indicator_.contentMode = UIViewContentModeCenter;
	activity_indicator_.backgroundColor = [UIColor colorWithRed:0
		green:0 blue:0 alpha:0.3];
	activity_indicator_.layer.cornerRadius = 5;
	[self.view addSubview:activity_indicator_];

	/* Create a label for error messages. */
	error_label_ = [[UILabel alloc] initWithFrame:self.view.bounds];
	error_label_.numberOfLines = 0;
	error_label_.hidden = YES;
	error_label_.textAlignment = UITextAlignmentCenter;
	error_label_.autoresizingMask = FLEXIBLE_SIZE;
	[self.view addSubview:error_label_];

	/* Create a hidden view for the shield image. */
	UIView *shield = [[UIView alloc] initWithFrame:self.view.bounds];
	shield.backgroundColor = [UIColor whiteColor];
	shield.alpha = 0;
	shield.hidden = YES;
	shield.tag = _SHIELD_TAG;
	shield.contentMode = UIViewContentModeScaleAspectFit;
	shield.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;

	UIImageView *image = [[UIImageView alloc]
		initWithImage:[UIImage imageNamed:@"shield.png"]];
	image.tag = _SHIELD_IMAGE_TAG;
	CGRect rect = image.frame;
	CGSize size = self.view.bounds.size;
	rect.origin.x = (size.width - rect.size.width) / 2;
	rect.origin.y = 0;
	image.frame = rect;
	[shield addSubview:image];
	[image release];

	UILabel *label = [[UILabel alloc]
		initWithFrame:CGRectMake(0, rect.size.height, size.width, 30)];
	label.tag = _SHIELD_LABEL_TAG;
	label.backgroundColor = [UIColor clearColor];
	label.text = _e(16);
	// _16: Connecting to the server...
	label.textAlignment = UITextAlignmentCenter;
	[shield addSubview:label];
	[label release];

	[self.view addSubview:shield];
	[shield release];

	/* Get notified of landscape changes. */
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(reposition_activity_indicator)
		name:UIDeviceOrientationDidChangeNotification object:nil];
}

/** Frees up all resources.
 */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[connection_ cancel];
	[connection_ release];
	[right_button_ release];
	[items_ release];
	[error_label_ release];
	[activity_indicator_ release];
	[requested_url_ release];
	[base_url_ release];
	[forced_url_ release];
	[super dealloc];
}

/// Clones into the receiver the properties which make sense.
- (void)copy_from:(FLContent_view_controller*)other
{
	self.requested_url = other.requested_url;
	self.base_url = other.base_url;
	self.forced_url = other.forced_url;
	self.ignore_updates = other.ignore_updates;
	self.same_window_push = self.same_window_push;
}

/** Sets the list of items.
 * Automatically updates max_item_id_ and min_item_id_. They will
 * be set to zero if the list of items is empty.
 */
- (void)setItems:(NSArray*)new_items
{
	if (items_ == new_items)
		return;

	[new_items retain];
	[items_ release];
	items_ = new_items;

	max_item_id_ = 0;
	min_item_id_ = INT_MAX;
	// Remember to skip the values which are zero, we consider those invalid.
	for (FLContent_item *item in items_) {
		const int value = item.id_;
		if (!value)
			continue;
		max_item_id_ = MAX(max_item_id_, value);
		min_item_id_ = MIN(min_item_id_, value);
	}

	if (INT_MAX == min_item_id_)
		min_item_id_ = 0;
}

/** Requests the object to start polling the remote server for news.
 * Previously this code was in loadView, but since we must restore
 * the state of the viewed items, we may want to postpone network
 * checking until the user reaches the main screen. Otherwise the
 * network fetch would cancel the browsing of the item due to sections.
 *
 * Call this as many times as you want, it will only work once.
 *
 * The class is expected to override the fetch_content method.
 */
- (void)start_doing_network_fetches
{
	BLOCK_UI();
	if (already_doing_network_fetches_)
		return;

	already_doing_network_fetches_ = YES;
	/* Set up periodic updates. Find out when we have to start checking. */
	NSDate *fire_date = 0;
	if (download_if_virgin_ || self.forced_url.length) {
		fire_date = [NSDate date];
	} else {
		FLDB *db = [FLDB get_db];
		fire_date = [[db get_tab_timestamp:unique_id_] addTimeInterval:ttl_];
	}

	//DLOG(@"Fire date for %@ set to %@", langcode_url_, fire_date);
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:fire_date interval:ttl_
		target:self selector:@selector(fetch_content:) userInfo:nil
		repeats:self.forced_url.length < 1];

	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[timer release];
}

/** Starts the download of the content.
 * The downloading is done through a FLMeta_data_connection, which
 * may have the contents already cached. Pass the FLContent_item object,
 * database cache parameters and the function that will receive the
 * connection response. You are allowed to pass nil as the item, which
 * will cancel previous downloads.
 *
 * The force parameter is passed straight to the FLMeta_data_connection
 * object, stating if you want to ignore the content from disk and
 * request again from the network.
 */
- (void)download_content:(FLContent_item*)item selector:(SEL)selector
	target:(id)target cache_type:(CACHE_TYPE)cache_type
	cache_tables:(NSString**)cache_tables force:(BOOL)force
{
	LASSERT(base_url_, @"Base url not initialised");
	LASSERT(cache_token_, @"db_cache not initialised");

	if (!activity_indicator_)
		[self loadView];

	self.navigationItem.title = item.title;

	if (!connection_)
		connection_ = [[FLMeta_data_connection alloc]
			init_with_action:selector target:target];
	else
		[connection_ cancel];

	if (item) {
		if ([self.base_url length] > 0 && [item.url isRelativeURL])
			self.requested_url = [NSString stringWithFormat:@"%@/%@",
				self.base_url, item.url];
		else
			self.requested_url = item.url;

		self.requested_url = [self prettify_request_url:self.requested_url];

		connection_.dont_cache = item.online;

		[activity_indicator_ startAnimating];
		[connection_ request:self.requested_url news_id:item.id_
			cache_token:cache_token_ cache_type:cache_type
			cache_tables:cache_tables force:force];
	}
}

/** Called just when the view is going to appear.
 * At this point we know the size of the screen, so we can adjust ourselves.
 * Also simulates warnings to force proper implementations of memory.  The
 * warning will be queued so it happens after all the hierarchy of
 * viewDidAppear calls is run.
 */
- (void)viewDidAppear:(BOOL)animated
{
	[self reposition_activity_indicator];
	[super viewDidAppear:animated];
#if TARGET_IPHONE_SIMULATOR
	[self performSelectorOnMainThread:@selector(simulate_memory_warning)
		withObject:nil waitUntilDone:NO];
}

/// Selector called by the viewDidAppear callback.
- (void)simulate_memory_warning
{
	simulate_memory_warning();
	DLOG(@"Simulated memory warning");
#endif // TARGET_IPHONE_SIMULATOR
}

/** Allow landscape view. */
- (BOOL)shouldAutorotateToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/** Called whenever the layout changes (think orientation).
 * Repositions the activity view indicator to always be centered.
 */
- (void)reposition_activity_indicator
{
	CGRect rect = self.view.frame;

	// Also reposition center of the shield image and its label.
	UIView *image = [self.view viewWithTag:_SHIELD_IMAGE_TAG];
	rect = image.frame;
	CGSize size = self.view.bounds.size;
	rect.origin.x = (size.width - rect.size.width) / 2;
	rect.origin.y = 0;
	image.frame = rect;

	UIView *label = [self.view viewWithTag:_SHIELD_LABEL_TAG];
	label.frame = CGRectMake(0, rect.size.height, size.width, 30);
}

/** Shows the error message, stopping any pending activity animation.
 * The message is constructed with three lines, the one you pass,
 * and two from the error object.
 *
 * Actually, you call this method inconditionally, and the method
 * returns YES if the error was shown to the user. Avoids the tedious
 * if in calling code.
 */
- (BOOL)show_error:(NSString*)message error:(NSError*)error
{
	if (!error)
		return NO;

	[self show_error:[NSString stringWithFormat:@"%@\n\n%@",
		message, error.localizedDescription]];
	return YES;
}

/** Shows the error message, stopping any pending activity animation.
 */
- (void)show_error:(NSString*)message
{
	error_label_.text = message;
	error_label_.hidden = NO;
	[self.view bringSubviewToFront:error_label_];
	[activity_indicator_ stopAnimating];
}

/** Constructs the right button.
 * Pass the selector of the action you want to target with the button. The
 * button will be stored in the right_button property and by default it will be
 * disabled.
 */
- (void)show_right_button:(SEL)action item:(UIBarButtonSystemItem)item
{
	UIBarButtonItem *b =[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:item target:self action:action];
	b.enabled = NO;
	self.navigationItem.rightBarButtonItem = b;
	[right_button_ release];
	right_button_ = [b retain];
	[b release];
}

/** Generates the mail composer view with the parameters.
 */
- (void)show_mail_composer:(FLContent_item*)item
	subject:(int)subject_id body:(int)body_id
{
	LASSERT([MFMailComposeViewController canSendMail], @"No email?");
	if (![MFMailComposeViewController canSendMail])
		return;

	NSString *subject = _(subject_id);
	NSString *body = _(body_id);

	// Replace tags with attributes from the item.
	subject = [self replace_tags:subject item:item];
	body = [self replace_tags:body item:item];

	MFMailComposeViewController *mail =
		[[MFMailComposeViewController alloc] init];
	mail.mailComposeDelegate = self;
	[mail setSubject:subject];
	[mail setMessageBody:body isHTML:YES];
	[self presentModalViewController:mail animated:YES];
	[mail release];
}

/** Shows the mail composer addressed at the mail address.
 */
- (void)show_mail_composer:(NSString*)to_address
{
	LASSERT([MFMailComposeViewController canSendMail], @"No email?");
	if (![MFMailComposeViewController canSendMail])
		return;

	MFMailComposeViewController *mail =
		[[MFMailComposeViewController alloc] init];
	mail.mailComposeDelegate = self;
	[mail setToRecipients:[NSArray arrayWithObject:to_address]];
	[self presentModalViewController:mail animated:YES];
	[mail release];
}

/** Replaces in text the tags extracted from the content item.
 * nil attributes in FLContent_item will be replaced by empty strings.
 */
- (NSString*)replace_tags:(NSString*)text item:(id)item
{
#define _REPLACE(TAG,ATTR) do {												\
	if ([item respondsToSelector:@selector(ATTR)])							\
		text = [text stringByReplacingOccurrencesOfString:TAG				\
			withString:NON_NIL_STRING(										\
				[item performSelector:@selector(ATTR)])];					\
	else																	\
		text = [text stringByReplacingOccurrencesOfString:TAG				\
			withString:@""];\
} while (0)

	_REPLACE(@"<PHOTO_DESC>", caption_text);
	_REPLACE(@"<TITLE>", title);
	_REPLACE(@"<URL>", share_url);

#undef _REPLACE
	return text;
}

/** Ugly hack to return predefined sizes depending of orientation.
 */
- (CGSize)get_visible_area
{
	CGRect app_frame = [[UIScreen mainScreen] applicationFrame];
	if (320 == app_frame.size.width && 460 == app_frame.size.height) {
		return CGSizeMake(320, 480);
	} else if (300 == app_frame.size.width && 480 == app_frame.size.height)
		return CGSizeMake(480, 320);
	else if (320 == app_frame.size.width || 480 == app_frame.size.height) {
		return CGSizeMake(320, 480);
	} else if (320 == app_frame.size.width || 480 == app_frame.size.height) {
		return CGSizeMake(480, 320);
	} else if (1024 == app_frame.size.width || 768 == app_frame.size.height) {
		return CGSizeMake(1024, 768);
	} else if (768 == app_frame.size.width || 1024 == app_frame.size.height) {
		return CGSizeMake(768, 1024);
	} else if (640 == app_frame.size.width || 960 == app_frame.size.height) {
		return CGSizeMake(640, 960);
	} else if (960 == app_frame.size.width || 640 == app_frame.size.height) {
		return CGSizeMake(960, 640);
	} else {
		DLOG(@"Warning: unknown device size, frame %0.1fx%0.1f",
			app_frame.size.width, app_frame.size.height);
		return self.view.bounds.size;
	}
}

/** Special visibility area version for iPad.
 * For the iPad version we need to hack the landscape sizes, since
 * in landscape there is actually no full screen mode. So the
 * landscape verision doesn't return the full size but the full size
 * minus the master view.
 */
- (CGSize)get_ipad_visible_area
{
	if (IS_IPAD) {
		CGSize size = [[UIScreen mainScreen] applicationFrame].size;
		if (748 == size.width) {
			size.width = 1024 - 320;
			size.height = 768;
		} else {
			size.width = 768;
			size.height = 1024;
		}
		const CGRect rect = [[UIApplication sharedApplication] statusBarFrame];
		const CGFloat offset = MIN(rect.size.width, rect.size.height);
		size.height -= offset;
		return size;
	} else {
		return [self get_visible_area];
	}
}

/** Puts in front of all views a shield screen.
 * The purpose of this shield screen is to show the user a log image
 * while the first contents of the view/table are loaded. On top
 * of the shield screen the activity icon is shown.
 *
 * You can call this method any time, even from background threads, because it
 * will run on the UI thread always.
 */
- (void)show_shield_screen
{
	if ([NSThread isMainThread])
		[self performSelector:@selector(show_shield_screen_worker)
			withObject:nil];
	else
		[self performSelectorOnMainThread:@selector(show_shield_screen_worker)
			withObject:nil waitUntilDone:YES];
}

/// Actual code run by show_shield_screen.
- (void)show_shield_screen_worker
{
	BLOCK_UI();
	UIView *shield = [self.view viewWithTag:_SHIELD_TAG];
	[shield retain];
	[shield removeFromSuperview];
	shield.hidden = NO;
	shield.alpha = 1;
	[self.view addSubview:shield];
	[shield release];

	/* Put again the activity_indicator_ in front. */
	[activity_indicator_ removeFromSuperview];
	[self.view addSubview:activity_indicator_];
	[activity_indicator_ startAnimating];
}

/** Fades out the shield screen to show the contents of the view.
 * This also implicitly stops the activity indicator.
 */
- (void)hide_shield_screen
{
	if ([NSThread isMainThread])
		[self performSelector:@selector(hide_shield_screen_worker)
			withObject:nil];
	else
		[self performSelectorOnMainThread:@selector(hide_shield_screen_worker)
			withObject:nil waitUntilDone:YES];
}

/// Actual code run by hide_shield_screen
- (void)hide_shield_screen_worker
{
	BLOCK_UI();
	UIView *shield = [self.view viewWithTag:_SHIELD_TAG];

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1];
	shield.alpha = 0;
	[UIView commitAnimations];

	[activity_indicator_ stopAnimating];
}

/** Sorts and purges unwanted items in the mutable array.
 * This is a common method to process FLContent_item elements.
 * First, the array will be sorted. Then, items will be removed
 * according to the to_delete array. Later expiration date elements
 * will be removed. Finally, the dataset will be trimmed to the maximum
 * size of allowed elements.
 *
 * As a special case, news controller with a forced URLs won't purge items by
 * date, or cache size.
 */
- (void)sort_and_purge_items:(NSMutableArray*)data
	to_delete:(NSArray*)to_delete
{
	DONT_BLOCK_UI();
	/* Sort items by sorting identifier. */
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc]
		initWithKey:@"sort_id_" ascending:NO];
	[data sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];

	/* Removed items as requested by server. */
	if (data.count && to_delete) {
		for (NSNumber *bad_num in to_delete) {
			const int bad_id = [bad_num intValue];
			for (int f = 0; f < data.count; f++) {
				FLContent_item *item = [data objectAtIndex:f];
				if (bad_id == item.id_) {
					[data removeObjectAtIndex:f];
					break;
				}
			}
		}
	}

	if (self.forced_url.length)
		return;

	/* Remove elements whose expiration date was reached. */
	const int now = time(0);
	for (int f = 0; f < data.count; f++) {
		FLContent_item *item = [data objectAtIndex:f];
		if (item.expiration_date > 0 && item.expiration_date < now) {
			DLOG(@"Removing item due to expiration date %d",
				item.expiration_date);
			[data removeObjectAtIndex:f--];
		}
	}
}

/** Takes the specified array of items and saves it to disk cache.
 * Pass the parent table that will be used in the disk cache along
 * with the data tables that will be purged of old elements. The
 * function will look at the lowest id of the items and purge everything
 * below that. For this reason you need to pass the owner id of the
 * database, which is usually the unique identifier of the tab calling
 * this function.
 */
- (void)save_items_to_cache:(NSArray*)items parent_table:(NSString*)parent_table
	data_tables:(NSString**)data_tables owner_id:(int)owner_id
	max_elements:(int)max_elements
{
	RASSERT(self.forced_url.length < 1, @"Saving to disk forced url?", return);
	DONT_BLOCK_UI();
	FLDB *db = [FLDB get_db];
	int lowest_id = -1;

	[db beginTransaction];
	int saved_items = 0;
	for (FLContent_item *item in items) {
		NSString *json_string = [item create_json];
		if (json_string.length < 1)
			continue;

		[db save_meta_item:parent_table data:json_string
			the_id:item.id_ owner:owner_id];
		saved_items++;

		if (lowest_id < 0)
			lowest_id = item.id_;
		else
			lowest_id = MIN(lowest_id, item.id_);

		if (saved_items >= max_elements)
			break;
	}
	[db commitTransaction];

	[db purge_stale_meta_items:parent_table data_tables:data_tables
		lowest_id:lowest_id owner:owner_id];
	/* Indicate for the future the last time the cache was updated. */
	[db touch_tab_timestamp:owner_id];
}

/** Pushes a view controller.
 * This is a special wrapper around the typical pushViewController
 * method. On the iPhone it does the usual thing, but on the ipad it
 * intercepts the message and replaces the split view controller
 * detail view if self.same_window_push is set to NO (the default).
 */
- (void)push_controller:(UIViewController*)controller animated:(BOOL)animated
{
	if (IS_IPAD && !self.same_window_push) {
		/* Try to traverse upwards the hierarchy for the split controller. */
		id parent = ASK_GETTER(self, splitViewController,
			self.navigationController.parentViewController);
		while (parent) {
			if ([parent isKindOfClass:[FLISplit_view_controller class]]) {
				FLISplit_view_controller *split_controller = parent;
				[split_controller set_detail_controller:controller];
				return;
			} else {
				SEL get_parent = @selector(parentViewController);
				if ([parent respondsToSelector:get_parent])
					parent = [parent performSelector:get_parent withObject:nil];
				else
					parent = nil;
			}
		}
	}
	// Propagate same_window_push attribute if possible.
	if ([controller respondsToSelector:@selector(setSame_window_push:)]) {
		FLContent_view_controller *c = (id)controller;
		c.same_window_push = self.same_window_push;
	}
	[self.navigationController pushViewController:controller animated:animated];
}

/** Returns the url with device and min/max info.
 * The function doesn't check if it has been called before, so take
 * care. It only verifies that no previous quote has been used to
 * separate other potential parameters which might already exist.
 *
 * Returns the newly formated URL as autoreleased string (even if
 * there were no changes in the string format). Retain it if you need
 * it.
 */
- (NSString*)prettify_request_url:(NSString*)url
{
	if (!url)
		return nil;

	NSMutableArray *params = [NSMutableArray arrayWithCapacity:3];
	const int device_id = get_device_identifier();
	if (device_id > 0)
		[params addObject:[NSString stringWithFormat:@"d=%d", device_id]];

	if (min_item_id_ > 0)
		[params addObject:[NSString stringWithFormat:@"l=%d", min_item_id_]];

	if (max_item_id_ > 0)
		[params addObject:[NSString stringWithFormat:@"h=%d", max_item_id_]];

	if (params.count < 1)
		return [NSString stringWithString:url];

	NSString *p = [params componentsJoinedByString:@"&"];
	NSRange range = [url rangeOfString:@"?"];
	if (NSNotFound == range.location)
		return [url stringByAppendingFormat:@"?%@", p];
	else
		return [url stringByAppendingFormat:@"&%@", p];
}

/** Like the instance version, but doesn't add min/max info, there is none.
 */
+ (NSString*)prettify_request_url:(NSString*)url
{
	if (!url)
		return nil;

	const int device_id = get_device_identifier();
	if (device_id < 1)
		return [NSString stringWithString:url];

	NSRange range = [url rangeOfString:@"?"];
	if (NSNotFound == range.location)
		return [url stringByAppendingFormat:@"?d=%d", device_id];
	else
		return [url stringByAppendingFormat:@"&d=%d", device_id];
}

/** Prettifies an URL with additional older than parameter.
 * Like the instance version, but if add_older is YES, the returned string will
 * also have appended the sort_id of the last element in self.items.
 */
- (NSString*)prettify_request_url:(NSString*)url add_older:(BOOL)add_older
{
	NSString *ret = [self prettify_request_url:url];
	if (!add_older || self.items.count < 1)
		return ret;

	/// Pick the last sort id of the list.
	int param = 0;
	for (FLContent_item *item in [self.items reverseObjectEnumerator]) {
		const int value = item.id_;
		if (value) {
			param = value;
			break;
		}
	}
	if (!param)
		return ret;

	NSRange range = [ret rangeOfString:@"?"];
	if (NSNotFound == range.location)
		return [ret stringByAppendingFormat:@"?o=%d", param];
	else
		return [ret stringByAppendingFormat:@"&o=%d", param];
}


#pragma mark UIActionSheet

/** Builds and presents an action sheet with content sharing options.
 */
- (void)show_share_actions:(int)title_id
{
	[self cancel_previous_action_sheet];

	last_sheet_ = [[UIActionSheet alloc]
		initWithTitle:_(title_id) delegate:self cancelButtonTitle:nil
		destructiveButtonTitle:nil otherButtonTitles:nil];

	[last_sheet_ addButtonWithTitle:_(STR_COPY_TO_CLIPBOARD)];
	if ([MFMailComposeViewController canSendMail])
		[last_sheet_ addButtonWithTitle:_(STR_SEND_EMAIL)];

	[last_sheet_ addButtonWithTitle:_(STR_TWITTER_BUTTON)];
	[last_sheet_ addButtonWithTitle:_(STR_FACEBOOK_BUTTON)];
	[last_sheet_ addButtonWithTitle:_(STR_CANCEL_ACTION)];
	last_sheet_.cancelButtonIndex = last_sheet_.numberOfButtons - 1;

	if (IS_IPAD) {
		id split_view = ASK_GETTER(self, splitViewController, nil);
		ASK_GETTER(split_view, dismiss_pop_over, nil);
		[last_sheet_ performSelector:@selector(showFromBarButtonItem:)
			withObject:self.right_button];
	} else {
		[last_sheet_ showInView:self.view];
	}
}

/** If there is an action sheet, it will be cancelled.
 * This is a hook helper for the iPad, where pressing the section
 * popover should cancel the share action.
 */
- (void)cancel_previous_action_sheet
{
	if (last_sheet_) {
		[last_sheet_
			dismissWithClickedButtonIndex:last_sheet_.cancelButtonIndex
			animated:NO];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet
	clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (![self respondsToSelector:@selector(handle_action:)])
		return;

	if (actionSheet.cancelButtonIndex == buttonIndex) {
		DLOG(@"Actionsheet cancelled.");
		NSNumber *param = [NSNumber numberWithInt:ACTION_CANCEL];
		[self performSelector:@selector(handle_action:) withObject:param];
		return;
	}

	Action_button action = ACTION_UNKNOWN;
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
	if ([title isEqualToString:_(STR_COPY_TO_CLIPBOARD)])
		action = ACTION_COPY_URL;
	else if ([title isEqualToString:_(STR_SEND_EMAIL)])
		action = ACTION_MAIL_URL;
	else if ([title isEqualToString:_(STR_TWITTER_BUTTON)])
		action = ACTION_TWIT_URL;
	else if ([title isEqualToString:_(STR_FACEBOOK_BUTTON)])
		action = ACTION_FACEBOOK_URL;

	NSNumber *param = [NSNumber numberWithInt:action];
	[self performSelector:@selector(handle_action:) withObject:param];
}

- (void)actionSheet:(UIActionSheet *)actionSheet
	willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	LASSERT(last_sheet_, @"Uh oh, not tracking properly the action sheets.");
	[last_sheet_ release];
	last_sheet_ = nil;
}

#pragma mark MFMailComposeViewControllerDelegate

/** Forces dismissing of the view, only logging the error, not dealing with it.
 */
- (void)mailComposeController:(MFMailComposeViewController*)controller
	didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	DLOG(@"Did mail fail? %@", error);
	[self dismissModalViewControllerAnimated:YES];
}

@end
