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
#import "net/FLMeta_data_connection.h"

#import <MessageUI/MessageUI.h>

typedef enum Action_button_enum Action_button;

enum Action_button_enum
{
	ACTION_UNKNOWN,
	ACTION_COPY_URL,
	ACTION_MAIL_URL,
	ACTION_TWIT_URL,
	ACTION_FACEBOOK_URL,
	ACTION_CANCEL,
};

@class FLContent_item;

/** Common class for reusable methods.
 *
 * There are many things common in all the view controllers, and
 * some specific ones which may repeat. By subclassing this functionality
 * you get to avoid rewritting your code. See all the available
 * methods here. You may need to access from tyme to time the protected
 * variables.
 */
@interface FLContent_view_controller : UIViewController <UIActionSheetDelegate,
	MFMailComposeViewControllerDelegate>
{
	/// Overlayed activity indicator to show loading progress.
	UIActivityIndicatorView *activity_indicator_;

	/// Object tracking network connection. Allows data caching.
	FLMeta_data_connection *connection_;

	/// Label used to tell user about network outages.
	UILabel *error_label_;

	/// Stores the last action sheet. Required to dismiss it on the ipad.
	UIActionSheet *last_sheet_;

	/// Stores the tab Owners identifier for disk cache.
	int unique_id_;

	/// Time to live of the fetched data in seconds.
	int ttl_;

	/// Behaviour of the news fetching when the tab is first loaded.
	BOOL download_if_virgin_;

	/// Internal witness for remote network activity start.
	BOOL already_doing_network_fetches_;

	/// Maximum number of items to show in the view. Excedent is purged.
	int cache_size_;

	/// Values automatically set when you modify the list of items.
	int max_item_id_, min_item_id_;
}

/// Base URL for the item, used to combine with item_.url if needed.
@property (nonatomic, retain) NSString *base_url;

/// Internal identifier of the database cache, Owner table identifier.
@property (nonatomic, assign) int cache_token;

/// Stores the items of the view.
@property (nonatomic, retain) NSArray *items;

/// Right action button. Null unless you call show_right_button:.
@property (nonatomic, retain, readonly) UIBarButtonItem *right_button;

/// Set to YES if you want the controller to ignore network updates.
@property (nonatomic, assign) BOOL ignore_updates;

/// True absolute URL downloaded. Probably base_url + item.url.
@property (nonatomic, retain) NSString *requested_url;

/// Holds a forced ULR to download stuff from, avoiding the usual URLs.
@property (nonatomic, retain) NSString *forced_url;

/// Set YES if you want push_controller: to NOT replace the root view on ipad.
@property (nonatomic, assign) BOOL same_window_push;


- (void)copy_from:(FLContent_view_controller*)other;
- (void)start_doing_network_fetches;
- (void)download_content:(FLContent_item*)item selector:(SEL)selector
	target:(id)target cache_type:(CACHE_TYPE)cache_type
	cache_tables:(NSString**)cache_tables force:(BOOL)force;

- (void)reposition_activity_indicator;
- (void)show_error:(NSString*)message;
- (BOOL)show_error:(NSString*)message error:(NSError*)error;
- (void)show_right_button:(SEL)action item:(UIBarButtonSystemItem)item;
- (void)show_share_actions:(int)title_id;
- (void)cancel_previous_action_sheet;

- (void)show_mail_composer:(FLContent_item*)item
	subject:(int)subject_id body:(int)body_id;

- (void)show_mail_composer:(NSString*)to_address;
- (CGSize)get_visible_area;
- (CGSize)get_ipad_visible_area;
- (void)show_shield_screen;
- (void)hide_shield_screen;

- (void)sort_and_purge_items:(NSMutableArray*)data
	to_delete:(NSArray*)to_delete;

- (void)save_items_to_cache:(NSArray*)items parent_table:(NSString*)parent_table
	data_tables:(NSString**)data_tables owner_id:(int)owner_id
	max_elements:(int)max_elements;

- (void)push_controller:(UIViewController*)controller animated:(BOOL)animated;

- (NSString*)prettify_request_url:(NSString*)url;
+ (NSString*)prettify_request_url:(NSString*)url;
- (NSString*)prettify_request_url:(NSString*)url add_older:(BOOL)add_older;

@end
