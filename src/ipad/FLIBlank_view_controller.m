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
#import "ipad/FLIBlank_view_controller.h"

#import "global/FLi18n.h"

#import "ELHASO.h"


@implementation FLIBlank_view_controller

@synthesize label = label_;

- (void)dealloc
{
	[arrow_ release];
	[label_ release];
	[super dealloc];
}

- (void)loadView
{
	[super loadView];

	self.view.backgroundColor = [UIColor whiteColor];
	self.view.contentMode = UIViewContentModeScaleAspectFit;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;

	/* Load the shield view and put it on the center. */
	UIImageView *image_view = [[UIImageView alloc]
		initWithImage:[UIImage imageNamed:@"shield.png"]];
	const CGSize size = self.view.bounds.size;
	image_view.center = CGPointMake(size.width / 2.0, size.height / 2.0);
	image_view.contentMode = UIViewContentModeCenter;
	image_view.autoresizingMask = UIViewAutoresizingFlexibleWidth |
		UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:image_view];
	[image_view release];

	/* Keep the arrow to allow rotations. */
	arrow_ = [[UIImageView alloc]
		initWithImage:[UIImage imageNamed:@"ipad_arrow_up.png"]];
	arrow_.transform = CGAffineTransformMakeRotation(angle_);
	[self.view addSubview:arrow_];

	/* Create right next to the arrow a text. */
	CGRect rect = self.view.frame;
	rect.origin.y = 0;
	rect.origin.x = arrow_.image.size.width;
	rect.size.height = arrow_.image.size.height;
	rect.size.width -= rect.origin.x;
	UILabel *label = [[UILabel alloc] initWithFrame:rect];
	label.text = NON_NIL_STRING(_(STR_BROWSE_IPAD_SECTIONS));
	label.numberOfLines = 0;
	label.lineBreakMode = UILineBreakModeTailTruncation;
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor blackColor];
	label.shadowColor = [UIColor lightGrayColor];
	label.shadowOffset = CGSizeMake(1, 1);
	[self.view addSubview:label];
	self.label = label;
	[label release];
}

/** Allow landscape view. */
- (BOOL)shouldAutorotateToInterfaceOrientation:
	(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/** Handles the rotation of the arrow.
 */
- (void)willRotateToInterfaceOrientation:
	(UIInterfaceOrientation)toInterfaceOrientation
	duration:(NSTimeInterval)duration
{
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			angle_ = -M_PI / 2.0;
			break;
		default:
			angle_ = 0;
			break;
	}
	BLOCK_UI();
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	arrow_.transform = CGAffineTransformMakeRotation(angle_);
	[UIView commitAnimations];
}

@end
