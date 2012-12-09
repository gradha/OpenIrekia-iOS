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
#import <Foundation/Foundation.h>

/** Stores cell attributes according to the news network protocol.
 */
@interface FLNews_cell_data : NSObject
{
@public
	int padding, section_title_padding;
	int title_lines;
	int title_size, text_size, footer_size;
	int footer_alignment;
	BOOL image_right, navigation_changes_section;
	CGSize image_size;
};

@property (nonatomic, retain) UIColor *title_color;
@property (nonatomic, retain) UIColor *text_color;
@property (nonatomic, retain) UIColor *footer_color;
@property (nonatomic, retain) UIColor *back_normal_color;
@property (nonatomic, retain) UIColor *back_highlight_color;
@property (nonatomic, retain) UIColor *section_expanded_text_color;
@property (nonatomic, retain) UIColor *section_expanded_back_color;
@property (nonatomic, retain) UIColor *section_collapsed_text_color;
@property (nonatomic, retain) UIColor *section_collapsed_back_color;
@property (nonatomic, retain) UIImage *disclosure_image;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
