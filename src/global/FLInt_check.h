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
/** \file FLInt_check.h
 * Special in memory cache of used integers.
 */

/** Class to mark integers as used.
 *
 * You can create a class yourself or get a special domain class
 * with the cache() method. The purpose of the class is to have a
 * memory persistent store of integers that have been used. This list
 * is useful for the FLItem_view_controller. That class needs to
 * refresh cached data from the network, even if it was loaded from
 * disk. But only once per application run.
 *
 * Since network news elements are replaced every time the user
 * asks for a network refresh, the FLNews_item class can't hold the
 * state of having been downloaded before. So we use this class to
 * store that info.
 *
 * Ugly, but works. As long as I don't forget what this was meant for...
 */
@interface FLInt_check : NSObject
{
	NSMutableSet *dic_;
}

- (id)init;
+ (FLInt_check*)cache:(int)number;
- (BOOL)get:(int)number;
- (void)set:(int)number;

@end
