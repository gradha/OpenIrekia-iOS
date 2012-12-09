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
#import "structures/FLRegex_match.h"

@implementation FLRegex_match

@synthesize controller_id = controller_id_;
@synthesize match = match_;
@synthesize text = text_;

- (void)dealloc
{
	[text_ release];
	[match_ release];
	[super dealloc];
}

/// Debugging helper, returns a textual description of the object.
- (NSString*)description
{
	return [NSString stringWithFormat:@"FLRegex_match {controller_id:%d, "
		@"match:%@, text:%@}",
		controller_id_, match_, text_];
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
