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

#import "global/FlokiAppDelegate.h"

#import "ELHASO.h"

static NSMutableDictionary *_memory_cache;

@implementation FLCached_connection

@synthesize url = url_;
@synthesize dont_cache = dont_cache_;

- (void)dealloc
{
	[url_ release];
	[super dealloc];
}

+ (void)didReceiveMemoryWarning
{
	DLOG(@"Releasing memory cache due to memory warning.");
	[_memory_cache release];
	_memory_cache = nil;
}

/** Request an URL.
 * However, unlike FLRemote_connection, this will first check the memory cache,
 * for which you are required to pass a cache_token, which is really
 * just the internal identifier associated with the tab this request
 * is happening from.
 *
 * Note that setting dont_cache to YES before calling this will
 * ignore all caches, memory and disk.
 */
- (void)request:(NSString*)url cache_token:(int)cache_token;
{
	self.url = url;
	cache_token_ = cache_token;

	if (self.dont_cache) {
		[super request:url];
		return;
	}

	id data = [self get_memory_cache:url token:cache_token_];
	if (!data) {
		[super request:url];
	} else {
		[self.target performSelector:action_ withObject:self withObject:nil];
	}
}

/** Returns the data from the cache if possible. */
- (id)data
{
	if (self.dont_cache)
		return data_;

	id data = [self get_memory_cache:self.url token:cache_token_];
	if (data)
		return data;
	else
		return [super data];
}

/** Everthing went OK, store a copy of the data in the memory cache. */
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection
{
	if (!self.dont_cache)
		[self set_memory_cache:self.url token:cache_token_ data:data_];
	LASSERT([super respondsToSelector:@selector(connectionDidFinishLoading:)],
		@"Broken API, need to look for something else");
	if ([super respondsToSelector:@selector(connectionDidFinishLoading:)])
		[super connectionDidFinishLoading:theConnection];
}

/** Returns the object for the url and token.
 * This call will automatically generate the required internal
 * _memory_cache structures.
 *
 * If no object is found, nil is returned.
 */
- (id)get_memory_cache:(NSString*)url token:(int)token
{
	if (!_memory_cache)
		_memory_cache = [[NSMutableDictionary dictionary] retain];
	LASSERT(_memory_cache, @"Uh oh");

	if (token < 1) {
		DLOG(@"Can't fetch a token lesser than 1 for %@", url);
		return nil;
	}

	NSNumber *token_num = [NSNumber numberWithInt:token];
	NSMutableDictionary *dict = [_memory_cache objectForKey:token_num];
	if (!dict) {
		[_memory_cache setObject:[NSMutableDictionary dictionary]
			forKey:token_num];
		return nil;
	} else {
		if (self.dont_cache)
			return nil;
		else
			return [dict objectForKey:url];
	}
}

/** Stores in memory the data for the specific URL and token.
 */
- (void)set_memory_cache:(NSString*)url token:(int)token data:(id)data
{
	if (!_memory_cache) {
		DLOG(@"set_memory_cache failed due to nil pointer!");
		return;
	}

	LASSERT(!self.dont_cache, @"Trying to cache something uncacheable");
	NSNumber *token_num = [NSNumber numberWithInt:token];
	NSMutableDictionary *dict = [_memory_cache objectForKey:token_num];
	if (!dict) {
		DLOG(@"No memory structure for in-memory cached token?");
		return;
	}

	if ([data isKindOfClass:[NSMutableData class]])
		[dict setObject:[NSData dataWithData:data] forKey:url];
	else
		[dict setObject:data forKey:url];
}

@end
