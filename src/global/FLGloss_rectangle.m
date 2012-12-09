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
#import "global/FLGloss_rectangle.h"

#import "ELHASO.h"

#import "gloss-caustic-shader/RRCausticColorMatcher.h"
#import "gloss-caustic-shader/RRGlossCausticShader.h"
#import "gloss-caustic-shader/UIColor+RRUIKit.h"

@implementation FLGloss_rectangle

static NSMutableDictionary *_color_cache;

/** Generate a gloss rectangle image.
 * The width of the generated image is the maximum width of the
 * device in landscape mode, you only have to pass the desired height
 * for the rectangle. Pass the color components as values from 0 to
 * 255 inclusive.
 *
 * Returns nil if there was a really weird problem, or the UIImage,
 * which you should retain if you want to keep it. Returned images
 * are cached for performance.
 */
+ (UIImage*)get:(CGFloat)height color:(UIColor*)color
{
	RASSERT(height > 0 && height < 300, @"Too big or small uiimage.",
		return nil);

	if (!_color_cache)
		_color_cache = [[NSMutableDictionary dictionaryWithCapacity:15] retain];

	const int r = [color redComponent] * 255;
	const int g = [color greenComponent] * 255;
	const int b = [color blueComponent] * 255;
	const int rgb = r << 16 | g << 8 | b;
	NSNumber *key = [NSNumber numberWithInt:rgb];
	id ret = [_color_cache objectForKey:key];
	if (ret)
		return ret;

	DLOG(@"FLGloss_rectangle cache miss, generating.");
	const CGSize size = CGSizeMake(480, height);
	UIGraphicsBeginImageContext(size);

	RRGlossCausticShader *shader = [[RRGlossCausticShader alloc] init];
	[shader setNoncausticColor:color];
	[shader update];

	[shader drawShadingFromPoint:CGPointMake(0, 0)
		toPoint:CGPointMake(0, height)
		inContext:UIGraphicsGetCurrentContext()];
	[shader release];

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	LASSERT(image, @"Coudln't draw gloss rectangle?");
	UIGraphicsEndImageContext();
	if (image)
		[_color_cache setObject:image forKey:key];
	else
		DLOG(@"Couldn't generate rectangle image?");
	return image;
}

/** Frees the cached gloss images.
 */
+ (void)didReceiveMemoryWarning
{
	[_color_cache release];
	_color_cache = nil;
}

@end
