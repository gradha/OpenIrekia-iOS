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
#import "structures/FLPagination_info.h"

#import "net/FLRemote_connection.h"


@implementation FLPagination_info

@synthesize next_page = next_page_;
@synthesize url = url_;
@synthesize user_input = user_input_;

#pragma mark -
#pragma mark Methods

- (void)dealloc
{
	[url_ release];
	[user_input_ release];
	[super dealloc];
}

/// Debugging helper, returns a textual description of the object.
- (NSString*)description
{
	return [NSString stringWithFormat:@"FLPagination_info {next_page:%d, "
		@"url:%@, user_input:%@}", next_page_, url_, user_input_];
}

/** Returns the url with the parameters replaced by the user input.
 * If something goes wrong, the method returns nil, which you can use as a text
 * to verify that the structure is valid.
 */
- (NSString*)replace_params
{
	return [FLRemote_connection replace_search_params:self.url
		words:self.user_input page:self.next_page];
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
