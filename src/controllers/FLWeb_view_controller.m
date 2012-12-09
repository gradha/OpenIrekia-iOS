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
#import "controllers/FLWeb_view_controller.h"

#import "categories/NSDictionary+Floki.h"
#import "global/FLi18n.h"
#import "global/FlokiAppDelegate.h"
#import "structures/FLRegex_match.h"

#import "ELHASO.h"
#import "NSArray+ELHASO.h"
#import "NSMutableArray+ELHASO.h"
#import "RegexKitLite.h"


/// Holds all the regular expressions that have to be tested for tag links.
static NSMutableArray *_gTags;

/// Holds all the regular expressions that have to be tested for video links.
static NSMutableArray *_gVideos;

/// Holds all the regular expressions that have to be tested for gallery links.
static NSMutableArray *_gGallery;


@interface FLWeb_view_controller ()
- (void)create_toolbar;
- (void)reposition_toolbar;
- (void)update_toolbar_actions;
- (void)open_safari;
@end


@implementation FLWeb_view_controller

@synthesize main_url = main_url_;
@synthesize push_external = push_external_;
@synthesize show_interface = show_interface_;

#pragma mark -
#pragma mark Methods

+ (void)initialize
{
	if (_gTags)
		return;

	_gTags = [[NSMutableArray alloc] initWithCapacity:5];
	_gVideos = [[NSMutableArray alloc] initWithCapacity:5];
	_gGallery = [[NSMutableArray alloc] initWithCapacity:5];
}

- (BOOL)init_with_data:(NSDictionary*)data unique_id:(int)unique_id
{
	self.main_url = [data objectForKey:@"main_url"];
	scales_page_to_fit_ = [data get_bool:@"scales_page_to_fit" def:NO];
	unique_id_ = unique_id;
	self.push_external = YES;

	if (!self.main_url || unique_id_ < 1) {
		LOG(@"Failed initialisation of FLWeb_view_controller %@", data);
		return NO;
	}
	return YES;
}

- (void)dealloc
{
	if ([web_view_ isLoading]) {
		[web_view_ stopLoading];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}

	web_view_.delegate = nil;
	[main_url_ release];
	[super dealloc];
}

- (void)loadView
{
	[super loadView];

	web_view_ = [[UIWebView alloc] initWithFrame:self.view.frame];
	web_view_.scalesPageToFit = self.show_interface ? YES : scales_page_to_fit_;
	web_view_.delegate = self;
	web_view_.frame = self.view.bounds;
	web_view_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:web_view_];
	[web_view_ release];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;

	if (self.show_interface) {
		[self create_toolbar];

		UIBarButtonItem *button = [[UIBarButtonItem alloc]
			initWithTitle:_e(23) style:UIBarButtonItemStyleBordered
			target:self action:@selector(open_safari)];
		// _23: Safari
		self.navigationItem.rightBarButtonItem = button;
		[button release];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	if (self.main_url) {
		DLOG(@"Requesting URL '%@'", self.main_url);
		[web_view_ loadRequest:[NSURLRequest
			requestWithURL:[NSURL URLWithString:self.main_url]]];
		[self show_shield_screen];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reposition_toolbar];
}

- (int)unique_id
{
	return unique_id_;
}

#pragma mark -
#pragma mark Toolbar controls

/** Creates the navigation toolbar.
 * Puts in toolbar_ the pointer, but doesn't require releasing.
 */
- (void)create_toolbar
{
	toolbar_ = [UIToolbar new];
	toolbar_.barStyle = UIBarStyleDefault;
	web_view_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	[toolbar_ sizeToFit];
	[web_view_ addSubview:toolbar_];
	[toolbar_ release];

	UIBarButtonItemStyle style = UIBarButtonItemStylePlain;

	// flex item used to separate the left groups items and right grouped items
	UIBarButtonItem *space = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil action:nil];

	left_ = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"arrow_left.png"]
		style:style target:web_view_ action:@selector(goBack)];
	SET_ACCESSIBILITY_LABEL(left_, _e(24));
	// _24: Back

	right_ = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"arrow_right.png"]
		style:style target:web_view_ action:@selector(goForward)];
	SET_ACCESSIBILITY_LABEL(right_, _e(25));
	// _25: Forward

	UIBarButtonItem *reload = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
		target:web_view_ action:@selector(reload)];
	SET_ACCESSIBILITY_LABEL(reload, _e(26));
	// _26: Reload

	NSArray *items = [NSArray arrayWithObjects:space,
		left_, space, reload, space, right_, space, nil];
	[toolbar_ setItems:items animated:NO];

	[left_ release];
	[right_ release];
	[space release];
	[reload release];
	[self update_toolbar_actions];
}

/** Updates the position of the toolbar to be at the bottom of the screen.
 */
- (void)reposition_toolbar
{
	CGRect rect = web_view_.frame;
	rect.origin.y += rect.size.height;
	rect.size.height = toolbar_.frame.size.height;
	rect.origin.y -= rect.size.height;
	toolbar_.frame = rect;
}

- (void)update_toolbar_actions
{
	left_.enabled = web_view_.canGoBack;
	right_.enabled = web_view_.canGoForward;
}

- (void)open_safari
{
	NSURL *url = [[web_view_ request] URL];
	DLOG(@"Trying to open external URL %@", url);
	if ([[UIApplication sharedApplication] openURL:url])
		exit(0);
	else
		[self show_error:_e(27)];
		// _27: Error opening URL
}

#pragma mark -
#pragma mark Regular expression methods

/** Internal method used by register_tag_regex and register_video_regex.
 * \return Returns an array with two objects which are the passed in parameters
 * (the string and an NSNumber with the unique_id) if the regex is valid. If
 * the regex is not valid, returns nil. The array is guaranteed to have two
 * elements if returned.
 */
+ (NSArray*)register_regex:(NSString*)regex unique_id:(int)unique_id
{
	RASSERT(regex.length, @"Emtpy regex?", return);
	RASSERT(unique_id > 0, @"Invalid unique_id for regex", return);

	DLOG(@"Adding id %d for regular expression '%@'", unique_id, regex);
	// Test the regular expression before adding it to the list.
	NSError *error = nil;
	[@" " rangeOfRegex:regex options:RKLNoOptions
		inRange:NSMakeRange(0, 1) capture:0 error:&error];
	if (error) {
		DLOG(@"Error with regex: %@", error);
		return nil;
	}

	return [NSArray arrayWithObjects:regex,
		[NSNumber numberWithInt:unique_id], nil];
}

/** Registers a regular expression with a specific controller identifier.
 * The regular expression is added to a list of expressions tested for each
 * link. If there is a match, a request to the controller for the identifier is
 * made to open the link instead of following it normally.
 */
+ (void)register_tag_regex:(NSString*)regex unique_id:(int)unique_id
{
	[_gTags append:[FLWeb_view_controller
		register_regex:regex unique_id:unique_id]];
}

/// Just like register_tag_regex but for video links.
+ (void)register_video_regex:(NSString*)regex unique_id:(int)unique_id
{
	[_gVideos append:[FLWeb_view_controller
		register_regex:regex unique_id:unique_id]];
}

/// Just like register_tag_regex but for video links.
+ (void)register_gallery_regex:(NSString*)regex unique_id:(int)unique_id
{
	[_gGallery append:[FLWeb_view_controller
		register_regex:regex unique_id:unique_id]];
}

/** Tests the regular expression tuple against the given text.
 * The tuple should contain as the first element the regular expression as a
 * string, and an NSNumber as a second element with the controller identifier.
 *
 * \return Returns negative if the regular expression did not match the text,
 * or an FLRegex_match object if successful.
 */
+ (FLRegex_match*)test_regex:(NSArray*)tuple text:(NSString*)text
{
	LASSERT([tuple isKindOfClass:[NSArray class]], @"Invalid tuple type");
	LASSERT(2 == tuple.count, @"The tuple doesn't have two elements");
	LASSERT([[tuple objectAtIndex:0] isKindOfClass:[NSString class]],
		@"First tuple element expected to be a string");
	LASSERT([[tuple objectAtIndex:1] isKindOfClass:[NSNumber class]],
		@"First tuple element expected to be a number");

	NSString *regex = [tuple objectAtIndex:0];
	NSRange range = [text rangeOfRegex:regex options:RKLNoOptions
		inRange:NSMakeRange(0, text.length) capture:1 error:nil];
	if (NSNotFound == range.location)
		return nil;

	FLRegex_match *match = [FLRegex_match new];
	match.match = [text substringWithRange:range];
	match.controller_id = [[tuple objectAtIndex:1] intValue];
	match.text = text;
	return [match autorelease];
}

/** Tests the registered regular expressions against the given text.
 * \return Returns negative if none matched, or the identifier associated with
 * the regular expression that matched the text.
 */
+ (FLRegex_match*)test_tag_regexs:(NSString*)text
{
	RASSERT(text.length > 0, @"Empty text to test?", return -1);
	// Test accumulated regular expressions.
	for (NSArray *tuple in _gTags) {
		FLRegex_match *ret = [FLWeb_view_controller test_regex:tuple text:text];
		if (ret)
			return ret;
	}
	return nil;
}

/// Just like test_tag_regexs but for video links.
+ (FLRegex_match*)test_video_regex:(NSString*)text
{
	RASSERT(text.length > 0, @"Empty text to test?", return -1);
	// Test accumulated regular expressions.
	for (NSArray *tuple in _gVideos) {
		FLRegex_match *ret = [FLWeb_view_controller test_regex:tuple text:text];
		if (ret)
			return ret;
	}
	return nil;
}

/// Just like test_tag_regexs but for gallery links.
+ (FLRegex_match*)test_gallery_regex:(NSString*)text
{
	RASSERT(text.length > 0, @"Empty text to test?", return -1);
	// Test accumulated regular expressions.
	for (NSArray *tuple in _gGallery) {
		FLRegex_match *ret = [FLWeb_view_controller test_regex:tuple text:text];
		if (ret)
			return ret;
	}
	return nil;
}

#pragma mark -
#pragma mark UIWebViewDelegate protocol

- (BOOL)webView:(UIWebView *)webView
	shouldStartLoadWithRequest:(NSURLRequest *)request
	navigationType:(UIWebViewNavigationType)navigationType
{
	switch (navigationType) {
		case UIWebViewNavigationTypeLinkClicked:
		case UIWebViewNavigationTypeFormSubmitted:
		case UIWebViewNavigationTypeFormResubmitted:
			DLOG(@"Evaluating %@", request);
			if (NSOrderedSame ==
					[[[request URL] scheme] caseInsensitiveCompare:@"mailto"]) {
				[self show_mail_composer:[[request URL] resourceSpecifier]];
				return NO;
			}

			NSString *url = [[request URL] absoluteString];
			if (!self.push_external) {
				return YES;
			} else {
				FLWeb_view_controller *controller = [FLWeb_view_controller new];
				controller.main_url = url;
				controller.push_external = NO;
				controller.show_interface = YES;
				controller.hidesBottomBarWhenPushed = YES;
				controller.wantsFullScreenLayout = YES;
				[self.navigationController pushViewController:controller
					animated:YES];
				[controller release];
			}
			return NO;
		default:
			return YES;
	}
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[activity_indicator_ startAnimating];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	/** Ignore stop requests to views which are not visible/active. */
	if (webView != web_view_)
		return;

	[self update_toolbar_actions];

	if (self.show_interface)
		self.navigationItem.title = [web_view_
			stringByEvaluatingJavaScriptFromString:@"document.title"];

	[activity_indicator_ stopAnimating];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self hide_shield_screen];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	if (webView != web_view_)
		return;

	[self update_toolbar_actions];

	[activity_indicator_ stopAnimating];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self hide_shield_screen];
	DLOG(@"Ignoring web fail error %@ for %@", error, [webView request]);
	//[self show_error:_e(21) error:error];
	// _21: Connection error
}

#pragma mark -
#pragma mark Rotation handlers

- (void)willAnimateRotationToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
	duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:interfaceOrientation
		duration:duration];
	[self reposition_toolbar];
}

@end
