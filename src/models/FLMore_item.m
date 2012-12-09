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
#import "models/FLMore_item.h"

#import "ELHASO.h"

@implementation FLMore_item

@synthesize is_working = is_working_;

/// Debugging helper, shows info about the object.
- (NSString*)description
{
	return [NSString stringWithFormat:@"FLMore_cell {is_working:%d, title:%@}",
		is_working_, self.title];
}

/// This is a dummy item, it doesn't generate JSON.
- (NSString*)create_json
{
	return nil;
}

/// This is a dummy item, it doesn't generate a dictionary.
- (NSMutableDictionary*)create_json_dict
{
	return nil;
}

@end
