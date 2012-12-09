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
#import "net/FLCached_connection.h"

extern NSString *Meta_data_error_domain;

/** Type of table cache we want to deal with. */
enum CACHE_TYPE_ENUM
{
	CACHE_THUMB = 0,
	CACHE_CONTENT,
};
typedef enum CACHE_TYPE_ENUM CACHE_TYPE;

/** Improvement over FLCached_connection to store data to disk.
 *
 * Instead of using the URL as index, this stringifies
 * the identifier of the cell and uses that instead. This prevents
 * reusing the same URL for different objects, but makes sure that
 * the images are saved correctly for each news item independently.
 *
 * Also accepts a parameter to use different cache tables depending
 * on resource.
 */
@interface FLMeta_data_connection : FLCached_connection
{
	/// Stores the news item identifier related to the data.
	int news_id_;
	NSString *news_str_;
	/// Stores the type of the cache for runtime behaviour changes.
	CACHE_TYPE type_;
	/// Pointer to the cache tables for the specified content types.
	NSString **tables_;
	/// This is set by the request method.
	BOOL force_;
}

/// Internally used key to access the memory cache.
@property (nonatomic, retain) NSString *news_str;

/// The size you want to UIImage to be rescaled to. Optional.
@property (nonatomic, assign) CGSize target_size;

/// Mark this to YES if you want UIImage scaling to be proportional.
@property (nonatomic, assign) BOOL proportional_scaling;

/// This is set to YES if the data was just loaded from disk.
@property (nonatomic, assign) BOOL from_disk;

- (void)request:(NSString*)url news_id:(int)news_id
	cache_token:(int)cache_token cache_type:(CACHE_TYPE)cache_type
	cache_tables:(NSString**)tables force:(BOOL)force;

+ (UIImage*)data_to_image:(id)data size:(CGSize)size
	proportional:(BOOL)proportional_scaling;

+ (UIImage*)scale_image:(UIImage*)image size:(CGSize)size
	proportional:(BOOL)proportional_scaling;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
