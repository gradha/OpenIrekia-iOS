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
@class FLCached_connection;
@class FLMeta_data_connection;
@class FLMovie_cell_data;

/** Handles the custom content of a movie button cell.
 *
 * The movie button cell is actually the thumbnail or bigger thumbnail
 * drawn on the cell with the overlay of a play button.
 */
@interface FLMovie_button_cell : UITableViewCell
{
	/// Internal view to handle custom drawing.
	UIView *content_view_;

	/// Holds the preview image.
	UIImage *image_;
	/// Connection to download thumbnail. Cached to disk.
	FLCached_connection *thumb_connection_;

	/// Layer for playback button.
	UIImageView *play_view_;
	/// Shows the spinning wheel during network load times.
	UIActivityIndicatorView *activity_indicator_;

	// To know if we have to readjust the layers according to the graphics.
	BOOL virgin_;
}

/// Pointer to common FLMovie_cell_data info.
@property (nonatomic, retain) FLMovie_cell_data *data;


- (id)initWithIdentifier:(NSString *)identifier;

- (id)initWithStyle:(UITableViewCellStyle)style
	reuseIdentifier:(NSString *)reuseIdentifier;

- (void)drawContentView:(CGRect)cell_rect;

+ (CGFloat)height_for_text:(FLMovie_cell_data*)data;

- (void)start;
- (void)stop;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
