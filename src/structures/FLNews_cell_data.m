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
#import "structures/FLNews_cell_data.h"

@implementation FLNews_cell_data

@synthesize back_highlight_color = back_highlight_color_;
@synthesize back_normal_color = back_normal_color_;
@synthesize disclosure_image = disclosure_image_;
@synthesize footer_color = footer_color_;
@synthesize section_collapsed_back_color = section_collapsed_back_color_;
@synthesize section_collapsed_text_color = section_collapsed_text_color_;
@synthesize section_expanded_back_color = section_expanded_back_color_;
@synthesize section_expanded_text_color = section_expanded_text_color_;
@synthesize text_color = text_color_;
@synthesize title_color = title_color_;

- (void)dealloc
{
	[title_color_ release];
	[text_color_ release];
	[footer_color_ release];
	[back_normal_color_ release];
	[back_highlight_color_ release];
	[section_expanded_text_color_ release];
	[section_expanded_back_color_ release];
	[section_collapsed_text_color_ release];
	[section_collapsed_back_color_ release];
	[disclosure_image_ release];
	[super dealloc];
}

@end
