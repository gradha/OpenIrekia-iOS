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
#import "controllers/FLCommon_view_controller.h"

#import "global/FLMore_cell.h"
#import "models/FLMore_item.h"

#import "protocols/FLItem_delegate.h"

#import "ELHASO.h"


@implementation FLCommon_view_controller

@synthesize cell_identifier = cell_identifier_;
@synthesize child_controller = child_controller_;
@synthesize did_startup = did_startup_;
@synthesize langcode_url = langcode_url_;
@synthesize row_height = row_height_;
@synthesize url = url_;

#pragma mark -
#pragma mark Methods

- (void)dealloc
{
	child_controller_ = nil;
	[cell_identifier_ release];
	[langcode_url_ release];
	[url_ release];
	[super dealloc];
}

/// Clones into the receiver the properties which make sense.
- (void)copy_from:(FLCommon_view_controller*)other
{
	[super copy_from:other];
	self.langcode_url = other.langcode_url;
	self.url = other.url;
}

/** Updates the "more cell" with a network error.
 * In order to update the more cell, you have to pass the underlaying logical
 * FLMore_item which stores its state. Pass it as the more_item parameter. Note
 * that you can pass anything there (even nil), the method will simply do
 * nothing if an FLMore_item cell is not provided.
 */
- (void)show_error_in_more_cell:(NSError*)error
	more_item:(FLMore_item*)more_item
{
	if (![more_item isKindOfClass:[FLMore_item class]])
		return;

	more_item.is_working = NO;
	more_item.title = error.localizedDescription;

	// If there is a "more" cell, stop it.
	for (id visible_cell in self.tableView.visibleCells) {
		FLMore_cell *cell = CAST(visible_cell, FLMore_cell);
		if (cell) {
			[cell stop];
			cell.label.text = more_item.title;
		}
	}
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
