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
@class FLIBlank_view_controller;
@class FLINavigation_controller;

/** Handles the iPad root view.
 *
 * Subclassed to handle rotations and provide basic communication
 * between detail and master views.
 */
@interface FLISplit_view_controller : UISplitViewController
	<UISplitViewControllerDelegate>
{
	/// Pointer to the details' navigation controller.
	FLINavigation_controller *details_;

	/// Pointer to the blank view. Only used during startup to fix labels.
	FLIBlank_view_controller *blank_view_;
}

/// Keep track of the popover controller and bar button.
@property (nonatomic, retain) UIPopoverController *pop_controller;

/// Keep track of the bar button.
@property (nonatomic, retain) UIBarButtonItem *pop_button;

- (id)init_with_master:(UIViewController*)controller;
- (void)set_detail_controller:(UIViewController*)controller;
- (void)recover_button_text;
- (void)remember_current_tab_and_item;
- (void)dismiss_pop_over;

@end
