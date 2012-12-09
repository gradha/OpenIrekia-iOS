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
#import "controllers/FLCentered_scroll_view.h"

@class FLGallery_item;

/** Shows a picture to the user in a scrollable area with zoom.
 *
 * This only handles a single FLGallery_item. The FLStrip_view_controller
 * shows a collection of these and you can flick from one to another.
 */
@interface FLPhoto_view_controller :
	FLContent_view_controller <UIScrollViewDelegate, FLTap_delegate>
{
	/// Holds the scrollable content.
	FLCentered_scroll_view *scroll_view_;

	/// Points to the zoomable content. Required for delegate.
	UIImageView *image_view_;

	/// Optional toggling handler.
	id tap_handler_;
	SEL tap_selector_;

	/// Stored when you call resize_frame.
	CGRect pos_rect_;
}

/// Pointer to FLGallery_item with the data for the view.
@property (nonatomic, retain) FLGallery_item *item;

- (void)set_tap_handler:(id)object selector:(SEL)selector;
- (void)resize_frame:(CGRect)rect;

@end
