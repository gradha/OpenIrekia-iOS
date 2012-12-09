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
#import "global/FLInt_check.h"

#import "ELHASO.h"

static NSMutableDictionary *_memory_cache;

@implementation FLInt_check

/** Constructs an FLInt_check wrapper around a mutable set.
 * Usually you will be using the static cache() method to retrieve these
 * objects.
 */
- (id)init
{
	if (self = [super init]) {
		dic_ = [[NSMutableSet alloc] initWithCapacity:60];
	}
	return self;
}

- (void)dealloc
{
	[dic_ release];
	[super dealloc];
}

/** Get a dictionary for a specific cache index.
 * If the dictionary doesn't exist, it will be created.
 */
+ (FLInt_check*)cache:(int)number
{
	if (!_memory_cache)
		_memory_cache = [[NSMutableDictionary dictionary] retain];
	LASSERT(_memory_cache, @"Uh oh");

	NSNumber *key = [NSNumber numberWithInt:number];
	id obj = [_memory_cache objectForKey:key];
	if (obj)
		return obj;

	obj = [FLInt_check new];
	[_memory_cache setObject:obj forKey:key];
	return [obj autorelease];
}

/** Returns true if the number has been previously set.
 */
- (BOOL)get:(int)number
{
	return [dic_ containsObject:[NSNumber numberWithInt:number]];
}

/** Sets a number to true. Once set there is no way back...
 */
- (void)set:(int)number
{
	[dic_ addObject:[NSNumber numberWithInt:number]];
}

@end
