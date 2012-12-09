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
#import "EGODatabase.h"

/** Wrapper around EGODatabase
 *
 * Holds the pointer to the real sqlite object and provides additional
 * wrapper helper functions to handle the database.
 */
@interface FLDB : EGODatabase
{
}

+ (NSString*)path;
+ (FLDB*)open_database;
+ (FLDB*)get_db;

- (BOOL)register_tab:(NSString*)name unique_id:(int)unique_id;
- (NSDate*)get_tab_timestamp:(int)tab;
- (void)touch_tab_timestamp:(int)tab;
- (void)remove_tabs:(NSArray*)id_list;

- (void)save_meta_item:(NSString*)table data:(NSString*)data the_id:(int)the_id
	owner:(int)owner;
- (void)purge_unused_sections:(int)owner to_preserve:(NSArray*)to_preserve;
- (void)purge_stale_meta_items:(NSString*)parent_table
	data_tables:(NSString**)data_tables lowest_id:(int)lowest_id
	owner:(int)owner;
- (void)purge_meta_items:(NSString*)parent_table
	data_tables:(NSString**)data_tables to_delete:(NSArray*)to_delete
	owner:(int)owner;
- (NSArray*)read_sections:(int)owner;
- (NSArray*)read_meta_items:(NSString*)parent_table owner:(int)owner;

- (void)save_meta_data:(NSString*)table the_id:(int)the_id owner:(int)owner
	url:(NSString*)url data:(NSMutableData*)data;
- (NSData*)load_meta_data:(NSString*)table the_id:(int)the_id
	owner:(int)owner url:(NSString*)url;

@end
