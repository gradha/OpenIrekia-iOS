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
#import "ipad/FLINavigation_controller.h"

@implementation FLINavigation_controller

-(id)initWithRootViewController:(UIViewController *)controller
{
	//create the fake controller and set it as the root
	UIViewController *fake = [[UIViewController alloc] init];
	if (self = [super initWithRootViewController:fake]) {
		fake_root_view_controller_ = fake;
		//hide the back button on the perceived root
		controller.navigationItem.hidesBackButton = YES;
		//push the perceived root (at index 1)
		[self pushViewController:controller animated:NO];
	} else {
		[fake release];
	}
	return self;
}

- (void)dealloc
{
	[fake_root_view_controller_ release];
	[super dealloc];
}

/** Returns the controllers.
 * This overrides the parent method to remove the fake root controller
 * from the list.
 */
- (NSArray*)viewControllers
{
	if (stop_faking_)
		return [super viewControllers];

	NSArray *controllers = [super viewControllers];
	if (controllers != nil && controllers.count > 0) {
		NSMutableArray *array = [NSMutableArray arrayWithArray:controllers];
		[array removeObjectAtIndex:0];
		return array;
	}
	return controllers;
}

/** Pops the views to the fake root controler.
 */
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
	//we use index 0 because we overrided "viewControllers"
	return [self popToViewController:[self.viewControllers objectAtIndex:0]
		animated:animated];
}

/** Sets the new root view controller.
 * Internally this pops everything up to the fake controller. Before popping
 * the views makes sure to disconnect each of them through informal selectors.
 */
-(void)set_root_view_controller:(UIViewController *)controller
{
	// Disconnect all relationships to avoid crashing.
	SEL action1 = @selector(setContainer:);
	SEL action2 = @selector(disconnect_child:);
	for (id controller in self.viewControllers) {
		if ([controller respondsToSelector:action1])
			[controller performSelector:action1 withObject:nil];
		if ([controller respondsToSelector:action2])
			[controller performSelector:action2 withObject:nil];
	}

	// Now do the swapping.
	stop_faking_ = YES;
	controller.navigationItem.hidesBackButton = YES;
	[self popToViewController:fake_root_view_controller_ animated:NO];
	[self pushViewController:controller animated:NO];
	controller.navigationController.navigationBar.alpha = 1;
	/* The photo browser might have set the bar hidden and black. Restore it. */
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	[[UIApplication sharedApplication]
		setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
	controller.navigationController.navigationBar.barStyle = UIBarStyleDefault;
	stop_faking_ = NO;
}

@end
