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

/** Section data holder.
 *
 * Holds the parameters of a section. Most of the attributes come
 * from the protocol specification. The biggest exception is the items
 * attribute, which is used by the code to check which items have to
 * be shown in each section and is therefore not serialized to json.
 */
@interface FLSection : NSObject

/// Internal database identifier of the section.
@property(nonatomic, assign) int id_;
/// Sorting identifier. By default takes the value of the db identifier.
@property(nonatomic, assign) uint64_t sort_id;
/// Optional name for the section.
@property(nonatomic, retain) NSString *name;
/// Is the section's header visible?
@property(nonatomic, assign) BOOL visible;
/// If the header is visible, can the user interact with it?
@property(nonatomic, assign) BOOL interactive;
/// If the header is interactive, does it start collapsed?
@property(nonatomic, assign) BOOL starts_collapsed;
/// Does collapsing this header collapse all other?
@property(nonatomic, assign) BOOL autocollapse_others;
/// Does the section hide if it is empty?
@property(nonatomic, assign) BOOL hide_if_empty;
/// Does the section append an item count to it's name header?
@property(nonatomic, assign) BOOL show_count;
/// If not nil, overwrides the default section collapsed text color.
@property(nonatomic, retain) UIColor *collapsed_text_color;
/// If not nil, overwrides the default section collapsed back color.
@property(nonatomic, retain) UIColor *collapsed_back_color;
/// If not nil, overwrides the default section expanded text color.
@property(nonatomic, retain) UIColor *expanded_text_color;
/// If not nil, overwrides the default section expanded back color.
@property(nonatomic, retain) UIColor *expanded_back_color;

- (id)initWithAPIDictionary:(NSDictionary *)dict;
- (void)dealloc;
- (NSString*)create_json;
- (NSMutableDictionary*)create_json_dict;
- (BOOL)is_equal_to:(FLSection*)other;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
