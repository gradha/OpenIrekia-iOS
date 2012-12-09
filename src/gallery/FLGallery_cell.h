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
@class FLGallery_cell_data;
@class FLGallery_item;
@class FLMeta_data_connection;

/** Handles the custom content of a gallery cell.
 *
 * Gallery cells are actually like multiple cells in one, all drawn
 * at the same time. Based on code of FLNews_cell.
 */
@interface FLGallery_cell : UITableViewCell
{
	/// Internal view to handle custom drawing.
	UIView *content_view_;

	/// Holds the constructed images for the row.
	NSMutableArray *images_;

	/// Connection to download thumbnail. Cached to disk.
	NSMutableArray *connections_;

	/// Array of UIAccessibilityElement objects wrapping the items.
	NSArray *accessible_items_;

	/// Holds the index of the selected image, or negative.
	int selected_;

	/// Stores the pixel of the first touch on the cell.
	CGPoint first_touch_;
}

/// Array of FLGallery_item objects.
@property (nonatomic, retain) NSArray *items;

/// Internal identifier of the database cache, Owner table identifier.
@property (nonatomic, assign) int cache_owner;

/// Pointer to common FLGallery_cell_data info.
@property (nonatomic, retain) FLGallery_cell_data *data;

- (id)initWithIdentifier:(NSString *)identifier;

- (id)initWithStyle:(UITableViewCellStyle)style
	reuseIdentifier:(NSString *)reuseIdentifier;

- (void)drawContentView:(CGRect)cell_rect;
- (FLGallery_item*)selected_item;

@end

float gallery_width(void);
