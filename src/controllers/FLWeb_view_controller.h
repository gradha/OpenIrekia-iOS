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
#import "protocols/FLTab_protocol.h"
#import "controllers/FLContent_view_controller.h"

#define MAPS_PREFIX		@"http://maps.google.com/maps"

@class FLRegex_match;


/** Handles a web view for online content.
 *
 * The web view will load a page and show its contents. If the
 * contents contain an external link, the view will push another view
 * controller with the external URL showing a basic navigation toolbar
 * at the bottom.
 */
@interface FLWeb_view_controller : FLContent_view_controller
	<FLTab_protocol, UIWebViewDelegate>
{
	/// Internal pointer to the web view.
	UIWebView *web_view_;

	/// Set by the application protocol, forces page scale fitting.
	BOOL scales_page_to_fit_;

	/// Optional navigation toolbar.
	UIToolbar *toolbar_;

	/// Pointers to the arrow buttons, we need to enable/disable them.
	UIBarButtonItem *left_, *right_;
}

/// Set this to the URL you want to load in the view.
@property (nonatomic, retain) NSString *main_url;

/// Set this to YES if you want external links to push a new view.
@property (nonatomic, assign) BOOL push_external;

/// Set this to YES if you want to show a basic navigation interface.
@property (nonatomic, assign) BOOL show_interface;

- (int)unique_id;
+ (void)register_tag_regex:(NSString*)regex unique_id:(int)unique_id;
+ (void)register_video_regex:(NSString*)regex unique_id:(int)unique_id;
+ (void)register_gallery_regex:(NSString*)regex unique_id:(int)unique_id;
+ (FLRegex_match*)test_tag_regexs:(NSString*)text;
+ (FLRegex_match*)test_video_regex:(NSString*)text;
+ (FLRegex_match*)test_gallery_regex:(NSString*)text;

@end
