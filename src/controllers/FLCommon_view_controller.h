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
#import "controllers/FLContent_table_view_controller.h"

@class FLMore_item;
@protocol FLItem_delegate;

@interface FLCommon_view_controller : FLContent_table_view_controller
{
}

/// Stores the generated string for cell reuse. Different on each tab.
@property (nonatomic, retain) NSString *cell_identifier;

/// And this is url_ + the current language code.
@property (nonatomic, retain) NSString *langcode_url;

/// The feed's URL. Note that this is not used, but rather langcode_url_.
@property (nonatomic, retain) NSString *url;

/// Maintains a weak pointer to the child class to change its item.
@property (nonatomic, assign) id<FLItem_delegate> child_controller;

/// Remembers if we have already loaded ourselves from disk.
@property (nonatomic, assign) BOOL did_startup;

/// Pixels of the row height.
@property (nonatomic, assign) int row_height;


- (void)copy_from:(FLContent_view_controller*)other;

- (void)show_error_in_more_cell:(NSError*)error
	more_item:(FLMore_item*)more_item;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
