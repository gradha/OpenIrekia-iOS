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
#import "controllers/FLContent_table_view_controller.h"

#import "FLi18n.h"
#import "controllers/FLSection_state.h"
#import "global/FLDB.h"
#import "global/FLGloss_rectangle.h"
#import "models/FLContent_item.h"

#import "ELHASO.h"


#define _DEFAULT_HEIGHT		30.0


@interface FLContent_table_view_controller ()
- (FLSection_state*)section_by_id:(int)section_id;
- (void)animate_section_collapsing:(FLSection_state*)section;
- (void)update_button_state:(UIButton*)button section:(FLSection_state*)section;
@end

@implementation FLContent_table_view_controller

@synthesize tableView = table_view__;
@synthesize sections = sections_;

/** Handles creation of the view, pseudo constructor.
 * We let the FLContent_view_controller create the views, and then
 * we sneakily replace the view with our table view, carefully
 * reattaching the original subviews.
 */
- (void)loadView
{
	LASSERT(self.nibName.length < 1, @"We dislike nibs");
	[super loadView];

	UITableView *table = [[UITableView alloc] initWithFrame:self.view.bounds
		style:UITableViewStylePlain];
	table.autoresizingMask = FLEXIBLE_SIZE;
	table.contentMode = UIViewContentModeScaleAspectFit;

	[self.view addSubview:table];
	[self.view sendSubviewToBack:table];
	self.tableView = table;
	[table release];
}

/** Frees up all resources.
 */
- (void)dealloc
{
	[sections_ release];
	[table_view__ release];
	[super dealloc];
}

/** Hooks the message to enable/disable the reload button.
 */
- (void)viewWillAppear:(BOOL)animated
{
	if (self.ignore_updates)
		self.right_button.enabled = NO;

	[super viewWillAppear:animated];
}

/** Property accesors.
 */
- (UITableView*)tableView
{
	return table_view__;
}

- (void)setTableView:(UITableView*)table_view
{
	if (table_view__ == table_view)
		return;

	[table_view__ release];
	table_view__ = [table_view retain];
	[table_view__ setDelegate:self];
	[table_view__ setDataSource:self];
}

/** Sets the list of items.
 * If there are sections, the items will also be replicated inside
 * the sections. Previous items from the sections are not purged.
 */
- (void)setItems:(NSArray*)new_items
{
	if (self.items == new_items)
		return;

	[super setItems:new_items];

	/* Here we add the items to the sections if there are any. */
	if (self.sections.count < 1)
		return;

	/* Clean the current arrays for the sections. */
	for (FLSection_state *section in self.sections)
		[section.items removeAllObjects];

	for (FLContent_item *item in new_items) {
		for (NSNumber *int_object in item.section_ids) {
			const int section_id = [int_object intValue];
			FLSection_state *section = [self section_by_id:section_id];
			if (!section) {
				DLOG(@"Didn't find section %d for item %@", section_id, item);
				continue;
			}

			[section.items addObject:item];
		}
	}

	/* Purge empty sections. */
	NSMutableArray *purged_sections = [NSMutableArray
		arrayWithCapacity:self.sections.count];
	for (FLSection_state *section in self.sections)
		if (section.items.count > 0)
			[purged_sections addObject:section];

	if (purged_sections.count != self.sections.count) {
		DLOG(@"There are empty sections, purging them!");
		self.sections = purged_sections;
	}
}

#pragma mark -
#pragma mark Section functions

/** Returns the section with the specified identifier.
 * Returns nil if the section was not found in the current array.
 */
- (FLSection_state*)section_by_id:(int)section_id
{
	for (FLSection_state *section in self.sections)
		if (section_id == section.id_)
			return section;
	return nil;
}

/** Returns the section with the specified index.
 * Returns nil if the index was out of range.
 */
- (FLSection_state*)section_by_index:(int)section_index
{
	if (section_index < 0 || section_index >= self.sections.count)
		return nil;

	return [self.sections objectAtIndex:section_index];
}

/** Returns the array of items stored in the specified section.
 * This works both for views with sections and without them, so it
 * is a safe replacement for those if checks to access one or the
 * other.
 *
 * If the requested section doesn't exist, the full list of items
 * will be returned instead, failing in debug builds, but not release
 * ones.
 */
- (NSArray*)items_in_section:(int)section_index
{
	if (self.sections.count > 0) {
		FLSection_state *section = [self section_by_index:section_index];
		RASSERT(section, @"Didn't find specified section", return self.items);
		return section.items;
	} else {
		LASSERT(0 == section_index, @"Bogus section index without sections!");
		return self.items;
	}
}

/** Returns the index of the section in the table.
 * Returns a negative value if the section wasn't found or there
 * was other problem.
 */
- (int)section_index:(FLSection_state*)section
{
	int f = 0;
	for (FLSection_state *item in self.sections) {
		if (item.id_ == section.id_)
			return f;
		else
			f++;
	}
	DLOG(@"Didn't find section index for %d (%@)", section.id_, section.name);
	return -1;
}

/** Returns the indexpath for the specified item identifier.
 * Returns nil if the identifier wasn't found. Note that since items
 * can be in multiple sections, this will return the instance in the
 * first section.
 *
 * If the table doesn't have sections, the indexpath will point to
 * the index of the item in self.items with the section set to zero.
 */
- (NSIndexPath*)path_for_item:(int)id_
{
	if (self.sections.count > 0) {
		for (int g = 0; g < self.sections.count; g++) {
			FLSection_state *section = [self.sections objectAtIndex:g];
			for (int f = 0; f < section.items.count; f++) {
				FLContent_item *item = [section.items objectAtIndex:f];
				if (id_ == item.id_)
					return [NSIndexPath indexPathForRow:f inSection:g];
			}
		}
	} else {
		for (int f = 0; f < self.items.count; f++) {
			FLContent_item *item = [self.items objectAtIndex:f];
			if (id_ == item.id_)
				return [NSIndexPath indexPathForRow:f inSection:0];
		}
	}
	return nil;
}

/** Returns the correct content item at the specified index path.
 * This function is expected to always work. Assertions are in place.
 */
- (FLContent_item*)item_at_index_path:(NSIndexPath*)indexPath
{
	FLContent_item *ret = nil;
	if (self.sections.count > 0) {
		LASSERT(indexPath.section >= 0 &&
			indexPath.section < self.sections.count,
			@"Incorrect item_at_index_path request 1");

		FLSection_state *s = [self.sections objectAtIndex:indexPath.section];
		ret = [s.items objectAtIndex:indexPath.row];
	} else {
		LASSERT(indexPath.row >= 0 && indexPath.row < self.items.count,
			@"Incorrect item_at_index_path request 2");
		ret = [self.items objectAtIndex:indexPath.row];
	}
	LASSERT(!ret || ret && [ret isKindOfClass:[FLContent_item class]],
		@"Returning an unexpected cell type is not good");
	return ret;
}

/** Transforms section specifications into objects.
 * Pass a list of dictionaries from which FLSection_state objects can be
 * created. Invalid or repeated sections will be ignored.
 *
 * The current sections will be replaced, freeing any previously
 * associated items, so you better call process_new_items after this
 * call.
 */
- (void)process_new_sections:(NSArray*)new_sections
{
	DONT_BLOCK_UI();
	NSMutableSet *set = [NSMutableSet setWithCapacity:new_sections.count];
	NSMutableArray *valid_sections = [NSMutableArray
		arrayWithCapacity:new_sections.count];

	for (NSDictionary *section in new_sections) {
		FLSection_state *s = [[FLSection_state alloc]
			initWithAPIDictionary:section];

		if (s) {
			/* See if the section is not a duplicate. */
			NSNumber *tester = [NSNumber numberWithInt:s.id_];
			if (![set containsObject:tester]) {
				[valid_sections addObject:s];
				[set addObject:[NSNumber numberWithInt:s.id_]];
			} else {
				DLOG(@"Ignoring duplicate section id %d", s.id_);
			}
		}
		[s release];
	}

	/* Check if the validated sections are already on the client. Also, try
	 * to copy the previous collapsed state in case something changes.
	 */
	BOOL changes = !self.sections;
	if (0 == valid_sections.count && self.sections.count > 0) {
		changes = YES;
	} else {
		for (FLSection_state *valid_section in valid_sections) {
			FLSection_state *previous = [self section_by_id:valid_section.id_];
			if (![previous is_equal_to:valid_section])
				changes = YES;

			if (previous)
				valid_section.collapsed = previous.collapsed;
		}
	}
	if (!changes) {
		DLOG(@"Didn't get new section changes, not refreshing.");
		return;
	}

	if (valid_sections.count > 0) {
		/* Preserve old sections by copying them to the new ones. */
		for (FLSection_state *old_section in self.sections) {
			NSNumber *tester = [NSNumber numberWithInt:old_section.id_];
			if (![set containsObject:tester])
				[valid_sections addObject:old_section];
		}
	}

	/* Sort sections by identifier. */
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc]
		initWithKey:@"sort_id_" ascending:NO];
	[valid_sections sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];

	self.sections = valid_sections;
	/* Force freeing items if the sections were disabled, or we will crash. */
	if (self.sections.count < 1) {
		self.items = nil;
		[self.tableView performSelectorOnMainThread:@selector(reloadData)
			withObject:nil waitUntilDone:YES];
	}

	DLOG(@"Created %d sections", self.sections.count);
}

/** Handles the touches on the interactive section headers.
 * The button is the sender, and it has a tag to find the section.
 */
- (void)section_touched:(id)sender
{
	UIButton *button = sender;
	FLSection_state *section = [self section_by_id:button.tag];
	if (!section) {
		DLOG(@"Unknown section touched!?");
		return;
	}
	DLOG(@"Interacting with section %@", section.name);

	/* First collapse other sections so the scroll position is changed. */
	if (section.autocollapse_others) {
		for (FLSection_state *s in self.sections) {
			if (s == section || s.collapsed || !s.interactive)
				continue;

			s.collapsed = !s.collapsed;
			[self animate_section_collapsing:s];
		}
	}

	/* Now collapse/expand the touched section. */
	section.collapsed = !section.collapsed;
	[self update_button_state:button section:section];
	[self animate_section_collapsing:section];
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
		nil);
}

/** Performs collapsation/expansion animation for a specific section.
 * The function will animate the section, but note that the state
 * of the section has to have been actually changed before calling
 * this function. So you change the collapsed attribute, then call
 * this method with the specified section.
 */
- (void)animate_section_collapsing:(FLSection_state*)section
{
	const int section_index = [self section_index:section];
	if (section_index < 0)
		return;

	/* Prepare expansion or collapsation of section content. */
	NSMutableArray *paths = [NSMutableArray
		arrayWithCapacity:section.items.count];
	for (int f = 0; f < section.items.count; f++)
		[paths addObject:[NSIndexPath indexPathForRow:f
			inSection:section_index]];

	[self.tableView beginUpdates];
	if (section.collapsed)
		[self.tableView deleteRowsAtIndexPaths:paths
			withRowAnimation:UITableViewRowAnimationTop];
	else
		[self.tableView insertRowsAtIndexPaths:paths
			withRowAnimation:UITableViewRowAnimationTop];
	[self.tableView endUpdates];

	/* If the section was expanded, scroll the contents to the top. */
	if (!section.collapsed && paths.count > 0)
		[self.tableView scrollToRowAtIndexPath:[paths objectAtIndex:0]
			atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

/** Similar to save_items_to_cache but used only to save sections.
 * The function will purge the unused sections from the database.
 * Note that only sections with items in them will be saved.
 */
- (void)save_sections_to_cache:(NSArray*)sections owner_id:(int)owner_id
{
	RASSERT(self.forced_url.length < 1, @"No cache with forced urls!", return);
	DONT_BLOCK_UI();
	FLDB *db = [FLDB get_db];
	NSMutableArray *used = [NSMutableArray arrayWithCapacity:sections.count];

	[db beginTransaction];
	for (FLSection_state *section in sections) {
		if (section.items.count < 1)
			continue;

		[db save_meta_item:@"Sections" data:[section create_json]
			the_id:section.id_ owner:owner_id];

		[used addObject:[NSString stringWithFormat:@"%d", section.id_]];
	}
	[db commitTransaction];

	[db purge_unused_sections:owner_id to_preserve:used];
}

#pragma mark Inheritable section customization by classes

- (UIColor*)get_section_collapsed_text_color { return nil; }
- (UIColor*)get_section_collapsed_back_color { return nil; }
- (UIColor*)get_section_expanded_text_color { return nil; }
- (UIColor*)get_section_expanded_back_color { return nil; }
- (int)get_section_title_padding { return 10; }

#pragma mark -
#pragma mark UITableViewDelegate

/** Comply with the prococol. This needs subclassing anyway...
 */
- (UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

/** Returns the number of sections, or 1 if there are no sections.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return (self.sections.count > 0) ? self.sections.count : 1;
}

/** Returns the total number of items or the number of rows in a section.
 */
- (NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	if (self.sections.count > 0) {
		if (section < 0 || section >= self.sections.count) {
			DLOG(@"Warning, was requesting section %d out of %d", section,
				self.sections.count);
			return 0;
		}

		FLSection_state *s = [self.sections objectAtIndex:section];
		DLOG(@"%d rows for section %d '%@'", s.items.count, s.id_, s.name);
		return (s.collapsed) ? 0 : s.items.count;
	} else {
		DLOG(@"table with %d items", self.items.count);
		return self.items.count;
	}
}

/** Returns the view for the section header.
 * Returns an active button which triggers expansion/collapse of a section.
 */
- (UIView *)tableView:(UITableView *)tableView
	viewForHeaderInSection:(NSInteger)section_index
{
	BLOCK_UI();
	FLSection_state *section = [self section_by_index:section_index];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.opaque = YES;
	button.tag = section.id_;
	button.frame = CGRectMake(0, 0, 320, _DEFAULT_HEIGHT);

	if (!section || !section.visible)
		return button;

	/* Set the text of the section header. */
	NSString *text = @"";
	if (section.name.length > 0) {
		if (section.show_count)
			text = [NSString stringWithFormat:@"%@ (%d)", section.name,
				section.items.count];
		else
			text = section.name;
	}
	[button setTitle:text forState:UIControlStateNormal];
	SET_ACCESSIBILITY_LANGUAGE(button);
	[button
		setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
	const int padding = [self get_section_title_padding];
	button.titleEdgeInsets = UIEdgeInsetsMake(0, padding, 0, padding);

	[self update_button_state:button section:section];

	/* Associate a method with the button. */
	if (section.interactive) {
		[button addTarget:self action:@selector(section_touched:)
			forControlEvents:UIControlEventTouchUpInside];
		button.showsTouchWhenHighlighted = YES;
	}

	return button;
}

/** Updates the state of the section colors and collapse state.
 */
- (void)update_button_state:(UIButton*)button section:(FLSection_state*)section
{
	UIColor *text = nil;
	UIColor *back = nil;

	if (section.collapsed) {
		text = section.collapsed_text_color;
		if (!text)
			text = [self get_section_collapsed_text_color];
		back = section.collapsed_back_color;
		if (!back)
			back = [self get_section_collapsed_back_color];
	} else {
		text = section.expanded_text_color;
		if (!text)
			text = [self get_section_expanded_text_color];
		back = section.expanded_back_color;
		if (!back)
			back = [self get_section_expanded_back_color];
	}

	[button setTitleColor:text forState:UIControlStateNormal];
	SET_ACCESSIBILITY_LANGUAGE(button);
	[button setBackgroundImage:[FLGloss_rectangle get:_DEFAULT_HEIGHT
		color:back] forState:UIControlStateNormal];
	if (section.interactive)
		button.accessibilityHint = section.collapsed ?  _e(31) : _e(32);
	// _31: Expand date
	// _32: Compress date
}

/** Returns the height for the section header.
 * Will return zero if the section is invisible.
 */
- (CGFloat)tableView:(UITableView *)tableView
	heightForHeaderInSection:(NSInteger)section_index
{
	FLSection_state *section = [self section_by_index:section_index];
	if (!section || !section.visible)
		return 0;

	// TODO: Parametrise the height.
	return _DEFAULT_HEIGHT;
}

@end
