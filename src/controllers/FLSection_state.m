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
#import "controllers/FLSection_state.h"

#import "models/FLContent_item.h"

@implementation FLSection_state

@synthesize items = items_;
@synthesize collapsed = collapsed_;

/** Creates a FLSection_state element from NSDictionary of the JSON string.
 *
 * Returns nil if there was a problem generating the object. This
 * could happen if you specify a section with zero or negative
 * identifier.
 */
- (id)initWithAPIDictionary:(NSDictionary *)dict
{
	if (self = [super initWithAPIDictionary:dict]) {
		self.collapsed = self.starts_collapsed;
		self.items = [NSMutableArray arrayWithCapacity:20];
	}

	return self;
}

- (void)dealloc
{
	[items_ release];
	[super dealloc];
}

@end
