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
#import "controllers/FLCommon_view_controller.h"
#import "protocols/FLContainer_protocol.h"
#import "protocols/FLTab_protocol.h"

@class FLNews_cell_data;
@class FLNews_item;
@class FLPagination_info;
@class FLRemote_connection;
@class FLRegex_match;
@class FlokiAppDelegate;


/** Handles the news view.
 *
 * The view will load some FLNews_item objects and then will display them
 * in a table fashion using FLNews_cell.
 */
@interface FLNews_view_controller :
	FLCommon_view_controller <FLTab_protocol, FLContainer_protocol,
	UISearchBarDelegate>
{
	/// Tells that the view is virgin, it is empty and has nothing.
	BOOL virgin_;

	/// Holds the search widget, to access the search input.
	UISearchBar *search_bar_;

	/// Holds to the temporary search shield view, which is a button.
	UIView *search_shield_;
}

/// Common cell attributes.
@property (nonatomic, retain) FLNews_cell_data *cell_data;

/// Remembers what was the last path selected by the user.
@property (nonatomic, retain) NSIndexPath *last_path_selected;

/// Specifies the search parameter URL if any (and valid)
@property (nonatomic, retain) NSString *search_bar_url;

/// If available, holds the state for forced pagination requests.
@property (nonatomic, retain) FLPagination_info *pagination;

/// Specifies the tag query URL if any (and valid)
@property (nonatomic, retain) NSString *tag_url;

/// Specifies the video query URL if any (and valid)
@property (nonatomic, retain) NSString *videos_url;


- (int)unique_id;
- (FLNews_item*)last_item;
- (void)set_last_item:(id)controller path:(NSIndexPath*)path;
- (FLNews_view_controller*)spawn_search:(NSString*)words;
- (UIViewController*)spawn_tag:(FLRegex_match*)match;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
