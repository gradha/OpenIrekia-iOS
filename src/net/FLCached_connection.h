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
#import "net/FLRemote_connection.h"

/** Improvement over the FLRemote_connection class.
 *
 * For the FLCached_connection, the contents of URLs are stored in
 * memory and reused from there.
 */
@interface FLCached_connection : FLRemote_connection
{
	/// Tab owner database identifier, for disk cache.
	int cache_token_;
}

/// Stores the requested URL. Used by the cache code.
@property (nonatomic, retain) NSString *url;

/// Set this to YES if you want the raw FLRemote_connection behaviour.
@property (nonatomic, assign) BOOL dont_cache;

+ (void)didReceiveMemoryWarning;
- (void)request:(NSString*)url cache_token:(int)cache_token;
- (id)get_memory_cache:(NSString*)url token:(int)token;
- (void)set_memory_cache:(NSString*)url token:(int)token data:(id)data;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
