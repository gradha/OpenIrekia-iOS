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
@class NSDictionary;

/** View controllers willing to be tabs are required to implement this.
 */
@protocol FLTab_protocol

@required
/** Initialises the tab with JSON data.
 * The function will be passed the unique_id database identifier
 * that should be assigned to the tab and used from now on for all
 * disk cache queries.
 *
 * \return Returns no if the tab could not be initialised.
 */
- (BOOL)init_with_data:(NSDictionary*)data unique_id:(int)unique_id;
/// \return Returns the unique identifier the tab was created with.
- (int)unique_id;

@optional
/// \return Not all tabs implement this, just the human name for the tab.
- (NSString*)name_for_cache;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
