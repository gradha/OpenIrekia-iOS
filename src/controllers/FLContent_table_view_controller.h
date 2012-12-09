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
#import "controllers/FLContent_view_controller.h"

@class FLContent_item;
@class FLSection_state;

/** Helper code for table content controllers.
 *
 * This is based on the article by Matt Gallagher 
 * (http://cocoawithlove.com/2009/03/recreating-uitableviewcontroller-to.html).
 * While this is not strictly a copy&paste, let's put his copyright
 * notice for completeness:
 *
//  BaseViewController.m
//  RecreatedTableViewController
//
//  Created by Matt Gallagher on 22/03/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
 *
 */
@interface FLContent_table_view_controller : FLContent_view_controller
	<UITableViewDelegate, UITableViewDataSource>
{
}

/// The table view for the class, emulating the expected property.
@property (nonatomic, retain) UITableView *tableView;

/// Stores the sections, if any.
@property (nonatomic, retain) NSArray *sections;

- (void)process_new_sections:(NSArray*)new_sections;
- (NSIndexPath*)path_for_item:(int)id_;
- (FLContent_item*)item_at_index_path:(NSIndexPath*)indexPath;
- (FLSection_state*)section_by_index:(int)section_index;
- (NSArray*)items_in_section:(int)section_index;
- (void)save_sections_to_cache:(NSArray*)sections owner_id:(int)owner_id;

- (UIColor*)get_section_collapsed_text_color;
- (UIColor*)get_section_collapsed_back_color;
- (UIColor*)get_section_expanded_text_color;
- (UIColor*)get_section_expanded_back_color;
- (int)get_section_title_padding;

@end
