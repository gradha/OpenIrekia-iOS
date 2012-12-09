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

@class FLGallery_cell_data;
@class FLMore_item;
@class FLRemote_connection;
@class FLRegex_match;
@class FlokiAppDelegate;

/** Handles the photo gallery view.
 *
 * The gallery view is implemented not with a scroll view, but with
 * a table view. This is slightly annoying, as it will cause problems
 * in the future with landscape rotation, but for the moment it works.
 * The view puts FLGallery_cell items in the table, which actually
 * handle multiple thumbs.
 */
@interface FLGallery_view_controller :
	FLCommon_view_controller <FLTab_protocol, FLContainer_protocol>
{
	/// Remembers what was the last item selected by the user.
	int last_item_selected_;
}

/// Common cell attributes.
@property (nonatomic, retain) FLGallery_cell_data *cell_data;

/// Additional cell for chronological navigation.
@property (nonatomic, retain) FLMore_item *more_item;

/// Specifies the gallery query URL if any (and valid).
@property (nonatomic, retain) NSString *gallery_url;


- (UIViewController*)spawn_gallery:(FLRegex_match*)match;

@end
