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
#import "news/FLNews_view_controller.h"

#import "categories/NSDictionary+Floki.h"
#import "categories/NSString+Floki.h"
#import "controllers/FLSection_state.h"
#import "controllers/FLWeb_view_controller.h"
#import "global/FLDB.h"
#import "global/FLMore_cell.h"
#import "global/FLi18n.h"
#import "global/FlokiAppDelegate.h"
#import "global/settings.h"
#import "models/FLMore_item.h"
#import "models/FLNews_item.h"
#import "net/FLRemote_connection.h"
#import "news/FLNews_cell.h"
#import "protocols/FLItem_delegate.h"
#import "structures/FLNews_cell_data.h"
#import "structures/FLPagination_info.h"
#import "structures/FLRegex_match.h"
#import "video/FLMovie_view_controller.h"

#import "ELHASO.h"
#import "NSArray+ELHASO.h"
#import "NSDictionary+ELHASO.h"
#import "SBJson.h"


static NSString *_PARENT_TABLE = @"News_items";
static NSString *_DATA_TABLES[] = { @"News_thumbs", @"Item_contents", nil };


#define _SEARCH_FADE		0.3


@interface FLNews_view_controller ()
- (void)fetch_content:(NSTimer*)theTimer;

- (void)process_new_items:(NSArray*)new_items to_delete:(NSArray*)to_delete
	old_item_id:(int)old_item_id has_older:(BOOL)has_older;

- (void)animate_row_changes:(NSArray*)old_items;
- (void)update_child_controller:(const int)old_id;

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)show_search_shield:(BOOL)show;

@end


@implementation FLNews_view_controller

@synthesize cell_data = cell_data_;
@synthesize last_path_selected = last_path_selected_;
@synthesize pagination = pagination_;
@synthesize search_bar_url = search_bar_url_;
@synthesize tag_url = tag_url_;
@synthesize videos_url = videos_url_;

#pragma mark -
#pragma mark Methods

/** Pseudo constructor, pass JSON dictionary.
 * Stores all the required data for later use. Doesn't actually
 * modify anything else.
 */
- (BOOL)init_with_data:(NSDictionary*)data unique_id:(int)unique_id
{
	LASSERT(!self.cell_data, @"Double initialization");
	LASSERT(!self.search_bar_url, @"Double initialization");
	FLNews_cell_data *cell_data = [FLNews_cell_data new];
	if (!cell_data) {
		LOG(@"Not enough memory to allocate news cell data");
		return NO;
	}

	self.cell_data = cell_data;
	[cell_data release];

	unique_id_ = unique_id;
	self.search_bar_url = [data get_string:@"search_bar" def:nil];
	self.tag_url = [data get_string:@"tags_url" def:nil];
	self.videos_url = [data get_string:@"videos_url" def:nil];
	self.url = [data objectForKey:@"main_url"];
	self.base_url = [self.url stringByRemovingFragment];
	cell_data->padding = [data get_int:@"padding" def:3];
	self.row_height = [data get_int:@"row_height" def:44];
	cell_data->title_lines = MAX(1, [data get_int:@"title_lines" def:1]);
	cell_data->title_size = [data get_int:@"title_size" def:16];
	cell_data->text_size = [data get_int:@"text_size" def:13];
	cell_data->footer_size = [data get_int:@"footer_size" def:11];
	cell_data->footer_alignment = [data get_int:@"footer_alignment" def:0];
	cell_data->image_right = (1 == [data get_int:@"image_alignment" def:0]);
	cell_data->image_size = [data get_size:@"image_size"
		def:CGSizeMake(30, (self.row_height - cell_data->padding * 2))];

	cell_data.title_color = [data get_color:@"title_color"
		def:[UIColor blueColor]];
	cell_data.text_color = [data get_color:@"text_color"
		def:[UIColor blackColor]];
	cell_data.footer_color = [data get_color:@"footer_color"
		def:[UIColor grayColor]];
	cell_data.back_normal_color = [data get_color:@"back_normal_color"
		def:[UIColor whiteColor]];
	cell_data.back_highlight_color = [data get_color:@"back_highlight_color"
		def:[UIColor blueColor]];

	cell_data->navigation_changes_section = [data
		get_bool:@"navigation_changes_section" def:NO];
	cell_data->section_title_padding = [data get_int:@"section_title_padding"
		def:10];

#define _COLOR(R,G,B,NAME) 												\
	[data get_color:NAME def:[UIColor colorWithRed:(R / 255.0f)			\
		green:(G / 255.0f) blue:(B / 255.0f) alpha:1]]

	cell_data.section_expanded_text_color = _COLOR(255, 255, 255,
		@"section_expanded_text_color");
	cell_data.section_expanded_back_color = _COLOR(114, 149, 219,
		@"section_expanded_back_color");
	cell_data.section_collapsed_text_color = _COLOR(0, 0, 0,
		@"section_collapsed_text_color");
	cell_data.section_collapsed_back_color = _COLOR(126, 127, 127,
		@"section_collapsed_back_color");

#undef _COLOR

	/* Make sure the disclosure image is set correctly. Use defaults. */
	cell_data.disclosure_image = [data get_image:@"item_disclosure" def:nil];
	if (!cell_data.disclosure_image) {
		cell_data.disclosure_image =
			[UIImage imageNamed:@"default_disclosure.png"];
		LASSERT(cell_data.disclosure_image, @"Bad disclosure image.");
	}

	cache_size_ = [data get_int:@"cache_size" def:50];
	ttl_ = [data get_int:@"ttl" def:300];
	download_if_virgin_ = [data get_bool:@"download_if_virgin" def:NO];

	if (!self.url || cache_size_ < 1 || ttl_ < 1 ||
			!cell_data.disclosure_image ||
			cell_data->padding < 1 || self.row_height < 1 || unique_id_ < 1 ||
			cell_data->title_size < 1 || cell_data->text_size < 1 ||
			cell_data->footer_size < 1 ||
			cell_data->section_title_padding < 0 ||
			cell_data->section_title_padding >= 320) {
		LOG(@"Failed initialisation of FLNews_view_controller %@", data);
		return NO;
	}

	// Optional protocol parameters.
	if ([data get_bool:@"allow_manual_reload" def:NO]) {
		[self show_right_button:@selector(fetch_content:)
			item:UIBarButtonSystemItemRefresh];
		if (!self.ignore_updates)
			self.right_button.enabled = YES;
	}

	// Register the regular expressions.
	for (NSString *regex in [data get_array:@"tags_regex"
			of:[NSString class] def:nil])
		[FLWeb_view_controller register_tag_regex:regex unique_id:unique_id_];
	for (NSString *regex in [data get_array:@"videos_regex"
			of:[NSString class] def:nil])
		[FLWeb_view_controller register_video_regex:regex unique_id:unique_id_];

	// Try to replace the search bar, if successful, keep it.
	if (self.search_bar_url.length > 0) {
		if (![FLRemote_connection replace_search_params:self.search_bar_url
				words:@"c is for cookie" page:1]) {
			DLOG(@"Ignoring search_bar %@, invalid URL", self.search_bar_url);
			self.search_bar_url = nil;
		}
	}

	// Try to replace the tag url, if successful, keep it.
	if (self.tag_url.length > 0) {
		if (![FLRemote_connection replace_search_params:self.tag_url
				words:@"cry cry" page:1]) {
			DLOG(@"Ignoring tags_url %@, invalid URL", self.tag_url);
			self.tag_url = nil;
		}
	}

	// Try to replace the tag url, if successful, keep it.
	if (self.videos_url.length > 0) {
		if (![FLRemote_connection replace_search_params:self.videos_url
				words:@"roly poly" page:-1]) {
			DLOG(@"Ignoring tags_url %@, invalid URL", self.videos_url);
			self.videos_url = nil;
		}
	}

	return YES;
}

- (void)loadView
{
	[super loadView];

	LASSERT(self.cell_data.back_normal_color, @"Bad initialisation");
	self.view.backgroundColor = self.cell_data.back_normal_color;
	self.tableView.backgroundColor = self.cell_data.back_normal_color;

	LASSERT(self.langcode_url, @"Corrupt object initialisation");
	LASSERT(unique_id_ > 0, @"Didn't register cache");

	if (self.items.count < 1)
		[self show_shield_screen];

	// Create search bar widgets if appropriate.
	if (self.pagination || self.search_bar_url.length < 1)
		return;

	// The search widget itself.
	search_bar_ = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 45)];
	//search_bar_.tintColor = get_app_color();
	search_bar_.delegate = self;
	self.tableView.tableHeaderView = search_bar_;

	CGRect rect = self.tableView.bounds;
	rect.origin.y = search_bar_.bounds.size.height;
	search_shield_ = [[UIView alloc] initWithFrame:rect];
	search_shield_.alpha = 0;
	search_shield_.autoresizingMask = FLEXIBLE_SIZE;
	search_shield_.backgroundColor = [[UIColor blackColor]
		colorWithAlphaComponent:0.8];
	[self.view addSubview:search_shield_];

	[self show_search_shield:NO];
}

- (void)dealloc
{
	[self disconnect_child:nil];
	[tag_url_ release];
	[videos_url_ release];
	[pagination_ release];
	[search_bar_url_ release];
	[search_bar_ release];
	[search_shield_ release];
	[last_path_selected_ release];
	[cell_data_ release];
	[super dealloc];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.last_path_selected = nil;
}

/// Clones into the receiver the properties which make sense.
- (void)copy_from:(FLNews_view_controller*)other
{
	[super copy_from:other];
	self.cell_data = other.cell_data;
	self.row_height = other.row_height;
	self.search_bar_url = other.search_bar_url;
	self.tag_url = other.tag_url;
	self.videos_url = other.videos_url;
}

/** If we come from a child, try to highlight the thing we were reading.
 */
- (void)viewWillAppear:(BOOL)animated
{
	[self.tableView
		deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
		animated:NO];

	[super viewWillAppear:animated];

	if (animated && !IS_IPAD) {
		/* See if we want to highlight and scroll a new
		 * row. Don't perform this code on the iPad since it
		 * will loose the child controller for the navigation.
		 * And the iPad should always allow navigation.
		 */
		if (animated && self.child_controller && self.last_path_selected &&
				self.last_path_selected.row >= 0) {
			[self.tableView selectRowAtIndexPath:self.last_path_selected
				animated:NO scrollPosition:UITableViewScrollPositionMiddle];
		}

		[self set_last_item:nil path:nil];
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

- (void)async_startup:(id)dummy
{
	DONT_BLOCK_UI();
	/* Load from disk related info, only if we don't have a forced URL. */
	if (self.forced_url.length < 1) {
		FLDB *db = [FLDB get_db];
		[self process_new_sections:[db read_sections:unique_id_]];

		[self process_new_items:[db read_meta_items:_PARENT_TABLE
			owner:unique_id_] to_delete:nil old_item_id:-1 has_older:NO];
		if (self.items.count < 1)
			[self show_shield_screen];

		const int id_to_recover = read_and_reset_last_viewed_id();
		if (id_to_recover >= 0) {
			NSIndexPath *path = [self path_for_item:id_to_recover];
			if (path)
				[self performSelectorOnMainThread:
					@selector(simulate_row_selection:)
					withObject:path waitUntilDone:YES];
		}
	}

	[self performSelectorOnMainThread:@selector(start_doing_network_fetches)
		withObject:nil waitUntilDone:NO];
}

/// Worker for async_startup .
- (void)simulate_row_selection:(NSIndexPath*)path
{
	BLOCK_UI();
	[self tableView:self.tableView didSelectRowAtIndexPath:path animated:NO];
}

/** Returns the optional name for the cache registering. */
- (NSString*)name_for_cache
{
	LASSERT(self.url, @"Empty url?");
	LASSERT([[FLi18n get] current_langcode], @"Bad initialisation sequence");
	self.langcode_url = [NSString stringWithFormat:@"%@%@",
		self.url, [[FLi18n get] current_langcode]];
	return self.langcode_url;
}

/** Returns the last item selected or nil if there was none.
 * For this function to work, you need to have called set_last_item
 * before. The function depends on the current state of the self.sections
 * and self.items arrays. If you mangle those, this won't find the
 * item, or will return a bogus one.
 */
- (FLNews_item*)last_item
{
	if (!self.child_controller || !self.last_path_selected)
		return nil;

	NSArray *items = [self items_in_section:self.last_path_selected.section];
	if (items && self.last_path_selected.row >= 0 &&
			self.last_path_selected.row < items.count) {
		return [items objectAtIndex:self.last_path_selected.row];
	} else {
		return nil;
	}
}

/** Sets the controller and path for the last selected item.
 * This doesn't store the item itself, only the position and such.
 * You can use the last_item method to retrieve the true element.
 *
 * The controller has to respond to the selector setItem:. If that's
 * not true, or one of the parameters is nil, the function will clean
 * up the indices pointing to the object.
 */
- (void)set_last_item:(id)controller path:(NSIndexPath*)path
{
	if ([controller respondsToSelector:@selector(setItem:)] && path) {
		self.child_controller = controller;
		self.last_path_selected = path;
	} else {
		[self disconnect_child:nil];
	}
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

/** Handles reception of news items.
 * Goes through the items creating the required model classes, used
 for each cell.
 */
- (void)did_receive_content:(FLRemote_connection*)response error:(NSError*)error
{
	if (error) {
		[activity_indicator_ stopAnimating];
		DLOG(@"Ignoring net error: %@.", error);
		[self show_error_in_more_cell:error more_item:[self.items lastObject]];
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

	/* Save now the last item identifier if there was any. */
	FLNews_item *last_item = self.last_item;
	const int old_id = last_item ? last_item.id_ : -1;

	NSArray *sections = [result objectForKey:@"sections"];
	[self process_new_sections:sections];

	NSArray *to_delete = [result get_array:@"to_delete"
		of:[NSNumber class] def:nil];
	[self process_new_items:[result get_array:@"items"
		of:[NSDictionary class] def:nil]
 		to_delete:to_delete old_item_id:old_id
		has_older:[result get_bool:@"has_older" def:NO]];

	// Increase the search page count if we were doing a search.
	if (self.pagination)
		self.pagination.next_page++;

	// Don't continue with disk operation if we are on a forced url.
	if (self.forced_url.length)
		return;

	[self save_items_to_cache:self.items parent_table:_PARENT_TABLE
		data_tables:_DATA_TABLES owner_id:unique_id_ max_elements:cache_size_];
	[self save_sections_to_cache:self.sections owner_id:unique_id_];
	[[FLDB get_db] purge_meta_items:_PARENT_TABLE
		data_tables:_DATA_TABLES to_delete:to_delete owner:unique_id_];
}

/** Processes new items to add to the current list.
 * The items are expected to be a list of dictionaries from which
 * FLNews_item objects can be created. If they cannot, they will be
 * ignored.
 *
 * Pass in the to_delete array the identifiers of the cells that
 * have to be purged from memory. Disk cache won't be affected, you
 * have to use [FLDB purge_meta_items] for that.
 *
 * This function is executed in the context of already new sections,
 * so you need to pass the previously selected last item id, since trying
 * to get it at this point will look for an element in empty sections.
 * Pass negative if there wasn't any previous item identifier.
 */
- (void)process_new_items:(NSArray*)new_items to_delete:(NSArray*)to_delete
	old_item_id:(int)old_item_id has_older:(BOOL)has_older
{
	DONT_BLOCK_UI();

	NSMutableSet *set = [NSMutableSet setWithCapacity:new_items.count];
	NSMutableArray *data = [NSMutableArray
		arrayWithCapacity:new_items.count + self.items.count];
	/* Add those items that can be converted safely. */
	for (NSDictionary *item in new_items) {
		FLNews_item *i = [[FLNews_item alloc] initWithAPIDictionary:item];
		if (i) {
			/* Detect if item's URL is absolute or not, and fix it. */
			if ([i.image isRelativeURL])
				i.image = [NSString stringWithFormat:@"%@/%@",
					self.base_url, i.image];

			[data addObject:i];
			[set addObject:[NSNumber numberWithInt:i.id_]];
			[i release];
		}
	}
	const int new_valid_items = data.count;

	/* Mix in those current items which weren't in the feed. */
	for (FLContent_item *item in self.items) {
		if (![item isKindOfClass:[FLNews_item class]])
			continue;
		NSNumber *tester = [NSNumber numberWithInt:item.id_];
		if (![set containsObject:tester])
			[data addObject:item];
	}

	[self sort_and_purge_items:data to_delete:to_delete];

	// For the special case of search results, add a more cell if appropriate.
	if (self.forced_url.length && new_valid_items)
		[data addObject:[[FLMore_item new] autorelease]];
	else if (has_older)
		[data addObject:[[FLMore_item new] autorelease]];

	/* Now perform animated deletions/insertions. */
	NSArray *old_items = [self.items retain];
	self.items = [NSArray arrayWithArray:data];

	if (self.sections.count > 0) {
		DLOG(@"Row animations not yet implemented for section tables!");
		[self.tableView performSelectorOnMainThread:@selector(reloadData)
			withObject:nil waitUntilDone:YES];
	} else {
		[self performSelectorOnMainThread:@selector(animate_row_changes:)
			withObject:old_items waitUntilDone:YES];
	}

	[self update_child_controller:old_item_id];
	[self hide_shield_screen];
	[old_items release];
	[self.tableView performSelectorOnMainThread:@selector(flashScrollIndicators)
		withObject:nil waitUntilDone:NO];
}

/** Generates core animation calls for the recently changed self.items.
 * Pass the old array of items. The function will compare it to the
 * current one and generate the animation calls. It will also update
 * the reading position of the article if the user is viewing one.
 */
- (void)animate_row_changes:(NSArray*)old_items
{
	BLOCK_UI();
	[self.tableView beginUpdates];

	NSMutableArray *paths_to_delete = [NSMutableArray
		arrayWithCapacity:old_items.count];

	for (int f = 0; f < old_items.count; f++) {
		FLNews_item *old_item = [old_items objectAtIndex:f];
		bool remove = YES;
		if ([old_item isKindOfClass:[FLNews_item class]]) {
			const int old_id = old_item.id_;
			// Search for old item in the new list, if it doesn't exist, remove.
			for (FLNews_item *item in self.items) {
				if (old_id == item.id_) {
					remove = NO;
					break;
				}
			}
		}
		if (remove)
			[paths_to_delete addObject:[NSIndexPath indexPathForRow:f
				inSection:0]];
	}

	NSMutableArray *paths_to_insert = [NSMutableArray
		arrayWithCapacity:self.items.count];
	NSMutableArray *paths_to_reload = [NSMutableArray
		arrayWithCapacity:self.items.count];

	for (int f = 0; f < self.items.count; f++) {
		FLNews_item *new_item = [self.items objectAtIndex:f];
		bool insert = YES;
		if ([new_item isKindOfClass:[FLNews_item class]]) {
			const int new_id = new_item.id_;
			// Search in the old list if the id didn't exist. If so, insert it.
			for (FLNews_item *item in old_items) {
				if (new_id == item.id_) {
					insert = NO;
					break;
				}
			}
		}
		/* Insert the path, or reload it. What do you prefer? */
		[(insert ? paths_to_insert : paths_to_reload)
			addObject:[NSIndexPath indexPathForRow:f inSection:0]];
	}

	if (paths_to_delete.count > 0)
		[self.tableView deleteRowsAtIndexPaths:paths_to_delete
			withRowAnimation:UITableViewRowAnimationFade];

	if (paths_to_insert.count > 0)
		[self.tableView insertRowsAtIndexPaths:paths_to_insert
			withRowAnimation:UITableViewRowAnimationRight];

	[self.tableView endUpdates];

	/* Reloads have to be performed out of insertion/deletions block. */
	if (paths_to_reload.count > 0)
		[self.tableView reloadRowsAtIndexPaths:paths_to_reload
			withRowAnimation:UITableViewRowAnimationNone];
}

/** If the user is viewing a child item, updates that view.
 * If the news changed in the parent, it may be necessary to update
 * the child to reflect new changes in the sorting order, or yank him
 * from a view that just dissappeared.
 *
 * Call this from process_new_items passing the old identifier. The
 * function will scan the current identifiers and select the correct
 * one if it still exists. Otherwise, navigation will be disabled.
 */
- (void)update_child_controller:(const int)old_id
{
	if (!self.child_controller)
		return;

	const int section = self.last_path_selected.section;
	NSArray *items = [self items_in_section:section];
	int new_position = 0;
	for (FLNews_item *item in items) {
		if (old_id == item.id_)
			break;
		new_position++;
	}

	if (new_position >= items.count) {
		DLOG(@"News item not available any more, resetting.");
		[self set_last_item:nil path:nil];
	} else {
		DLOG(@"News item position changed, triggering child refresh.");
		[self set_last_item:self.child_controller path:[NSIndexPath
			indexPathForRow:new_position inSection:section]];
	}

	/* Force refresh of navigation. */
	[self.child_controller setItem:[self.child_controller item]];
}

#pragma mark -
#pragma mark Inheritable section customization

- (UIColor*)get_section_collapsed_text_color
{
	return self.cell_data.section_collapsed_text_color;
}

- (UIColor*)get_section_collapsed_back_color
{
	return self.cell_data.section_collapsed_back_color;
}

- (UIColor*)get_section_expanded_text_color
{
	return self.cell_data.section_expanded_text_color;
}

- (UIColor*)get_section_expanded_back_color
{
	return self.cell_data.section_expanded_back_color;
}

- (int)get_section_title_padding
{
	return self.cell_data->section_title_padding;
}

#pragma mark -
#pragma mark UISearchBar delegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	DLOG(@"searchBarShouldBeginEditing");
	[self show_search_shield:YES];
	return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
	DLOG(@"searchBarShouldEndEditing");
	[self show_search_shield:NO];
	return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	DLOG(@"searchBarCancelButtonClicked");
	[self show_search_shield:NO];
	[searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	NSString *user_input = [searchBar.text
		stringByTrimmingCharactersInSet:[NSCharacterSet
			whitespaceAndNewlineCharacterSet]];

	// Dismiss the current search shield, as if the user had pressed cancel.
	[self searchBarCancelButtonClicked:searchBar];

	if (user_input.length) {
		DLOG(@"Searching for %@", user_input);
		FLNews_view_controller *c = [self spawn_search:user_input];
		c.hidesBottomBarWhenPushed = YES;
		c.title = user_input;
		// Avoid ipad push, always push inside this view controller.
		[self.navigationController pushViewController:c animated:YES];
	}
}

#pragma mark -
#pragma mark Search methods

/** Modifies the visibility of the search options panel.
 * The visibility is done with a fade. This method also disables or enables the
 * scrolling of the table.
 */
- (void)show_search_shield:(BOOL)show
{
	self.tableView.scrollEnabled = !show;

	[search_bar_ setShowsCancelButton:show animated:YES];

	// Ugly hack to change language of cancel button.
	for (UIView *view in search_bar_.subviews) {
		if ([view respondsToSelector:@selector(setTitle:forState:)]) {
			UIButton *b = (UIButton*)view;
			[b setTitle:_e(34) forState:UIControlStateNormal];
			// _34: Cancel
			break;
		}
	}

	search_bar_.placeholder = show ? @"" : _e(33);
	// _33: Search

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:_SEARCH_FADE];
	[UIView setAnimationBeginsFromCurrentState:YES];
	search_shield_.alpha = show ? 1 : 0;
	[UIView commitAnimations];
}

/** Spawns the view with a special search URL.
 * The view will act like the current news view controller, but it will be
 * modified especially to not use cache and force a specific URL for a search
 * query.
 *
 * \return Returns nil if there was any problem.
 */
- (FLNews_view_controller*)spawn_search:(NSString*)words
{
	FLPagination_info *pagination = [[FLPagination_info new] autorelease];
	pagination.next_page = 1;
	pagination.url = self.search_bar_url;
	pagination.user_input = words;
	NSString *search_url = [pagination replace_params];
	if (search_url.length < 1) {
		DLOG(@"Couldn't spawn search for %@ by %@", words, self);
		return nil;
	}

	FLNews_view_controller *search_controller = [FLNews_view_controller new];
	[search_controller copy_from:self];
	search_controller.pagination = pagination;
	search_controller->unique_id_ = unique_id_;
	search_controller.forced_url = search_url;
	return [search_controller autorelease];
}

#pragma mark -
#pragma mark URL capture methods

/** Similar to spawn_search, creates a duplicate for tag viewing.
 * Tag viewing is really similar to search viewing, with the difference of
 * using other URL substitution and a complex input structure.
 */
- (UIViewController*)spawn_tag:(FLRegex_match*)match
{
	FLPagination_info *pagination = [[FLPagination_info new] autorelease];
	pagination.next_page = 1;
	pagination.url = self.tag_url;
	pagination.user_input = match.match;
	NSString *tag_url = [pagination replace_params];
	if (tag_url.length < 1) {
		DLOG(@"Couldn't spawn tags for %@ by %@", match, self);
		return nil;
	}

	FLNews_view_controller *tag_controller = [FLNews_view_controller new];
	[tag_controller copy_from:self];
	tag_controller.same_window_push = YES;
	tag_controller.title = match.match;
	tag_controller.pagination = pagination;
	tag_controller->unique_id_ = unique_id_;
	tag_controller.forced_url = tag_url;
	return [tag_controller autorelease];
}

/// Just like spawn_tag: but for video controllers.
- (UIViewController*)spawn_video:(FLRegex_match*)match
{
	FLPagination_info *pagination = [[FLPagination_info new] autorelease];
	pagination.next_page = -1;
	pagination.url = self.videos_url;
	pagination.user_input = match.match;
	NSString *test_url = [pagination replace_params];
	if (test_url.length < 1) {
		DLOG(@"Couldn't spawn video for %@ by %@", match, self);
		return nil;
	}

	FLMovie_view_controller *controller = [FLMovie_view_controller new];
	controller.same_window_push = YES;
	[controller download_json:test_url];
	return [controller autorelease];
}

#pragma mark -
#pragma mark Table view methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.row_height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id cell_item = [self item_at_index_path:indexPath];
	NSString *identifier = nil;
	Class cell_class = [FLNews_cell class];
	if ([cell_item isKindOfClass:[FLNews_item class]]) {
		if (!self.cell_identifier.length) {
			self.cell_identifier = [NSString stringWithFormat:@"News_cell_%d",
				unique_id_];
			LASSERT(self.cell_identifier.length, @"Couldn't build identifier");
		}
		identifier = self.cell_identifier;
	} else if ([cell_item isKindOfClass:[FLMore_item class]]) {
		identifier = [NSString stringWithFormat:@"More_cell_%d", unique_id_];
		cell_class = [FLMore_cell class];
	} else {
		RASSERT(NO, @"Shouldn't reach here", return nil);
	}

	UITableViewCell *cell = [tableView
		dequeueReusableCellWithIdentifier:identifier];

	if (cell == nil)
		cell = [[[cell_class alloc] initWithStyle:UITableViewCellStyleDefault
			reuseIdentifier:identifier] autorelease];

	FLMore_cell *more_cell = CAST(cell, FLMore_cell);
	if (more_cell) {
		[more_cell set_background_color:self.cell_data.back_normal_color
			highlight_color:self.cell_data.back_highlight_color];
		[more_cell update_state_from:cell_item];
	} else {
		FLNews_cell *news_cell = CAST(cell, FLNews_cell);
		news_cell.data = self.cell_data;
		news_cell.cache_owner = unique_id_;
		news_cell.item = cell_item;
	}

	LASSERT(cell, @"Can't return nil");
	return cell;
}

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BLOCK_UI();
	[self tableView:tableView didSelectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
	BLOCK_UI();
	FLContent_item *cell_item = [self item_at_index_path:indexPath];
	UIViewController *controller = nil;
	if ([cell_item isKindOfClass:[FLNews_item class]])
		controller = [(FLNews_item*)cell_item get_controller:self.base_url
			token:unique_id_];
	else if ([cell_item isKindOfClass:[FLMore_item class]]) {
		FLMore_item *more_item = (id)cell_item;
		FLMore_cell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
		RASSERT([cell isKindOfClass:[FLMore_cell class]], @"Bad cell type!",
			return);

		// Ignore touches on an already animated cell.
		if (!more_item.is_working) {
			more_item.title = nil;
			more_item.is_working = YES;
			[cell start];
			// What kind of "more" cell we have? A paginated search?
			if (self.pagination) {
				self.forced_url = [self.pagination replace_params];
				[self fetch_content:nil];
			} else {
				RASSERT(self.forced_url.length < 1, @"Unexpected forced url",
					return);
				// Nope, just a "get older" items cell.
				self.forced_url = [self prettify_request_url:self.langcode_url
					add_older:YES];
				[self fetch_content:nil];
				// After initiating the request, clean the forced URL.
				self.forced_url = nil;
			}
		}
	}

	[self set_last_item:controller path:indexPath];
	if (controller) {
		controller.title = cell_item.title;

		/* Let the child know that we care about the container protocol. */
		if ([controller respondsToSelector:@selector(setContainer:)])
			[controller performSelector:@selector(setContainer:)
				withObject:self];

		[self push_controller:controller animated:animated];

		if (IS_IPAD)
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
	} else {
		DLOG(@"Ugh, couldn't get controller for %@: id (%d) %@",
			cell_item, cell_item.id_, cell_item);
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (int)unique_id
{
	return unique_id_;
}

#pragma mark -
#pragma mark FLContainer_protocol

- (BOOL)has_previous
{
	if (!self.child_controller)
		return NO;

	if (self.cell_data->navigation_changes_section &&
		self.last_path_selected.section > 0)
			return YES;
	else
		return (self.last_path_selected.row > 0);
}

- (BOOL)has_next
{
	if (!self.child_controller)
		return NO;

	if (self.cell_data->navigation_changes_section && self.sections.count > 1 &&
			self.last_path_selected && self.last_path_selected.section <
			self.sections.count - 1) {
		return YES;
	} else if (self.last_path_selected && self.last_path_selected.row <
			[self items_in_section:self.last_path_selected.section].count - 1) {
		// Ok, there is a next cell, but is it a valid content cell?
		NSArray *section_items = [self
			items_in_section:self.last_path_selected.section];
		id item = [section_items get:self.last_path_selected.row + 1];
		if ([item isKindOfClass:[FLNews_item class]])
			return YES;
		else
			return NO;
	} else {
		return NO;
	}
}

/** Switches the item of the child controller.
 * If the direction is positive, the next element will be selected,
 * otherwise the previous will.
 */
- (void)switch_item:(int)direction
{
	RASSERT(self.child_controller, @"Bad internal pointer", return);
	LASSERT(self.last_path_selected, @"Doesn't remember item selection...");
	LASSERT(self.items.count > 0, @"Cant switch without items!");
	LASSERT(direction, @"Zero invalid direction");

	/* Since the user touched the navigation bar, dismiss the pop overs. */
	if (IS_IPAD) {
		ASK_GETTER(self.child_controller, cancel_previous_action_sheet, nil);
		id split_view = ASK_GETTER(self, splitViewController, nil);
		ASK_GETTER(split_view, dismiss_pop_over, nil);
	}

	NSArray *items = [self items_in_section:self.last_path_selected.section];
	int new_sec = self.last_path_selected.section;
	int new_row = self.last_path_selected.row;

	/* First try to detect if we are switching section. */
	if (self.cell_data->navigation_changes_section && self.sections.count > 1) {
		if (direction > 0 && items.count - 1 == new_row &&
				new_sec < self.sections.count - 1) {
			new_sec++;
			items = [self items_in_section:new_sec];
			new_row = 0;
			direction = 0;
		} else if (direction < 0 && 0 == new_row && new_sec > 0) {
			new_sec--;
			items = [self items_in_section:new_sec];
			direction = 0;
			new_row = items.count - 1;
		}
	}
	LASSERT(items.count > 0, @"Weird empty section?");

	if (direction > 0)
		new_row++;
	else if (direction < 0)
		new_row--;

	new_row = MIN(items.count - 1, new_row);
	new_row = MAX(0, new_row);
	DLOG(@"Will show new item %d.%d", new_sec, new_row);

	self.last_path_selected = [NSIndexPath
		indexPathForRow:new_row inSection:new_sec];

	FLNews_item *item = (id)[self item_at_index_path:self.last_path_selected];
	if ([item isKindOfClass:[FLNews_item class]])
		[self.child_controller setItem:item];
}

/** Nils the pointer to the child and resets the last selected path.
 * Also attempts to notify the children object through an informal protocol to
 * update the navigation arrows.
 */
- (void)disconnect_child:(id)child
{
	if (!child || self.child_controller == child) {
		id valid_child = child ? child : self.child_controller;
		self.child_controller = nil;
		self.last_path_selected = nil;
		ASK_GETTER(valid_child, update_navigation_arrows, nil);
		ASK_GETTER(valid_child, updat_hud, nil);
	}
}

@end
