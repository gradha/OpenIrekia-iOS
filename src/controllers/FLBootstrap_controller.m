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
#import "controllers/FLBootstrap_controller.h"

#import "global/FLi18n.h"

#import "ELHASO.h"

@implementation FLBootstrap_controller

- (void)loadView
{
	[super loadView];

	is_landscape_ = NO;

	CGSize size = self.view.bounds.size;
	UILabel *label = [[UILabel alloc]
		initWithFrame:CGRectMake(0, size.height * 0.63, size.width, 30)];
	label.backgroundColor = [UIColor clearColor];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	label.text = _e(16);
	// _16: Connecting to the server...
	SET_ACCESSIBILITY_LANGUAGE(label);
	label.textAlignment = UITextAlignmentCenter;
	[self.view addSubview:label];
	[label release];
}

- (void)dealloc
{
	[super dealloc];
}

/** Allow landscape view. */
- (BOOL)shouldAutorotateToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/** Delay picking of image to load until we know the orientation.
 * That's just barely before appearing. Before this is called
 * willRotateToInterfaceOrientation will have been called, storing
 * is_landscape_.
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	NSString *name = @"Default.png";

	/* Detect if we are on the iPad. That requires a different default image. */
	if (IS_IPAD)
		name = is_landscape_ ?
			@"Default-Landscape.png" : @"Default-Portrait.png";

	UIImageView *splash = [[UIImageView alloc]
		initWithImage:[UIImage imageNamed:name]];
	/* For iPad landscape offset the image 20px to the top. */
	if (IS_IPAD && is_landscape_) {
		CGRect rect = splash.frame;
		rect.origin.y -= 20;
		splash.frame = rect;
	}
	[self.view insertSubview:splash atIndex:0];
	[splash release];
}

/** Detects the orientation and stores it in the landscape variable.
 */
- (void)willRotateToInterfaceOrientation:
	(UIInterfaceOrientation)to_orientation
	duration:(NSTimeInterval)duration
{
	if (UIInterfaceOrientationLandscapeLeft == to_orientation ||
			UIInterfaceOrientationLandscapeRight == to_orientation)
		is_landscape_ = YES;
}

@end
