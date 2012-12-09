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
@class FLMeta_data_connection;
@class FLNews_cell_data;
@class FLNews_item;

/** Handles the custom content of a news cell.
 *
 * News cells usually have a title, a text, a thumbnail image and a footer.
 *
 * Uses custom drawing to show the image and text. Based on code
 * found at
 * http://blog.atebits.com/2008/12/fast-scrolling-in-tweetie-with-uitableview/.
 */
@interface FLNews_cell : UITableViewCell
{
	/// Internal view to handle custom drawing.
	UIView *content_view_;
	/// Holds the constructed image for the thumbnail.
	UIImage *image_;
	/// Connection to download thumbnail. Cached to disk.
	FLMeta_data_connection *thumb_connection_;
}

/// Pointer to FLNews_item with the data for the cell.
@property (nonatomic, retain) FLNews_item *item;

/// Internal identifier of the database cache, Owner table identifier.
@property (nonatomic, assign) int cache_owner;

/// Pointer to common FLNews_cell_data info.
@property (nonatomic, retain) FLNews_cell_data *data;

- (id)initWithIdentifier:(NSString *)identifier;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)drawContentView:(CGRect)cell_rect;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
