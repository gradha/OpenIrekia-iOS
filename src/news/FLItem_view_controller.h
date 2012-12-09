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

@class FLNews_item;
@protocol FLContainer_protocol;

/** Shows a news item to the user with a web view.
 *
 * The item view controller also contains a second web view to hot
 * swap news following the FLContainer_protocol of the parent (see
 * FLItem_view_controller::container).
 */
@interface FLItem_view_controller : FLContent_view_controller
	<UIWebViewDelegate, UIAlertViewDelegate>
{
	/// Web view used to show the content.
	UIWebView *web_view_, *second_web_view_;
	/// Stored external link touched previously by the user.
	NSURL *external_;

	/// Shows the navigation arrows to switch prev/next article.
	UISegmentedControl *navigation_arrows_;

	/// Last data loaded into the web view. To avoid spurious refreshes.
	NSString *last_url_data_;
}

/// Set this to the news item you want to view now.
@property (nonatomic, retain) FLNews_item *item;

/// Set to a parent following the FLContainer_protocol.
@property (nonatomic, assign) id<FLContainer_protocol> container;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
