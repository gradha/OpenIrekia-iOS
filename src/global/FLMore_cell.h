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
#import "ELHASO_cell.h"

@class FLMore_item;
@class UIActivity;

@interface FLMore_cell : ELHASO_cell
{
	/// Activity spinner, to the left of the cell.
	UIActivity *activity_;
}

/// Text showing the current state of the label.
@property (nonatomic, retain) UILabel *label;

- (void)stop;
- (void)start;
- (BOOL)isAnimating;
- (void)update_state_from:(FLMore_item*)item;
- (void)set_background_color:(UIColor*)background_color
	highlight_color:(UIColor*)highlight_color;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
