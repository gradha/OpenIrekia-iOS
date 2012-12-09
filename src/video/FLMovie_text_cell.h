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
@class FLMovie_cell_data;

/** Handles the custom content of a movie text cell.
 *
 * The movie text cell shows a title and subtitle with a possibly
 * very big text area spanning one or two screens. The cell doesn't
 * answer to user interaction in any way.
 */

@interface FLMovie_text_cell : UITableViewCell
{
	/// Internal view to handle custom drawing.
	UIView *content_view_;

	int cache_owner_;
}

/// Internal identifier of the database cache, Owner table identifier.
@property (nonatomic, assign) int cache_owner;

/// Pointer to common FLMovie_cell_data info.
@property (nonatomic, retain) FLMovie_cell_data *data;


- (id)initWithIdentifier:(NSString *)identifier;

- (id)initWithStyle:(UITableViewCellStyle)style
	reuseIdentifier:(NSString *)reuseIdentifier;

- (void)drawContentView:(CGRect)cell_rect;
+ (CGFloat)height_for_text:(FLMovie_cell_data*)data width:(CGFloat)width;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
