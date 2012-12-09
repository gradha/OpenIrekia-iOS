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
#import "gallery/FLGallery_view_controller.h"

#import "categories/NSDictionary+Floki.h"
#import "categories/NSString+Floki.h"
#import "controllers/FLWeb_view_controller.h"
#import "gallery/FLGallery_cell.h"
#import "global/FLDB.h"
#import "global/FLMore_cell.h"
#import "global/FLi18n.h"
#import "global/FlokiAppDelegate.h"
#import "global/settings.h"
#import "models/FLGallery_item.h"
#import "models/FLMore_item.h"
#import "net/FLRemote_connection.h"
#import "protocols/FLItem_delegate.h"
#import "structures/FLGallery_cell_data.h"
#import "structures/FLPagination_info.h"
#import "structures/FLRegex_match.h"

#import "ELHASO.h"
#import "SBJson.h"
#import "UIColor+RRUIKit.h"


static NSString *_PARENT_TABLE = @"Gallery_items";
static NSString *_DATA_TABLES[] = { @"Gallery_thumbs", @"Gallery_images", nil };


@interface FLGallery_view_controller ()
- (void)fetch_content:(NSTimer*)theTimer;

- (void)process_items:(NSArray*)new_items to_delete:(NSArray*)to_delete
	has_older:(BOOL)has_older;

- (int)num_rows;

- (void)did_select_item:(FLGallery_item*)item
	indexPath:(NSIndexPath*)indexPath animated:(BOOL)animated;
@end


@implementation FLGallery_view_controller

@synthesize cell_data = cell_data_;
@synthesize gallery_url = gallery_url_;
@synthesize more_item = more_item_;

#pragma mark -
#pragma mark Methods

/** Pseudo constructor, pass JSON dictionary.
 * Stores all the required data for later use. Doesn't actually
 * modify anything else.
 */
- (BOOL)init_with_data:(NSDictionary*)data unique_id:(int)unique_id
{
	LASSERT(!self.cell_data, @"Double initialization");
	FLGallery_cell_data *cell_data = [FLGallery_cell_data new];
	if (!cell_data) {
		LOG(@"Not enough memory to allocate gallery cell data");
		return NO;
	}
	self.cell_data = cell_data;
	[cell_data release];

	unique_id_ = unique_id;
	self.gallery_url = [data get_string:@"gallery_url" def:nil];
	self.url = [data get_string:@"main_url" def:nil];
	self.base_url = [self.url stringByRemovingFragment];
	cell_data->padding = [data get_int:@"padding" def:2];
	self.row_height = [data get_int:@"row_height" def:79];
	cell_data->cells_per_row = [data get_int:@"cells_per_row" def:4];
	cell_data.normal_color = [data get_color:@"cell_normal_color"
		def:[UIColor whiteColor]];
	cell_data.highlight_color = [data get_color:@"cell_highlight_color"
		def:[UIColor blueColor]];

	cache_size_ = [data get_int:@"cache_size" def:50];
	ttl_ = [data get_int:@"ttl" def:300];
	download_if_virgin_ = [data get_bool:@"download_if_virgin" def:NO];
	cell_data->stretch_images = [data get_bool:@"stretch_images" def:YES];

	if (!self.url || cache_size_ < 1 || ttl_ < 1 ||
			cell_data->cells_per_row < 1 ||
			cell_data->padding < 1 || self.row_height < 1 || unique_id_ < 1 ||
			cell_data->padding * 2 >= self.row_height) {
		LOG(@"Failed initialisation of FLGallery_view_controller %@", data);
		return NO;
	}
	last_item_selected_ = -1;

	/* Calculate the size of the cells. */
	cell_data->image_size.height = self.row_height - 2 * cell_data->padding;
	cell_data->image_size.width = (int)((320.0f - 2 * cell_data->padding) /
		(float)cell_data->cells_per_row - 2 * cell_data->padding);

	/* For ipads, increase the number of cells per row. */
	if (IS_IPAD) {
		cell_data->cells_per_row = (int)((gallery_width()
				- 2 * cell_data->padding) /
			(float)(cell_data->image_size.width + 2 * cell_data->padding));
	}

	cell_data->start_x = (gallery_width() - (cell_data->cells_per_row *
		(cell_data->image_size.width + 2 * cell_data->padding))) / 2;

	if (cell_data->image_size.width < 1 ||
			cell_data->start_x < cell_data->padding) {
		LOG(@"Failed initialisation of Gallery cell width %@", data);
		return NO;
	}

	// Register the regular expressions.
	for (NSString *regex in [data get_array:@"gallery_regex"
			of:[NSString class] def:nil])
		[FLWeb_view_controller register_gallery_regex:regex
			unique_id:unique_id_];

	/* Optional  */
	if ([data get_bool:@"allow_manual_reload" def:NO]) {
		[self show_right_button:@selector(fetch_content:)
			item:UIBarButtonSystemItemRefresh];
		if (!self.ignore_updates)
			self.right_button.enabled = YES;
	}
	return YES;
}

- (void)loadView
{
	[super loadView];

	LASSERT(self.cell_data.normal_color, @"Bad initialisation");
	self.view.backgroundColor = self.cell_data.normal_color;
	self.tableView.backgroundColor = self.cell_data.normal_color;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	// If the color is darkish, force white scrollbars.
	UIColor *c = self.view.backgroundColor;
	if (c.redComponent < 0.5f && c.greenComponent < 0.5f &&
			c.blueComponent < 0.5f) {
		self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	}

	LASSERT(self.langcode_url, @"Corrupt object initialisation");
	// Forced url galleries don't have cache attributes.
	if (self.forced_url.length)
		return;
	LASSERT(unique_id_ > 0, @"Didn't register cache");
	LASSERT(ttl_ > 0, @"Bad ttl");
}

- (void)dealloc
{
	[self disconnect_child:nil];
	[gallery_url_ release];
	[more_item_ release];
	[cell_data_ release];
	[super dealloc];
}

/// Clones into the receiver the properties which make sense.
- (void)copy_from:(FLGallery_view_controller*)other
{
	[super copy_from:other];
	self.cell_data = other.cell_data;
	self.row_height = other.row_height;
	self.gallery_url = other.gallery_url;
}

- (void)async_startup:(id)dummy
{
	DONT_BLOCK_UI();
	/* Load from disk related info, only if we don't have a forced URL. */
	if (self.forced_url.length < 1) {
		FLDB *db = [FLDB get_db];
		[self process_items:[db read_meta_items:_PARENT_TABLE owner:unique_id_]
			to_delete:nil has_older:NO];
		if (self.items.count < 1)
			[self show_shield_screen];

		const int id_to_recover = read_and_reset_last_viewed_id();
		if (id_to_recover >= 0) {
			NSIndexPath *path = [self path_for_item:id_to_recover];
			if (path)
				[self performSelectorOnMainThread:
					@selector(simulate_item_selection:)
					withObject:path waitUntilDone:YES];
		}
	}

	[self performSelectorOnMainThread:@selector(start_doing_network_fetches)
		withObject:nil waitUntilDone:NO];
}

/// Worker for async_startup.
- (void)simulate_item_selection:(NSIndexPath*)path
{
	BLOCK_UI();
	[self did_select_item:[self.items objectAtIndex:path.row]
		indexPath:path animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	if (animated) {
		/* See if we want to highlight and scroll a new row. */
		if (animated && self.child_controller && last_item_selected_ >= 0) {
			const int row = last_item_selected_ / self.cell_data->cells_per_row;
			[self.tableView selectRowAtIndexPath:[NSIndexPath
				indexPathForRow:row inSection:0] animated:NO
				scrollPosition:UITableViewScrollPositionMiddle];
		}

		[self disconnect_child:nil];
	}

	// Load from disk only if necessary.
	if (!self.did_startup) {
		self.did_startup = YES;
		[self performSelector:@selector(async_startup:)
			onThread:serial_background_thread withObject:nil waitUntilDone:NO];
	}
}

/** Make sure any eventual forced selection of viewWillAppear deselects.
 */
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.tableView
		deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
		animated:YES];
}

- (int)unique_id
{
	return unique_id_;
}

/** Returns the optional name for the cache registering.
 */
- (NSString*)name_for_cache
{
	LASSERT(self.url, @"Empty url?");
	LASSERT([[FLi18n get] current_langcode], @"Bad initialisation sequence");
	self.langcode_url = [NSString stringWithFormat:@"%@%@",
		self.url, [[FLi18n get] current_langcode]];
	return self.langcode_url;
}

/** Sets up network connection to fetch the content. Called periodically.
 */
- (void)fetch_content:(NSTimer*)theTimer
{
	RASSERT(self.langcode_url.length, @"Uh, incorrect initialisation?", return);

	[connection_ cancel];
	if (!connection_)
		connection_ = (id)[[FLRemote_connection alloc]
			init_with_action:@selector(did_receive_content:error:) target:self];

	[activity_indicator_ startAnimating];
	if (self.forced_url.length) {
		[connection_ request:self.forced_url];
		DLOG(@"Requested forced url %@", self.forced_url);
	} else {
		[connection_ request:[self prettify_request_url:self.langcode_url]];
	}
}

/** Handles reception of gallery items.
 * Goes through the items creating the required model classes, used
 * for each cell.
 */
- (void)did_receive_content:(FLRemote_connection*)response error:(NSError*)error
{
	if (error) {
		[activity_indicator_ stopAnimating];
		DLOG(@"Ignoring net error: %@.", error);
		[self show_error_in_more_cell:error more_item:self.more_item];
		return;
	}

	BLOCK_UI();
	[self performSelector:@selector(process_response:)
		onThread:serial_background_thread withObject:response waitUntilDone:NO];
}

/// Asynchronous method to process the retrieved JSON.
- (void)process_response:(FLRemote_connection*)response
{
	DONT_BLOCK_UI();

	SBJsonParser *parser = [[SBJsonParser new] autorelease];
	NSDictionary *result = [parser objectWithData:[response data]];

	NSArray *to_delete = [result objectForKey:@"to_delete"];
	[self process_items:[result objectForKey:@"thumbs"] to_delete:to_delete
		has_older:[result get_bool:@"has_older" def:NO]];
	[self switch_item:0];

	// Don't continue with disk operation if we are on a forced url.
	if (self.forced_url.length > 0)
		return;

	[self save_items_to_cache:self.items parent_table:_PARENT_TABLE
		data_tables:_DATA_TABLES owner_id:unique_id_ max_elements:cache_size_];
	[[FLDB get_db] purge_meta_items:_PARENT_TABLE data_tables:_DATA_TABLES
		to_delete:to_delete owner:unique_id_];
}

/** Processes gallery items to add to the current list.
 * The items are expected to be a list of dictionaries from which
 * FLGallery_item objects can be created. If they cannot, they will be
 * ignored.
 *
 * Pass in the to_delete array the identifiers of the cells that
 * have to be purged from memory. Disk cache won't be affected, you
 * have to use [FLDB purge_meta_items] for that.
 */
- (void)process_items:(NSArray*)new_items to_delete:(NSArray*)to_delete
	has_older:(BOOL)has_older
{
	DONT_BLOCK_UI();
	NSMutableSet *set = [NSMutableSet setWithCapacity:new_items.count];
	NSMutableArray *data = [NSMutableArray
		arrayWithCapacity:new_items.count + self.items.count];
	/* Add those items that can be converted safely. */
	for (NSDictionary *item in new_items) {
		FLGallery_item *i = [[FLGallery_item alloc] initWithAPIDictionary:item];
		if (i) {
			/* Detect if item's URL is absolute or not, and fix it. */
			if ([i.image isRelativeURL])
				i.image = [NSString stringWithFormat:@"%@/%@",
					self.base_url, i.image];

			if ([i.url isRelativeURL])
				i.url = [NSString stringWithFormat:@"%@/%@",
					self.base_url, i.url];

			[data addObject:i];
			[set addObject:[NSNumber numberWithInt:i.id_]];
			[i release];
		}
	}

	/* Mix in those current items which weren't in the feed. */
	for (FLContent_item *item in self.items) {
		if (![item isKindOfClass:[FLGallery_item class]])
			continue;
		NSNumber *tester = [NSNumber numberWithInt:item.id_];
		if (![set containsObject:tester])
			[data addObject:item];
	}

	[self sort_and_purge_items:data to_delete:to_delete];

	// Should we add an extra cell?
	self.more_item = has_older ? [[FLMore_item new] autorelease] : nil;

	/* Finally assign data, save it and reload table. */
	self.items = [NSArray arrayWithArray:data];
	//DLOG(@"%d items", self.items.count);
	[self hide_shield_screen];

	[self.tableView performSelectorOnMainThread:@selector(reloadData)
		withObject:nil waitUntilDone:YES];
	[self.tableView performSelectorOnMainThread:@selector(flashScrollIndicators)
		withObject:nil waitUntilDone:NO];
}

/// Returns the number of rows for the thumbnail section of the table.
- (int)num_rows
{
	RASSERT(self.cell_data->cells_per_row > 0, @"Bad cells per row", return 0);
	return (self.items.count + (self.cell_data->cells_per_row - 1)) /
		self.cell_data->cells_per_row;
}

/** Updates the accesibility layout for all the visible cells.
 * This method has to be called when there is a scroll on the table, otherwise
 * the frames get unsynched with regards to the current view position. You can
 * only wonder what was going on inside Apple's engineers' heads when they
 * required the frame to be in window coordinates...
 */
- (void)update_cell_accesibility_layout
{
	// This loop has a lot of side effects, see the cell accesor code.
	for (id cell in self.tableView.visibleCells)
		for (int f = 0; [cell accessibilityElementAtIndex:f]; f++);

	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
		nil);
}

/** Spawns a gallery controller for a regex match.
 * This is called globally when the user touches a gallery link in HTML. The
 * gallery will a duplicate and request downloading the forced URL.
 */
- (UIViewController*)spawn_gallery:(FLRegex_match*)match
{
	FLPagination_info *pagination = [[FLPagination_info new] autorelease];
	pagination.next_page = -1;
	pagination.url = self.gallery_url;
	pagination.user_input = match.match;
	NSString *test_url = [pagination replace_params];
	if (test_url.length < 1) {
		DLOG(@"Couldn't spawn gallery for %@ by %@", match, self);
		return nil;
	}

	FLGallery_view_controller *controller = [FLGallery_view_controller new];
	[controller copy_from:self];
	controller.same_window_push = YES;
	controller->unique_id_ = unique_id_;
	controller.forced_url = test_url;
	return [controller autorelease];
}

#pragma mark -
#pragma mark Table view methods

- (CGFloat)tableView:(UITableView *)tableView
	heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.row_height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	if (section)
		return self.more_item ? 1 : 0;
	else
		return [self num_rows];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	LASSERT(self.cell_data->cells_per_row > 0, @"Too few cells per row");
	// Should we deal with the more items cell?
	if (indexPath.section) {
		NSString *identifier = [NSString stringWithFormat:@"More_cell_%d",
			unique_id_];
		FLMore_cell *cell = (id)[tableView
			dequeueReusableCellWithIdentifier:identifier];
		if (!cell)
			cell = [[[FLMore_cell alloc]
				initWithStyle:UITableViewCellStyleDefault
				reuseIdentifier:identifier] autorelease];
		[cell set_background_color:self.cell_data.normal_color
			highlight_color:nil];
		[cell update_state_from:self.more_item];
		return cell;
	}

	// Just a normal section thumbnail row.
	if (!self.cell_identifier) {
		self.cell_identifier = [NSString stringWithFormat:@"Gallery_cell_%d",
			unique_id_];
		LASSERT(self.cell_identifier, @"Couldn't generate cell identifier");
	}

	UITableViewCell *cell = [tableView
		dequeueReusableCellWithIdentifier:self.cell_identifier];

	if (cell == nil)
		cell = [[[FLGallery_cell alloc]
			initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:self.cell_identifier] autorelease];

	FLGallery_cell *gallery_cell = (FLGallery_cell*)cell;
	gallery_cell.data = self.cell_data;
	gallery_cell.cache_owner = unique_id_;

	/* Find out the range of cells that have to be shown. */
	const int num_items = self.items.count;
	NSRange range;
	range.location = indexPath.row * self.cell_data->cells_per_row;
	const int last_item = (MIN(num_items,
		range.location + self.cell_data->cells_per_row)) - 1;
	range.length = 1 + last_item - range.location;
	LASSERT(range.length > 0 && range.length <= self.cell_data->cells_per_row,
		@"Bad range");

	NSArray *stride = [self.items subarrayWithRange:range];
	gallery_cell.items = stride;

	return cell;
}

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BLOCK_UI();
	if (indexPath.section) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		RASSERT(self.more_item, @"No more item but section touched?", return);
		FLMore_cell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
		RASSERT([cell isKindOfClass:[FLMore_cell class]], @"Bad cell type!",
			return);

		// Ignore touches on an already animated cell.
		if (!self.more_item.is_working) {
			self.more_item.title = nil;
			self.more_item.is_working = YES;
			[cell start];
			RASSERT(self.forced_url.length < 1, @"Unexpected forced url",
				return);
			// Nope, just a "get older" items cell.
			self.forced_url = [self prettify_request_url:self.langcode_url
				add_older:YES];
			[self fetch_content:nil];
			// After initiating the request, clean the forced URL.
			self.forced_url = nil;
		}
	} else {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		FLGallery_item *item = ASK_GETTER(cell, selected_item, nil);
		RASSERT(item, @"Invalid cell type or no item?", return);
		[self did_select_item:item indexPath:indexPath animated:YES];
	}
}

- (void)did_select_item:(FLGallery_item*)item
	indexPath:(NSIndexPath*)indexPath animated:(BOOL)animated
{
	BLOCK_UI();
	UIViewController *controller = [item get_controller:self.base_url
		token:unique_id_ group:self.items];

	[self disconnect_child:nil];
	if (controller) {
		if ([controller respondsToSelector:@selector(setItem:)]) {
			self.child_controller = (id)controller;

			NSIndexPath *path = [self path_for_item:item.id_];
			if (path) {
				last_item_selected_ = path.row;
			} else {
				[self disconnect_child:nil];
			}
		}
		controller.title = item.title;

		/* Let the child know that we care about the container protocol. */
		if ([controller respondsToSelector:@selector(setContainer:)])
			[controller performSelector:@selector(setContainer:)
				withObject:self];

		[self push_controller:controller animated:animated];

		if (IS_IPAD)
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	} else {
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
}

#pragma mark FLContainer_protocol

/** You shouldn't be using this. See switch_item for reasons.
 */
- (BOOL)has_previous
{
	return NO;
}

/** You shouldn't be using this. See switch_item for reasons.
 */
- (BOOL)has_next
{
	return NO;
}

/** Get notifications from FLStrip_view_controller about scroll changes.
 *
 * Note that unlike the FLNews_view_controller, the control is
 * inverted in this class! Yes, the switch_item doesn't actually
 * switch the item. It is only used for the child (the strip controller)
 * to tell the parent the item has changed. Otherwise, the strip is
 * in charge of doing everything.
 *
 * So, this method is called when the page changed, but we figure
 * out the index position in the list obtaining the selected item.
 * That's much saner than trying to figure out what cell of the row
 * was pressed.
 */
- (void)switch_item:(int)direction
{
	last_item_selected_ = -1;
	FLGallery_item *item = ASK_GETTER(self.child_controller, item, nil);
	if (item) {
		NSIndexPath *path = [self path_for_item:item.id_];
		if (path)
			last_item_selected_ = path.row;
	}

	DLOG(@"Will show new item %d", last_item_selected_);
}

/** Nils the pointer to the child and resets the last selected path.
 */
- (void)disconnect_child:(id)child
{
	if (!child || self.child_controller == child) {
		self.child_controller = nil;
		last_item_selected_ = -1;
	}
}

#pragma mark -
#pragma mark Scroll methods

/// The table scrolled. Update accessibility layouts.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self update_cell_accesibility_layout];
}

@end
