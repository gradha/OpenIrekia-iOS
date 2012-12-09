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
/** Remote connection handler.
 *
 * Abstracts the URL fetching tedious housekeeping work. The action
 * function will receive a Remote_response object which has to be released.
 * You will likely be more interested in FLCached_connection or
 * FLMeta_data_connection, which implement caching schemes for the
 * received data.
 *
 * Note that before releasing you should always call the cancel
 * method, just in case there is a pending network connection going
 * on.
 *
 * You are encouraged to reuse the live object by cancelling the
 * current connection and starting a new one with the
 * FLRemote_connection::request method. That's more optimal than
 * recreating the objects again.
 */
@interface FLRemote_connection : NSObject
{
	/// Downloaded bytes are stored here.
	NSMutableData *data_;

	/// Target object that will be called.
	id target_;
	/// When download is complete, receives a response and NSError object.
	SEL action_;
	/// Keeps the amount if bytes we expect to receive.
	int expected_bytes_;
	/// Marks the connection as gzip enabled, to avoid length checks.
	BOOL is_gzip_;
}

/// Stores the internal state of the net connection doing something.
@property (nonatomic, assign) BOOL working;

/// Objection keeping track of the download.
@property (nonatomic, readonly, retain) NSURLConnection *connection;

/// Target of the connection object. Weak reference, might be nil.
@property (nonatomic, retain, readonly) id target;

- (id)init_with_action:(SEL)action target:(id)target;
- (void)request:(NSString*)url;
- (void)cancel;
- (id)data;

+ (NSString*)replace_search_params:(NSString*)url
	words:(NSString*)words page:(int)page;

@end // FLRemote_connection

// vim:tabstop=4 shiftwidth=4 syntax=objc
