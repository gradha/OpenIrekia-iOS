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
#import "categories/NSString+Floki.h"

@implementation NSString (Floki)

/** Based on code found at:
 * http://stackoverflow.com/questions/1682919/removing-url-fragment-from-nsurl.
 */
- (NSString *)stringByRemovingFragment
{
	// Find that last component in the string from the end to
	// make sure to get the last one
	NSRange fragmentRange = [self rangeOfString:@"/" options:NSBackwardsSearch];
	if (fragmentRange.location != NSNotFound) {
	    // Chop the fragment.
	    return [self substringToIndex:fragmentRange.location];
	} else {
	    return self;
	}
}

/** Checks if the URL contained in the string is absolute.
 * Yet another perverted hack of the NSString class!
 */
- (BOOL)isRelativeURL
{
	NSURL *check_url = [NSURL URLWithString:self];
	return ([[check_url host] length] < 1);
}

@end
