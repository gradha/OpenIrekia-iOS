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
#import "gallery/FLStrip_view_controller.h"

#import "gallery/FLPhoto_view_controller.h"
#import "global/FLi18n.h"
#import "models/FLGallery_item.h"
#import "protocols/FLContainer_protocol.h"

#import "ELHASO.h"
#import "ShareKit/Core/SHK.h"
#import "ShareKit/Sharers/Services/Facebook/SHKFacebook.h"
#import "ShareKit/Sharers/Services/Twitter/SHKTwitter.h"

#define _DELAY_HUD				4
#define _CAPTION_ALPHA			0.3
#define _TEXT_PADDING			5
#define _PADDING				10


@interface FLStrip_view_controller ()
- (int)num_items;
- (void)cancel_pending_requests:(BOOL)all;
- (void)create_toolbar;
- (void)create_caption;
- (void)free_all_images;
- (void)free_hidden_photos:(int)range;
- (void)free_hidden_photos_strict;
- (void)queue_hud_hidding;
- (void)request_photo:(int)index;
- (void)scroll_to_page;
- (void)show_next_image;
- (void)show_prev_image;
- (void)update_hud;
- (void)change_caption:(FLGallery_item*)item;
@end


@implementation FLStrip_view_controller

@synthesize container = container_;
@synthesize group = group_;

#pragma mark -
#pragma mark Methods

- (void)loadView
{
	[super loadView];

	CGRect rect = [[UIScreen mainScreen] applicationFrame];
	rect.origin.x -= _PADDING;
	rect.size.width += 2 * _PADDING;
	scroll_ = [[FLCentered_scroll_view alloc] initWithFrame:rect];
	scroll_.backgroundColor = [UIColor blackColor];
	scroll_.pagingEnabled = YES;
	size_ = [self get_ipad_visible_area];
	scroll_.contentSize = CGSizeMake(2 * _PADDING + size_.width, size_.height);
	scroll_.scrollEnabled = YES;
	scroll_.bouncesZoom = YES;
	scroll_.scrollsToTop = NO;
	scroll_.showsHorizontalScrollIndicator = NO;
	scroll_.showsVerticalScrollIndicator = NO;
	scroll_.contentMode = UIViewContentModeScaleAspectFit;
	scroll_.autoresizingMask = 0;

	scroll_.delegate = self;
	[self.view addSubview:scroll_];
	[scroll_ release];

	[self show_right_button:@selector(share_button)
		item:UIBarButtonSystemItemAction];
	[self create_toolbar];
	[self create_caption];

	/* Full screen experience. */
	if (!IS_IPAD) {
		self.hidesBottomBarWhenPushed = YES;
		self.wantsFullScreenLayout = YES;
	}
	is_hud_on_ = YES;
}

- (void)dealloc
{
	if ([container_ respondsToSelector:@selector(disconnect_child:)])
		[container_ performSelector:@selector(disconnect_child:)
			withObject:self];
	container_ = nil;
	[self cancel_pending_requests:YES];
	[self.navigationController setToolbarHidden:YES animated:YES];

	[self free_all_images];
	if (images_)
		free(images_);
	[group_ release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	//DLOG(@"Strip view controller trying to free hidden photos...");
	[self free_hidden_photos_strict];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	/* Change the status bar on top to be translucent. */
	[[UIApplication sharedApplication]
		setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	self.navigationController.navigationBar.barStyle =
		UIBarStyleBlackTranslucent;

	/* Detect if the size has changed since the last time. This
	 * could happen when the user rotates the view while composing
	 * an email. Also there are some disturbing issues with
	 * rotation in the parent view, so we better force the code
	 * to reshape all views.
	 */
	size_ = [self get_ipad_visible_area];
	[self willAnimateRotationToInterfaceOrientation:0 duration:0];

	/* Re-force screen size. */
	CGRect rect = CGRectMake(0, 0, size_.width, size_.height);
	self.view.frame = rect;
	rect.origin.x -= _PADDING;
	rect.size.width += 2 * _PADDING;
	scroll_.frame = rect;

	/* Re-force scrolling to the page we want to appear in. */
	[self scroll_to_page];
	[self update_hud];
	[self queue_hud_hidding];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DLOG(@"View will dissappear! cancelling pending hide requests!");
	[super viewWillDisappear:animated];

	// Recover the previous status bar state. We expect it is normal.
	[self cancel_pending_requests:YES];
	[[UIApplication sharedApplication]
		setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (int)num_items
{
	return self.group.count;
}

/** Creates the toolbar_ for the view.
 * The toolbar has to be tracked manually and resized during
 * rotations. The toolbar contains buttons to go directly from one
 * picture to another.
 */
- (void)create_toolbar
{
	LASSERT(!toolbar_, @"create_toolbar called twice?");
	toolbar_ = [UIToolbar new];
	toolbar_.barStyle = UIBarStyleBlackTranslucent;

	// size up the toolbar and set its frame
	[toolbar_ sizeToFit];
	const CGFloat toolbarHeight = [toolbar_ frame].size.height;
	[toolbar_ setFrame:CGRectMake(0, size_.height - toolbarHeight,
		size_.width, toolbarHeight)];

	[self.view addSubview:toolbar_];

	UIBarButtonItemStyle style = UIBarButtonItemStylePlain;

	// flex item used to separate the left groups items and right grouped items
	UIBarButtonItem *space = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil action:nil];

	left_ = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"arrow_left.png"]
		style:style target:self action:@selector(show_prev_image)];
	SET_ACCESSIBILITY_LABEL(left_, _e(18));
	// _18: Previous

	right_ = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"arrow_right.png"]
		style:style target:self action:@selector(show_next_image)];
	SET_ACCESSIBILITY_LABEL(right_, _e(19));
	// _19: Next

	NSArray *items = [NSArray arrayWithObjects:space,
		left_, space, right_, space, nil];
	[toolbar_ setItems:items animated:YES];

	[left_ release];
	[right_ release];
	[space release];
	[toolbar_ release];
}

/** Creates the caption objects.
 * The caption view is just a semi translucid black view with a
 * label. This function creates the objects and puts them at the
 * bottom, hidden. To later change the caption just call change_caption.
 *
 * Call this function only once and after the toolbar is created,
 * since the caption gets the size from the toolbar.
 */
- (void)create_caption
{
	LASSERT(!caption_view_, @"create_caption called twice?");
	LASSERT(toolbar_, @"Call create_toolbar before this function");
	CGRect rect = toolbar_.frame;
	rect.origin.y -= rect.size.height;
	//rect.size.height = 0;
	caption_view_ = [[UIView alloc] initWithFrame:rect];
	caption_view_.backgroundColor = [UIColor blackColor];
	caption_view_.userInteractionEnabled = NO;
	caption_view_.alpha = _CAPTION_ALPHA;
	[self.view addSubview:caption_view_];
	[caption_view_ release];

	caption_label1_ = [[UILabel alloc] initWithFrame:rect];
	caption_label1_.font = [UIFont boldSystemFontOfSize:17];
	caption_label1_.lineBreakMode = UILineBreakModeTailTruncation;
	caption_label1_.numberOfLines = 0;
	caption_label1_.backgroundColor = [UIColor clearColor];
	caption_label1_.textColor = [UIColor whiteColor];
	caption_label1_.shadowColor = [UIColor blackColor];
	caption_label1_.shadowOffset = CGSizeMake(1, 1);
	[self.view addSubview:caption_label1_];
	[caption_label1_ release];

	caption_label2_ = [[UILabel alloc] initWithFrame:rect];
	caption_label2_.font = [UIFont systemFontOfSize:17];
	caption_label2_.lineBreakMode = UILineBreakModeTailTruncation;
	caption_label2_.numberOfLines = 0;
	caption_label2_.backgroundColor = [UIColor clearColor];
	caption_label2_.textColor = [UIColor whiteColor];
	caption_label2_.shadowColor = [UIColor blackColor];
	caption_label2_.shadowOffset = CGSizeMake(1, 1);
	[self.view addSubview:caption_label2_];
	[caption_label2_ release];
}

/** Cancells pending requests, all or only the hud hidding.
 * This can be called from dealloc or anywhere else. Pass YES if
 * you want to cancel all the pending requests, or NO if you only
 * want to prevent the hud from hidding.
 */
- (void)cancel_pending_requests:(BOOL)all
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(hide_hud) object:nil];

	if (all)
		[NSObject cancelPreviousPerformRequestsWithTarget:self
			selector:@selector(free_hidden_photos_strict) object:nil];
}

/** Helper method, frees all non null picture pointers.
 * This method doesn't free the array itself, only makes sure it
 * is clean after this call.
 */
- (void)free_all_images
{
	for (int f = 0; f < self.num_items; f++) {
		LASSERT(images_, @"Bad internal images_ pointer");
		if (images_[f])
			[images_[f].view removeFromSuperview];
		[images_[f] release];
		images_[f] = 0;
	}
}

/** Makes sure the photo index is being shown.
 * You can call this function any time with any parameter, it will
 * silently ignore errors. After you request some photos, you would
 * likely want to call free_hidden_photos_strict to remove past stuff.
 */
- (void)request_photo:(int)index
{
	if (!images_ || index < 0 || index >= self.num_items)
		return;

	/* Construct class controller if there is none. */
	if (!images_[index]) {
		images_[index] = [FLPhoto_view_controller new];
		[images_[index] set_tap_handler:self selector:@selector(toggle_hud)];
		images_[index].base_url = self.base_url;
		images_[index].cache_token = self.cache_token;
		images_[index].item = nil;
		[scroll_ addSubview:images_[index].view];
	}

	LASSERT(images_[index], @"Bad internal pointer");
	/* Associate image if there is none. */
	if (!images_[index].item) {
		//DLOG(@"Requesting new photo for index %d", index);
		images_[index].item = [self.group objectAtIndex:index];
		CGRect rect = images_[index].view.frame;
		rect.size = size_;
		rect.origin.x = _PADDING + (size_.width + 2 * _PADDING) * index;
		[images_[index] resize_frame:rect];
	}
}

- (void)free_hidden_photos_strict
{
	[self free_hidden_photos:2];
}

- (void)free_hidden_photos_lax
{
	[self free_hidden_photos:3];
}

/** Removes hidden photos to reduce memory consumption.
 * Call this method after you have changed the page_ variable. The
 * method will remove all the pictures which are not directly adjacent
 * to that index.
 *
 * We presume that the array contains contiguous nil values, to
 * avoid processing the whole stuff.
 */
- (void)free_hidden_photos:(int)range
{
	if (self.num_items < 1)
		return;

	range = MAX(2, range);

	LASSERT(images_, @"Bad internal pointer");
	for (int f = page_ - range; f >= 0; f--) {
		if (images_[f]) {
			//DLOG(@"Freeing hidden photo %d", f);
			[images_[f].view removeFromSuperview];
			[images_[f] release];
			images_[f] = 0;
		}
	}

	for (int f = page_ + range; f < self.num_items; f++) {
		if (images_[f]) {
			//DLOG(@"Freeing hidden photo %d", f);
			[images_[f].view removeFromSuperview];
			[images_[f] release];
			images_[f] = 0;
		}
	}
}

/// Speaks a voice over notification about the current photo index.
- (void)speak_voiceover_index
{
	// Temporary storage, avoid LLVM optimizations.
	BOOL available = (NULL != &UIAccessibilityPageScrolledNotification);
	if (!available)
		return;

	UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification,
		[NSString stringWithFormat:_e(28), [NSNumber numberWithInt:1 + page_],
		[NSNumber numberWithInt:self.num_items]]);
	// _28: %$1@ of %$2@
}

/** Tries to show the previous photo without animation.
 */
- (void)show_prev_image
{
	if (page_ < 1)
		return;

	page_--;
	[self scroll_to_page];
	[self update_hud];
	[self free_hidden_photos_strict];
	[self queue_hud_hidding];
	[self.container switch_item:0];
	[self speak_voiceover_index];
}

/** Tries to show the previous photo without animation.
 */
- (void)show_next_image
{
	if (page_ >= self.num_items - 1)
		return;

	page_++;
	[self scroll_to_page];
	[self update_hud];
	[self free_hidden_photos_strict];
	[self queue_hud_hidding];
	[self.container switch_item:0];
	[self speak_voiceover_index];
}

/** Sets the group.
 * This will retain the group and also remove/resize the current image array.
 * The page index will be reset. You should set the item of the
 * class next to know what page should we be looking at.
 */
- (void)setGroup:(NSArray*)group
{
	if (group_ == group)
		return;

	UIView *v = self.view; // Hack to force loading of the view. Ugly!
	v = nil;

	DLOG(@"Setting new group of %d elements", group.count);
	[self free_all_images];
	[group retain];
	[group_ release];
	group_ = group;
	page_ = 0;

	// Reallocate array of image pointers.
	const size_t mem_size = sizeof(FLPhoto_view_controller*) * self.num_items;
	images_ = reallocf(images_, mem_size);
	if (!images_ && mem_size > 0) {
		LOG(@"Couldn't allocate pointer array for %d images (%ld bytes)",
			self.num_items, mem_size);
		LASSERT(images_, @"Not enough memory");
		self.group = nil;
	} else if (mem_size > 0) {
		LASSERT(images_, @"Bad programmer");
		memset(images_, 0, mem_size);
	}

	// Update content size.
	scroll_.contentSize = CGSizeMake(
		(2 * _PADDING + size_.width) * self.num_items, size_.height);
	[self update_hud];
}

/** Sets the index page through an item pointer.
 * The function searches the pointer in the current group and sets that.
 * If not found, sets the page to the first element.
 */
- (void)setItem:(FLGallery_item*)item
{
	page_ = 0;

	if (self.num_items < 1)
		return;

	// Do we have that pointer?
	for (int f = 0; f < self.num_items; f++) {
		FLGallery_item* group_item = [self.group objectAtIndex:f];
		if (group_item == item) {
			page_ = f;
			break;
		}
	}

	[self scroll_to_page];
	[self update_hud];
}

/** Returns the pointer to the currently viewable item.
 * Returns nil if there is no gallery or there is some problem.
 */
- (FLGallery_item*)item
{
	if (self.num_items < 1)
		return nil;

	RASSERT(page_ >= 0 && page_ < self.num_items, @"Bad internal page index",
		return nil);
	return [self.group objectAtIndex:page_];
}

/** Updates the title bar and toolbar.
 * This includes showing a numeric position in the title, toggling
 * the share button, updating the caption text and toggling the
 * prev/next arrows.
 */
- (void)update_hud
{
	const int total = self.num_items;
	self.right_button.enabled = (nil != self.item.share_url);
	self.navigationItem.title = [NSString stringWithFormat:_e(28),
		[NSNumber numberWithInt:1 + page_], [NSNumber numberWithInt:total]];
	// _28: %$1@ of %$2@
	left_.enabled = page_ > 0;
	right_.enabled = page_ < total - 1;

	[self change_caption:self.item];
}

/** Changes the caption label to a new text.
 * The change will also resize the background caption view. If this
 * is called with the HUD off (is_hud_on_), the text won't be changed
 * so that the text of existing fading off animations is not modified.
 */
- (void)change_caption:(FLGallery_item*)item
{
	if (!is_hud_on_)
		return;

	caption_label1_.text = item.title;
	caption_label2_.text = item.caption_text;
	CGSize size1 = [caption_label1_
		sizeThatFits:CGSizeMake(size_.width - 2 * _TEXT_PADDING, 500)];
	CGSize size2 = [caption_label2_
		sizeThatFits:CGSizeMake(size_.width - 2 * _TEXT_PADDING, 500)];
	CGFloat height = size1.height > 0 ? size1.height + 2 * _TEXT_PADDING : 0;
	if (size2.height > 0) {
		if (height < 1)
			height = 2 * _TEXT_PADDING;
		height += size2.height;
	}

	CGRect rect = toolbar_.frame;
	rect.origin.y -= height;
	rect.size.height = height;
	caption_view_.frame = rect;

	rect.origin.x += _TEXT_PADDING;
	rect.origin.y += _TEXT_PADDING;
	rect.size.width -= 2 * _TEXT_PADDING;
	rect.size.height = size1.height;
	caption_label1_.frame = rect;

	rect.origin.y += size1.height;
	rect.size.height = size2.height;
	caption_label2_.frame = rect;
}

/** Changes the hud to be on/off.
 * This is used as an action by the child FLPhoto_view_controller.
 */
- (void)toggle_hud
{
	if ([NSThread isMainThread])
		[self performSelector:@selector(toggle_hud_worker)
			withObject:nil];
	else
		[self performSelectorOnMainThread:@selector(toggle_hud_worker)
			withObject:nil waitUntilDone:YES];
}

/// Actual worker which performs hud toggling in the UI thread.
- (void)toggle_hud_worker
{
	BLOCK_UI();
	[UIView beginAnimations:@"hud_toggle" context:nil];
	[UIView setAnimationDuration:0.5];
	toolbar_.alpha = is_hud_on_	? 0 : 1;
	caption_view_.alpha = is_hud_on_ ? 0 : _CAPTION_ALPHA;
	caption_label1_.alpha = is_hud_on_ ? 0 : 1;
	caption_label2_.alpha = is_hud_on_ ? 0 : 1;
	self.navigationController.navigationBar.alpha = toolbar_.alpha;
	[UIView commitAnimations];

	if (!IS_IPAD)
		[[UIApplication sharedApplication]
			setStatusBarHidden:is_hud_on_ animated:YES];

	is_hud_on_ = !is_hud_on_;

	// Refresh text, just in case.
	[self change_caption:self.item];

	if (is_hud_on_) {
		[self queue_hud_hidding];
		/* Force redisplaying of the navigation bar.
		 * Otherwise, If the user had rotated the view with
		 * the status bar hidden, it would appear beneath the
		 * status bar. Ugly.
		 */
		[self.navigationController setNavigationBarHidden:YES animated:NO];
		[self.navigationController setNavigationBarHidden:NO animated:NO];
	}
}

/** Repeated lines of code to cancel previous hide request and enqueue a new
 * one.
 */
- (void)queue_hud_hidding
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(hide_hud) object:nil];
	[self performSelector:@selector(hide_hud) withObject:nil
		afterDelay:_DELAY_HUD];
}

/// If the hud is on, tries to force it off, only if accessibility is off.
- (void)hide_hud
{
	BOOL toggle = is_hud_on_;
	if (UIAccessibilityIsVoiceOverRunning &&
			UIAccessibilityIsVoiceOverRunning())
		toggle = NO;

	if (toggle)
		[self toggle_hud];
}

- (void)willAnimateRotationToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
	duration:(NSTimeInterval)duration
{
	scroll_.contentSize = CGSizeMake(
		(2 * _PADDING + size_.width) * self.num_items, size_.height);
	//DLOG(@"Content size now %0.0f", scroll_.contentSize.width);
	scroll_.frame = CGRectMake(-_PADDING, 0,
		size_.width + 2 * _PADDING, size_.height);

	// Reset the scroll of children.
	CGRect rect;
	for (int f = 0; f < self.num_items; f++) {
		if (images_[f]) {
			rect = images_[f].view.frame;
			rect.size = size_;
			rect.origin.x = _PADDING + (size_.width + 2 * _PADDING) * f;
			[images_[f] resize_frame:rect];
		}
	}

	ignore_scrolls_ = NO;
	//DLOG(@"Will animate to page %d...", page_);
	rect = CGRectMake(page_ * (2 * _PADDING + size_.width), 0,
		size_.width + 2 * _PADDING, size_.height);
	//LOG(@"Parent scrolling to %0.0f sized %0.0f, %0.0f", rect.origin.x,
	//	size_.width, size_.height);
	[scroll_ scrollRectToVisible:rect animated:NO];

	// Reset the toolbar to be at the bottom of the screen.
	rect = toolbar_.frame;
	rect.origin.x = 0;
	rect.origin.y = size_.height - rect.size.height;
	rect.size.width = size_.width;
	toolbar_.frame = rect;

	// Make the caption view resize itself, forcing it first to nil.
	[self change_caption:nil];
	[self change_caption:self.item];
}

- (void)willRotateToInterfaceOrientation:
	(UIInterfaceOrientation)toInterfaceOrientation
	duration:(NSTimeInterval)duration
{
	ignore_scrolls_ = YES;
	DLOG(@"Rotating! Weeeeee, we were looking at page %d", page_);

	const BOOL to_landscape =
		(UIInterfaceOrientationLandscapeRight == toInterfaceOrientation ||
			UIInterfaceOrientationLandscapeLeft == toInterfaceOrientation);
	if (IS_IPAD) {
		/* iPads have a non full screen view, they require special sizes. */
		if (to_landscape) {
			size_.width = 1024 - 320;
			size_.height = 768;
		} else {
			size_.width = 768;
			size_.height = 1024;
		}
		const CGRect rect = [[UIApplication sharedApplication] statusBarFrame];
		const CGFloat offset = MIN(rect.size.width, rect.size.height);
		size_.height -= offset;
	} else {
		// Detect and store the new size.
		size_ = [self get_ipad_visible_area];
		BOOL swap = NO;
		if (to_landscape) {
			// We are going to rotate to landscape. Width has to be bigger.
			if (size_.width < size_.height)
				swap = YES;
		} else {
			// We are going to rotate to portrait. Width has to be smaller.
			if (size_.height < size_.width)
				swap = YES;
		}

		if (swap) {
			CGFloat temp = size_.height;
			size_.height = size_.width;
			size_.width = temp;
		}
	}
}

#pragma mark Scroll functions

/** Forces the scroll to show the currently active page.
 * No animation, immediate scrolling. Verify page_ and size_ have sane values.
 * The pictures for the current page and previos/next will be requested.
 */
- (void)scroll_to_page
{
	[scroll_ scrollRectToVisible:CGRectMake(
		page_ * (2 * _PADDING + size_.width), 0,
		size_.width + 2 * _PADDING, size_.height) animated:NO];

	// Make sure the pictures we are viewing are created.
	for (int f = page_ - 1; f < page_ + 2; f++)
		[self request_photo:f];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
	if (ignore_scrolls_)
		return;

	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(free_hidden_photos_strict) object:nil];

	if (is_hud_on_ && scroll_.tracking)
		[self toggle_hud];

	// Switch the indicator when more than 50% of the previous/next
	// page is visible
	const CGFloat page_width = 2 * _PADDING + size_.width;

#if 0
	// Detect the intention of direction of the sliding movement.
	// Try to preload at the beginning of flick to avoid stutters.
	if (scroll_.tracking) {
		const CGFloat predict_page_x = MAX(0, MIN(self.num_items, 1 +
			(scroll_.contentOffset.x) / page_width));
		const CGFloat diff = predict_page_x - page_;
		if (diff > 1)
			[self request_photo:page_ + 2];
		else
			[self request_photo:page_ - 2];
	}
#endif
	//DLOG(@"content offset %0.0f", scroll_.contentOffset.x);
	const int new_page = MAX(0, MIN(self.num_items - 1, 1 + floor(
		(scroll_.contentOffset.x - page_width / 2) / page_width)));

	/* If the new page is not the same, request new pages to view. */
	if (new_page != page_) {
		[self request_photo:new_page - 1];
		[self request_photo:new_page];
		[self request_photo:new_page + 1];
		page_ = new_page;
		[self free_hidden_photos_lax];
		[self update_hud];
		[self.container switch_item:0];
	}

	[self performSelector:@selector(free_hidden_photos_strict) withObject:nil
		afterDelay:1];
}

/** Special hook for the FLISplit_view_controller.
 * When the user touches the sections button in portrait, the
 * navigation bar would continue to hide after several seconds. This
 * prevents the hiding from happening.
 */
- (void)cancel_hud_hidding
{
	LASSERT(IS_IPAD, @"Why are you calling this?");
	[self cancel_pending_requests:NO];
}

#pragma mark UIActionsheet

- (void)share_button
{
	FLGallery_item *item = self.item;
	LASSERT(item.share_url, @"Item doesn't have URL to share?");
	if (!item.share_url)
		return;

	[self cancel_pending_requests:NO];
	[self show_share_actions:STR_PICTURE_SHARING_TITLE];
}

/** Special action handler that avoids knowing the index button.
 */
- (void)handle_action:(NSNumber*)action
{
	switch ([action intValue]) {
		case ACTION_COPY_URL:
			[UIPasteboard generalPasteboard].string = self.item.share_url;
			break;
		case ACTION_MAIL_URL: {
			[self show_mail_composer:self.item subject:STR_MAIL_PICTURE_SUBJECT
				body:(self.item.caption_text.length > 0) ?
					STR_MAIL_PICTURE_BODY_DESC : STR_MAIL_PICTURE_BODY];
			return;
		}
		case ACTION_TWIT_URL: {
			NSURL *url = [NSURL URLWithString:self.item.share_url];
			SHKItem *item = [SHKItem URL:url
				title:NON_NIL_STRING(self.item.title)];
			[SHKTwitter shareItem:item];
			break;
		}
		case ACTION_FACEBOOK_URL: {
			NSString *filter = @"\"'<>&?\\";

			NSString *clean = [[NON_NIL_STRING(self.item.title)
				componentsSeparatedByCharactersInSet:[NSCharacterSet
				characterSetWithCharactersInString:filter]]
				componentsJoinedByString:@""];
			DLOG(@"Filtered %@", clean);

			NSURL *url = [NSURL URLWithString:self.item.share_url];
			SHKItem *item = [SHKItem URL:url title:clean];
			[SHKFacebook shareItem:item];
			break;
		}
		default:
			break;
	}

	[self queue_hud_hidding];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
	didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[super mailComposeController:controller
		didFinishWithResult:result error:error];
	[self queue_hud_hidding];
}

@end
