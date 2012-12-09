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
#import "gallery/FLPhoto_view_controller.h"

@protocol FLContainer_protocol;

/** Controls a group of pictures in a slideshow fashion.
 *
 * The class will create a huge scrolling area required to fit all
 * the images together in a long strip from left to right. Then it
 * will control all touch actions to detect switching from one or
 * another.
 *
 * A translucent HUD with information and actions is also shown,
 * but hidden during user interaction to allow full screen picture
 * viewing.
 *
 * Delegates the individual picture viewing to the FLPhoto_view_controller.
 */
@interface FLStrip_view_controller :
	FLContent_view_controller <UIScrollViewDelegate, FLTap_delegate>
{
	UIScrollView *scroll_;
	FLPhoto_view_controller **images_;
	UIToolbar *toolbar_;

	/// Used by some methods to know the page we are in.
	/// Not very clean, but has to be known during screen orientations too.
	int page_;
	CGSize size_;

	/// Pointers to the arrow buttons, we need to enable/disable them.
	UIBarButtonItem *left_, *right_;

	/// Keeps track of hud toggling.
	BOOL is_hud_on_;
	/// Set this to YES for scrollViewDidScroll to not do anything.
	BOOL ignore_scrolls_;

	/// Caption overlay variables.
	UIView *caption_view_;
	UILabel *caption_label1_, *caption_label2_;
}

// First set the group, then set the item to specify an index into the group.
@property (nonatomic, retain) NSArray *group;

// Sets the page to the specified item, or gets the item for the selected page.
@property (nonatomic, retain) FLGallery_item *item;

/// Parent, in charge of changing the content. Not. See
/// FLGallery_view_controller::switch_item() for details.
@property (nonatomic, assign) id<FLContainer_protocol> container;

@end
