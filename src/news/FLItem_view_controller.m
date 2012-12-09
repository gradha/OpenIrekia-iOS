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
#import "news/FLItem_view_controller.h"

#import "controllers/FLWeb_view_controller.h"
#import "global/FLInt_check.h"
#import "global/FLi18n.h"
#import "global/FlokiAppDelegate.h"
#import "models/FLNews_item.h"
#import "protocols/FLContainer_protocol.h"
#import "structures/FLRegex_match.h"

#import "ELHASO.h"
#import "NSArray+ELHASO.h"
#import "ShareKit/Core/SHK.h"
#import "ShareKit/Sharers/Services/Facebook/SHKFacebook.h"
#import "ShareKit/Sharers/Services/Twitter/SHKTwitter.h"

#define _CURL_DELAY			1


@interface FLItem_view_controller ()
- (void)share_button;
- (void)update_navigation_arrows;
@end


@implementation FLItem_view_controller

@synthesize container = container_;
@synthesize item = item_;

#pragma mark -
#pragma mark Methods

/** Handles creation of the view, pseudo constructor.
 */
- (void)loadView
{
	[super loadView];

	/* Create the web view. */
	web_view_ = [[UIWebView alloc] initWithFrame:self.view.frame];
	web_view_.scalesPageToFit = YES;
	[(id)web_view_ setDetectsPhoneNumbers:NO];
	web_view_.delegate = self;
	web_view_.frame = self.view.bounds;
	web_view_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	[self.view insertSubview:web_view_ atIndex:0];

	/* Repeat for the secondary web view, when we flip stuff. */
	second_web_view_ = [[UIWebView alloc] initWithFrame:self.view.frame];
	second_web_view_.scalesPageToFit = YES;
	[(id)second_web_view_ setDetectsPhoneNumbers:NO];
	second_web_view_.delegate = self;
	second_web_view_.frame = self.view.bounds;
	second_web_view_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	second_web_view_.hidden = YES;
	[self.view insertSubview:second_web_view_ atIndex:1];

	self.hidesBottomBarWhenPushed = YES;

	/* Segmented control with arrows to go prev/next chapter. */
	navigation_arrows_ = [[UISegmentedControl alloc] initWithItems:
		[NSArray arrayWithObjects:[UIImage imageNamed:@"arrow_up.png"],
			[UIImage imageNamed:@"arrow_down.png"], nil]];

	[navigation_arrows_ addTarget:self action:@selector(arrow_action:)
		forControlEvents:UIControlEventValueChanged];
	navigation_arrows_.frame = CGRectMake(0, 0, 90, 30);
	navigation_arrows_.segmentedControlStyle = UISegmentedControlStyleBar;
	navigation_arrows_.momentary = YES;

	[self show_right_button:@selector(share_button)
		item:UIBarButtonSystemItemAction];
}

- (void)dealloc
{
	if ([container_ respondsToSelector:@selector(disconnect_child:)])
		[container_ performSelector:@selector(disconnect_child:)
			withObject:self];
	container_ = nil;
	[last_url_data_ release];
	last_url_data_ = nil;
	second_web_view_.delegate = web_view_.delegate = nil;
	[navigation_arrows_ release];
	navigation_arrows_ = nil;
	[external_ release];
	[second_web_view_ release];
	[web_view_ release];
	[item_ release];
	[super dealloc];
}

/** Handles button presses on the navigation toolbar.
 * If there is no container handler, this does nothing. If there
 * is, the container is requested to switch the item after starting
 * the activity indicator.
 */
- (void)arrow_action:(id)sender
{
	if (!self.container)
		return;

	const int button = navigation_arrows_.selectedSegmentIndex;
	[activity_indicator_ startAnimating];
	/* Disable interface until the parent sets the new item. */
	[navigation_arrows_ setEnabled:NO forSegmentAtIndex:0];
	[navigation_arrows_ setEnabled:NO forSegmentAtIndex:1];
	self.right_button.enabled = NO;

	[self.container switch_item:(button > 0) ? 1 : -1];
}

- (void)setItem:(FLNews_item*)item
{
	LASSERT(self.base_url, @"Base url not initialised");
	LASSERT(self.cache_token, @"db_cache not initialised");

	[self update_navigation_arrows];

	if (self.item == item)
		return;

	/* Due to how row elements are updated, we will be passed
	 * a different pointer to the same content, so check in addition
	 * some of the most relevant attributes to see if we force a refresh.
	 */
	if (self.item.id_ == item.id_ && self.item.sort_id == item.sort_id &&
			(!self.item.url || [self.item.url isEqualToString:item.url]) &&
			(!self.item.share_url ||
				[self.item.share_url isEqualToString:item.share_url]))
		return;

	[connection_ cancel];
	[web_view_ stopLoading];

	/* See if we are switching from a previous item to a new one. Animate! */
	if (self.item && item) {
		DLOG(@"Switching item to another one %lld -> %lld!",
			self.item.sort_id, item.sort_id);

		/* Begin a nice curl up/down animation based on identifier numbers. */
		BLOCK_UI();
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:_CURL_DELAY];

		[UIView setAnimationTransition:(
			(self.item.sort_id > item.sort_id) ? UIViewAnimationTransitionCurlUp :
				UIViewAnimationTransitionCurlDown) forView:self.view
			cache:YES];

		[web_view_ removeFromSuperview];
		second_web_view_.hidden = NO;
		[UIView commitAnimations];
		web_view_.hidden = YES;
		[self.view insertSubview:web_view_ atIndex:1];

		/* Now clean up the pointers and the former web view content. */
		UIWebView *temp = second_web_view_;
		[web_view_ loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
		second_web_view_ = web_view_;
		web_view_ = temp;
		[activity_indicator_ startAnimating];

		/* Trick the user by disabling the navigation buttons for a while. */
		[navigation_arrows_ setEnabled:NO forSegmentAtIndex:0];
		[navigation_arrows_ setEnabled:NO forSegmentAtIndex:1];
		[self performSelector:@selector(update_navigation_arrows) withObject:nil
			afterDelay:_CURL_DELAY];
	}

	[item retain];
	[item_ release];
	item_ = item;

	[self download_content:item selector:@selector(did_receive_url:error:)
		target:self cache_type:CACHE_CONTENT cache_tables:NEWS_CACHE_TABLES
		force:NO];

	self.right_button.enabled = (nil != self.item.share_url);
}

/** Weak container setter.
 * Also tries to show/hide the navigation buttons depending on the value of
 * the container. Pass nil to hide the buttons.
 */
- (void)setContainer:(id<FLContainer_protocol>)container
{
	container_ = nil;
	if (!container) {
		self.navigationItem.titleView = nil;
	} else {
		LASSERT([container respondsToSelector:@selector(switch_item:)],
			@"Unexpected, container should conform to protocol");
		container_ = container;

		self.navigationItem.titleView = navigation_arrows_;
		/* Force the setItem to reactivate/disable the arrows. */
		[self setItem:self.item];
	}
}

/** Updates the state of the navigation arrows according to the protocol.
 */
- (void)update_navigation_arrows
{
	[navigation_arrows_
		setEnabled:([self.container has_previous])
		forSegmentAtIndex:0];
	[navigation_arrows_
		setEnabled:([self.container has_next])
		forSegmentAtIndex:1];

	// Force accessibility attributes.
	for (int f = 0; f < 2; f++) {
		UIView *v = [navigation_arrows_.subviews get:f];
		if (![v respondsToSelector:@selector(accessibilityLabel)])
			continue;

		if (NSNotFound != [v.accessibilityLabel
				rangeOfString:@"down"].location) {
			SET_ACCESSIBILITY_LABEL(v, _e(19));
			// _19: Next
		} else if (NSNotFound != [v.accessibilityLabel
				rangeOfString:@"up"].location) {
			SET_ACCESSIBILITY_LABEL(v, _e(18));
			// _18: Previous
		}
	}
}

#pragma mark Network connection handler

- (void)did_receive_url:(FLMeta_data_connection*)response error:(NSError*)error
{
	if ([self show_error:_e(21) error:error])
		return;
	// _21: Connection error

	NSData *data = [response data];
	NSString *url_data_ = [[NSString alloc] initWithBytes:[data bytes]
		length:[data length] encoding:NSUTF8StringEncoding];
	if (!url_data_) {
		[self show_error:_e(22)];
		// _22: Error processing data
		return;
	}

	/* Load the string only if it is different from the last
	 * one. This check is performed because we are sometimes forcing
	 * a network reload even if we got the file from disk cache.
	 */
	if (!(last_url_data_ && url_data_ &&
			[last_url_data_ isEqualToString:url_data_])) {
		DLOG(@"Updating HTML view with fresh data.");
		[web_view_ loadHTMLString:url_data_
			baseURL:[NSURL URLWithString:self.requested_url]];
	}
	[last_url_data_ release];
	last_url_data_ = url_data_;

	/* If this comes from disk and wasn't checked before,
	 * redownload it again to force a just-in-case refresh. See
	 * #917.
	 */
	FLInt_check *checks = [FLInt_check cache:self.cache_token];
	if (response.from_disk && ![checks get:self.item.id_]) {
		DLOG(@"Requesting fresh version for cache, just in case.");
		[self download_content:self.item
			selector:@selector(did_receive_url:error:)
			target:self cache_type:CACHE_CONTENT
			cache_tables:NEWS_CACHE_TABLES force:YES];
	}
	[checks set:self.item.id_];
}

#pragma mark UIAlertViewDelegate protocol

- (void)alertView:(UIAlertView *)alertView
	clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex > 0)
		[[UIApplication sharedApplication] openURL:external_];
}

#pragma mark UIWebViewDelegate protocol

- (BOOL)webView:(UIWebView *)webView
	shouldStartLoadWithRequest:(NSURLRequest *)request
	navigationType:(UIWebViewNavigationType)navigationType
{
	switch (navigationType) {
		case UIWebViewNavigationTypeLinkClicked:
		case UIWebViewNavigationTypeFormSubmitted:
		case UIWebViewNavigationTypeFormResubmitted:
			DLOG(@"Item requesting URL %@", request);
			NSString *url = [[request URL] absoluteString];
			SEL action = 0;
			FLRegex_match *match = nil;
			UIViewController *controller = nil;

			if ((match = [FLWeb_view_controller test_tag_regexs:url])) {
				DLOG(@"Found tag %@", match);
				action = @selector(spawn_tag_controller:);
			} else if ((match = [FLWeb_view_controller test_video_regex:url])) {
				DLOG(@"Found video %@", match);
				action = @selector(spawn_video_controller:);
			} else if ((match =
					[FLWeb_view_controller test_gallery_regex:url])) {
				DLOG(@"Found gallery %@", match);
				action = @selector(spawn_gallery_controller:);
			}

			if (match && action) {
				controller = [FlokiAppDelegate performSelector:action
					withObject:match];
				controller.hidesBottomBarWhenPushed = YES;
				// Avoid ipad push, always push inside this view controller.
				if (controller)
					[self.navigationController
						pushViewController:controller animated:YES];
				return NO;
			}

			if (NSOrderedSame ==
					[[[request URL] scheme] caseInsensitiveCompare:@"mailto"]) {
				[self show_mail_composer:[[request URL] resourceSpecifier]];
				return NO;
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
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	/* Ignore stop requests to views which are not visible/active. */
	if (webView == web_view_) {
		[activity_indicator_ stopAnimating];
	}
}

#pragma mark UIActionsheet

- (void)share_button
{
	LASSERT(self.item.share_url, @"Item doesn't have URL to share?");
	if (!self.item.share_url)
		return;

	[self show_share_actions:STR_NEWS_SHARING_TITLE];
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
			[self show_mail_composer:self.item subject:STR_MAIL_NEWS_SUBJECT
				body:STR_MAIL_NEWS_BODY];
			break;
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
}

@end
