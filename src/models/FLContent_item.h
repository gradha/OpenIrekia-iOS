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
#import <Foundation/Foundation.h>

/** Base model controller.
 *
 * Implements common functionality and attributes which otherwise
 * would be repeated through all the classes. The interesting bits
 * are creation of items with FLContent_item::initWithAPIDictionary:
 * and FLContent_item::get_controller:, which returns the most
 * appropriate view controller to show the specific item.
 */
@interface FLContent_item : NSObject

@property(nonatomic, assign) int id_;
@property(nonatomic, assign) int expiration_date;
@property(nonatomic, assign) uint64_t sort_id;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSString *url;
@property(nonatomic, retain) NSString *share_url;
@property(nonatomic, retain) NSString *image;
@property(nonatomic, assign) BOOL online;
@property(nonatomic, retain) NSString *class_type;
@property(nonatomic, retain) NSDictionary *data;
@property(nonatomic, retain) NSArray *section_ids;
@property(nonatomic, retain, readonly) NSString *default_controller;

- (id)initWithAPIDictionary:(NSDictionary *)dict;
- (void)dealloc;
- (NSString*)create_json;
- (NSMutableDictionary*)create_json_dict;
- (UIViewController*)get_controller:(NSString*)base_url;
- (NSString*)accessibilityLabel;

@end
