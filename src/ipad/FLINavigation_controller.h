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
/** Allows replacing the root view controller for navigation.
 * This is an iPad exclusive class. For the details view we want
 * to have a navigation view which can replace the whole hiearchy.
 * By default the Apple class doesn't allow this, so it is acomplished
 * faking an empty root controller.
 *
 * Some code and inspiration came from
 * http://starterstep.wordpress.com/2009/03/05/changing-a-uinavigationcontroller’s-root-view-controller/
 */
@interface FLINavigation_controller : UINavigationController
{
	UIViewController *fake_root_view_controller_;

	/** Weird, under iOS4 there are problems with the viewControllers
	 * method, so activating this will avoid the faking of the
	 * returned array.
	 */
	BOOL stop_faking_;
}

-(void)set_root_view_controller:(UIViewController *)controller;

@end

