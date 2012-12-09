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
#import "video/FLMovie_view_controller.h"

#import "categories/NSDictionary+Floki.h"
#import "categories/NSString+Floki.h"
#import "global/FLi18n.h"
#import "global/FlokiAppDelegate.h"
#import "models/FLContent_item.h"
#import "structures/FLMovie_cell_data.h"
#import "video/FLMovie_button_cell.h"
#import "video/FLMovie_text_cell.h"

#import "ELHASO.h"
#import "NSArray+ELHASO.h"
#import "SBJson.h"
#import "ShareKit/Core/SHK.h"
#import "ShareKit/Sharers/Services/Facebook/SHKFacebook.h"
#import "ShareKit/Sharers/Services/Twitter/SHKTwitter.h"

#import <MediaPlayer/MediaPlayer.h>


#define _MIN_SIZE			30
#define _MAX_WIDTH			285
#define _MAX_HEIGHT			160
#define _MAX_IPAD_WIDTH		450
#define _MAX_IPAD_HEIGHT	400
#define _DELAY				0.1

#define _BUTTON_ROW			1
#define _TEXT_ROW			0


@interface FLMovie_view_controller ()
- (void)play_movie;
- (void)start_movie;
- (void)movie_finished_callback:(NSNotification*)notification;
- (void)share_button;
@end


@implementation FLMovie_view_controller

@synthesize cell_data = cell_data_;
@synthesize item_id = item_id_;
@synthesize share_url = share_url_;

#pragma mark -
#pragma mark Methods

/** Pseudo constructor, pass JSON dictionary.
 * Stores all the required data for later use. Doesn't actually
 * modify anything else.
 */
- (BOOL)init_with_data:(NSDictionary*)data unique_id:(int)unique_id
{
	FLMovie_cell_data *cell_data = [FLMovie_cell_data new];
	RASSERT(cell_data, "Not enough memory for movie cell data", return NO);
	self.cell_data = cell_data;
	[cell_data release];

	unique_id_ = unique_id;
	url_ = [[data objectForKey:@"main_url"] retain];
	self.base_url = [url_ stringByRemovingFragment];
	cell_data->padding = [data get_int:@"padding" def:3];
	cell_data.preview_url = [data objectForKey:@"preview_url"];
	cell_data->preview_width = [data get_int:@"preview_width" def:10000];
	cell_data->preview_height = [data get_int:@"preview_height" def:10000];

	if (IS_IPAD) {
		cell_data->preview_width = MIN(_MAX_IPAD_WIDTH, MAX(_MIN_SIZE,
			cell_data->preview_width));
		cell_data->preview_height = MIN(_MAX_IPAD_HEIGHT, MAX(_MIN_SIZE,
			cell_data->preview_height));
	} else {
		cell_data->preview_width = MIN(_MAX_WIDTH, MAX(_MIN_SIZE,
			cell_data->preview_width));
		cell_data->preview_height = MIN(_MAX_HEIGHT, MAX(_MIN_SIZE,
			cell_data->preview_height));
	}
	cell_data->title_lines = MAX(1, [data get_int:@"title_lines" def:10]);
	cell_data->title_size = [data get_int:@"title_size" def:16];
	cell_data->text_size = [data get_int:@"text_size" def:13];
	cell_data.title_color = [data get_color:@"title_color"
		def:[UIColor blueColor]];
	cell_data.text_color = [data get_color:@"text_color"
		def:[UIColor blackColor]];
	cell_data.playback_color = [data get_color:@"playback_color"
		def:[UIColor lightGrayColor]];
	cell_data.back_color = [data get_color:@"back_normal_color"
		def:[UIColor whiteColor]];
	cell_data->autoload = [data get_bool:@"autoload" def:true];

	if (!url_ ||  unique_id_ < 1) {
		LOG(@"Failed initialisation of FLMovie_view_controller %@", data);
		return NO;
	}

	/* Retrieve the texts for the details cell. If there is no
	 * specific text, try the identifiers.
	 */
	const int title_id = [data get_int:@"title_id" def:-1];
	const int text_id = [data get_int:@"text_id" def:-1];
	cell_data.title = [data objectForKey:@"title"];
	cell_data.text = [data objectForKey:@"text"];
	if (title_id >= 0 && !cell_data.title) cell_data.title = _(title_id);
	if (text_id >= 0 && !cell_data.text) cell_data.text = _(text_id);

	return YES;
}

- (void)dealloc
{
	[connection_ cancel];
	[self movie_finished_callback:nil];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[share_url_ release];
	[item_id_ release];
	[cell_identifier_ release];
	[url_ release];
	[cell_data_ release];
	[super dealloc];
}

- (void)loadView
{
	[super loadView];

	/* Remember now what kind of device we are. */
	is_ipad_or_ios4_ = IS_IPAD || [[UIDevice currentDevice]
			respondsToSelector:@selector(isMultitaskingSupported)];

	/* We want to know when we are being rotated. */
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(orientationChanged:)
		name:UIDeviceOrientationDidChangeNotification object:nil];

	[self show_right_button:@selector(share_button)
		item:UIBarButtonSystemItemAction];
	self.right_button.enabled = (self.share_url.length > 0);
	self.navigationItem.title = @"";

	/* Hide extra lines of table below content. Kudos to wkw:
	 * http://stackoverflow.com/questions/1369831/eliminate-extra-separators-below-uitableview-in-iphone-sdk
	 */
	UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
	footer.backgroundColor = [UIColor clearColor];
	[self.tableView setTableFooterView:footer];
	[footer release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (queue_reload_) {
		DLOG(@"Reloading table due to hidden request");
		[self.tableView reloadData];
		queue_reload_ = NO;
	}

	self.right_button.enabled = (self.share_url.length > 0);
	if (!self.cell_data)
		self.navigationItem.title = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	is_visible_ = YES;
	if (self.cell_data && self.cell_data->autoload && !did_play_once_)
		[self play_movie];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	is_visible_ = NO;
	queue_reload_ = NO;
}

- (NSString*)name_for_cache
{
	LASSERT(url_, @"Empty url?");
	LASSERT([[FLi18n get] current_langcode], @"Bad initialisation sequence");
	return url_;
}

- (int)unique_id
{
	return unique_id_;
}

- (void)orientationChanged:(NSNotification *)notification
{
	if (is_visible_) {
		DLOG(@"Reloading table due to orientation change");
		[self.tableView reloadData];
	} else {
		queue_reload_ = YES;
	}
}

/** Override only because we want to control the right button.
 * Other than that the setter is pretty standard.
 */
- (void)setShare_url:(NSString*)share_url
{
	if (share_url_ == share_url)
		return;

	[share_url retain];
	[share_url_ release];
	share_url_ = share_url;

	self.right_button.enabled = (share_url.length > 0);
}

#pragma mark -
#pragma mark Download/spawn methods

/** Starts the download of a specific JSON item for the controller.
 * This method is used when a video view controller is spawned. In a normal
 * situation this view controller is spawn with the JSON already being known.
 * However, in this situation we actually have to go and fetch the JSON and
 * test if it is valid.
 */
- (void)download_json:(NSString*)url
{
	RASSERT(url.length > 0, @"Empty url?", return);
	RASSERT(!connection_, @"Already forced a connection?", return);
	self.forced_url = url;
	connection_ = (id)[[FLRemote_connection alloc]
		init_with_action:@selector(did_receive_json:error:) target:self];
	[activity_indicator_ startAnimating];
	[connection_ request:self.forced_url];
	[self show_shield_screen];
}

/** Handles reception of the JSON with the video info.
 * This actually calls init_with_data simulating the construction of the
 * controller in a delayed fashion.
 */
- (void)did_receive_json:(FLRemote_connection*)response error:(NSError*)error
{
	if (error) {
		DLOG(@"Ignoring net error: %@.", error);
		[self show_error:error.localizedDescription];
		[self hide_shield_screen];
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
	NSArray *items = [result
		get_array:@"items" of:[NSDictionary class] def:nil];
	NSDictionary *source = CAST([items get:0], NSDictionary);
	NSDictionary *source_data = [source get_dict:@"data" def:nil];
	[activity_indicator_ stopAnimating];
	if (!source_data || self.forced_url.length < 1) {
		DLOG(@"Failed input data or forced url param");
		goto error;
	}

	NSMutableDictionary *data = [NSMutableDictionary
		dictionaryWithDictionary:source_data];
	// Set default forced URL for the video.
	[data setValue:[source get_string:@"url" def:self.forced_url]
		forKey:@"main_url"];
	// Force a title if the sub-data doesn't contain any.
	if (![data get_string:@"title" def:nil])
		[data setValue:[source get_string:@"title" def:@""] forKey:@"title"];
	if (![data get_string:@"text" def:nil])
		[data setValue:[source get_string:@"body" def:@""] forKey:@"text"];

	if (![self init_with_data:data unique_id:10000]) {
		DLOG(@"Failed initialization");
		goto error;
	}
	unique_id_ = -1;
	self.navigationItem.title = @"";
	[self.tableView reloadData];
	[self hide_shield_screen];
	return;

error:
	DLOG(@"Couldn't process JSON: %@", response);
	[self show_error:_e(22)];
	// _22: Error processing data
	[self hide_shield_screen];
}

#pragma mark -
#pragma mark Video methods

/** Starts to play the movie.
 * Actually this only starts spinning the wheel and queues start_movie to
 * be responsive.
 */
- (void)play_movie
{
	if (movie_) {
		DLOG(@"Hey, the movie is already being played!");
		return;
	}

	// Tell the button cell that we are playing.
	FLMovie_button_cell *cell = (FLMovie_button_cell*)[self.tableView
		cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_BUTTON_ROW
		inSection:0]];
	[cell start];

	[self performSelector:@selector(start_movie) withObject:nil
		afterDelay:_DELAY];
}

/** Part of play_movie.
 * Separated from play_movie because creating the movie player
 * controller is slow and we want the UI to be responsive. So this gets called
 * after the UI has had chance to update the spinning wheel.
 */
- (void)start_movie
{
	did_play_once_ = YES;
	LASSERT(!movie_, @"Bad internal movie state");
	NSURL *url = [NSURL URLWithString:url_];

	if (is_ipad_or_ios4_) {
		LASSERT(!movie_controller_, @"Bad internal movie state");
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
		movie_controller_ = [[MPMoviePlayerViewController alloc]
			initWithContentURL:url];
#endif
		movie_ = [movie_controller_ performSelector:@selector(moviePlayer)];
		movie_.view.backgroundColor = [UIColor blackColor];
		LASSERT(movie_, @"Ugh, couldn't get player class");
	} else {
		movie_ = [[MPMoviePlayerController alloc] initWithContentURL:url];
		movie_.scalingMode = MPMovieScalingModeAspectFill;
	}

	// Register for the playback finished notification.
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(movie_finished_callback:)
		name:MPMoviePlayerPlaybackDidFinishNotification object:movie_];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (is_ipad_or_ios4_)
		[self presentMoviePlayerViewControllerAnimated:movie_controller_];
#endif

	/* Try to detect allowsAirPlay attribute. */
	SEL airplay_selector = @selector(setAllowsAirPlay:);
	if ([movie_ respondsToSelector:airplay_selector]) {
		DLOG(@"Supports airplay, activating!");
		BOOL param = YES;
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[movie_
				methodSignatureForSelector:airplay_selector]];
		[inv setSelector:airplay_selector];
		[inv setTarget:movie_];
		[inv setArgument:&param atIndex:2];
		[inv invoke];
	}

	[movie_ play];
}

/** Apparently there's a rotation bug in the ipad movie viewer. See:
 * http://stackoverflow.com/questions/3089692/ipad-rotation-bug-when-using-mpmovieplayerviewcontroller
 * But this is modified, we hook the fix for the status bar after
 * the movie has finished, not earlier.
 *
 * This also tries to fix the split viewer section button just in
 * case it was rotated. You know, during the full screen playback
 * rotations seem to be lost to all other views.
 */

- (void)fix_status_bar
{
	DLOG(@"fix_status_bar!");
	UIInterfaceOrientation orientation = [self interfaceOrientation];
	[[UIApplication sharedApplication]
		setStatusBarOrientation:orientation animated:NO];

	id split_view = ASK_GETTER(self, splitViewController, nil);
	ASK_GETTER(split_view, hide_landscape_button, nil);
}

/// When the movie is done, release the controller.
- (void)movie_finished_callback:(NSNotification*)notification
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

	if (!movie_)
		return;

	DLOG(@"movie_finished_callback %@, movie %@", notification, movie_);
	[[NSNotificationCenter defaultCenter] removeObserver:self
		name:MPMoviePlayerPlaybackDidFinishNotification object:movie_];

	// set initialPlaybackTime property of the MPMoviePlayerController
	// class to -1.0 to prevent continued playback in case user
	// closes movie player before pre loading has finished. Credits
	// go to http://icodeblog.com/2009/07/21/anyone-else-having-issues-with-mpmovieplayercontroller-in-iphone-os-3-0/.
	[movie_ stop];
	movie_.initialPlaybackTime = -1.0;

	if (is_ipad_or_ios4_) {
		[movie_controller_ autorelease];
	} else {
		[movie_ autorelease];
	}
	movie_controller_ = nil;
	movie_ = nil;

	// Tell the button cell that we are stopping.
	FLMovie_button_cell *cell = (FLMovie_button_cell*)[self.tableView
		cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_BUTTON_ROW
		inSection:0]];
	[cell stop];
	[self performSelector:@selector(fix_status_bar) withObject:nil
		afterDelay:0];
}

#pragma mark -
#pragma mark Table view methods

- (CGFloat)tableView:(UITableView *)tableView
	heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const CGSize size = [self get_ipad_visible_area];
	if (_TEXT_ROW == indexPath.row)
		return [FLMovie_text_cell
			height_for_text:self.cell_data width:size.width];
	else
		return [FLMovie_button_cell height_for_text:self.cell_data];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.cell_data ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return self.cell_data ? 2 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!cell_identifier_) {
		cell_identifier_ = [[NSString alloc] initWithFormat:@"FLMovie_cell_%d",
			unique_id_];
		LASSERT(cell_identifier_, @"Couldn't generate cell identifier");
	}

	NSString *identifier = [NSString stringWithFormat:@"%s_%d",
		cell_identifier_, indexPath.row];

	UITableViewCell *cell = [tableView
		dequeueReusableCellWithIdentifier:identifier];

	if (cell == nil) {
		/* Create new cells */
		if (_TEXT_ROW == indexPath.row) {
			FLMovie_text_cell *movie_cell = [[[FLMovie_text_cell alloc]
				initWithStyle:UITableViewCellStyleDefault
				reuseIdentifier:identifier] autorelease];
			movie_cell.data = self.cell_data;
			cell = movie_cell;
		} else {
			FLMovie_button_cell *movie_cell = [[[FLMovie_button_cell alloc]
				initWithStyle:UITableViewCellStyleDefault
				reuseIdentifier:identifier] autorelease];
			movie_cell.data = self.cell_data;
			cell = movie_cell;
		}
	} else {
		DLOG(@"Reusing old movie cells...");
		if (_TEXT_ROW == indexPath.row) {
			FLMovie_text_cell *movie_cell = (FLMovie_text_cell*)cell;
			movie_cell.data = self.cell_data;
		} else {
			FLMovie_button_cell *movie_cell = (FLMovie_button_cell*)cell;
			movie_cell.data = self.cell_data;
		}
	}

	return cell;
}

- (void)tableView:(UITableView*)tableView
	didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (_BUTTON_ROW == indexPath.row)
		[self play_movie];
}

#pragma mark -
#pragma mark UIActionsheet

- (void)share_button
{
	LASSERT(self.share_url.length > 0, @"Item doesn't have URL to share?");
	if (self.share_url.length < 1)
		return;

	[self show_share_actions:STR_MOVIE_SHARING_TITLE];
}

/** Special action handler that avoids knowing the index button.
 */
- (void)handle_action:(NSNumber*)action
{
	switch ([action intValue]) {
		case ACTION_COPY_URL:
			[UIPasteboard generalPasteboard].string = self.share_url;
			break;
		case ACTION_MAIL_URL: {
			FLContent_item *item = [FLContent_item new];
			item.title = self.cell_data.title;
			item.share_url = self.share_url;
			[self show_mail_composer:item subject:STR_MAIL_MOVIE_SUBJECT
				body:STR_MAIL_MOVIE_BODY];
			[item release];
			break;
		}
		case ACTION_TWIT_URL: {
			NSURL *url = [NSURL URLWithString:self.share_url];
			SHKItem *item = [SHKItem URL:url
				title:NON_NIL_STRING(self.cell_data.title)];
			[SHKTwitter shareItem:item];
			break;
		}
		case ACTION_FACEBOOK_URL: {
			NSString *filter = @"\"'<>&?\\";

			NSString *clean = [[NON_NIL_STRING(self.cell_data.title)
				componentsSeparatedByCharactersInSet:[NSCharacterSet
				characterSetWithCharactersInString:filter]]
				componentsJoinedByString:@""];
			DLOG(@"Filtered %@", clean);

			NSURL *url = [NSURL URLWithString:self.share_url];
			SHKItem *item = [SHKItem URL:url title:clean];
			[SHKFacebook shareItem:item];
			break;
		}
		default:
			break;
	}
}

@end
