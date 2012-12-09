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
#import "models/FLGallery_item.h"

#import "categories/NSDictionary+Floki.h"
#import "categories/NSString+Floki.h"
#import "gallery/FLPhoto_view_controller.h"
#import "gallery/FLStrip_view_controller.h"
#import "protocols/FLTab_protocol.h"

#import "ELHASO.h"
#import "SBJson.h"


NSString *GALLERY_CACHE_TABLES[] = { @"Gallery_thumbs", @"Gallery_images",
	nil };

@implementation FLGallery_item

@synthesize width = width_;
@synthesize height = height_;
@synthesize max_zoom = max_zoom_;
@synthesize caption_text = caption_text_;

/** Creates a FLGallery_item element from NSDictionary of the JSON string.
 * Returns nil if there was a problem generating the object.
 */
- (id)initWithAPIDictionary:(NSDictionary *)dict
{
	if (self = [super initWithAPIDictionary:dict]) {
		self.width = [dict get_int:@"width" def:-1];
		self.height = [dict get_int:@"height" def:-1];
		self.max_zoom = MAX(1, [dict get_float:@"max_zoom" def:2]);

		if (!self.image || self.width < 1 || self.height < 1) {
			LOG(@"Invalid FLGallery_item was created: %@", dict);
			[self release];
			return nil;
		}

		self.caption_text = [dict get_string:@"caption_text" def:nil];
	}
	return self;
}

- (void)dealloc
{
	[caption_text_ release];
	[super dealloc];
}

/** Returns the default controller class name for this item.
 * See parent definition for notes.
 */
- (NSString*)default_controller
{
	return @"Photo_view_controller";
}

/** Generates the JSON string with the object representation.
 * Returns an NSString object which has to be retained by the receiver.
 */
- (NSString*)create_json
{
	// TODO: Move common code to protocol function?
	NSMutableDictionary *dict = [super create_json_dict];
	[dict setValue:[NSNumber numberWithInt:self.width] forKey:@"width"];
	[dict setValue:[NSNumber numberWithInt:self.height] forKey:@"height"];
	[dict setValue:[NSNumber numberWithFloat:self.max_zoom] forKey:@"max_zoom"];
	if ([self.caption_text length] > 0)
		[dict setValue:self.caption_text forKey:@"caption_text"];

	return [dict JSONRepresentation];
}

/** Returns the specific controller for this item.
 *
 * Returns nil if there was a problem or no controller is available
 * for this item.
 */
- (UIViewController*)get_controller:(NSString*)base_url token:(int)token
{
	LASSERT(base_url, @"Bad pointer");
	if (!self.url)
		return nil;

	UIViewController *controller = nil;
	if ([self.class_type isEqualToString:self.default_controller]) {
		FLPhoto_view_controller *c = [FLPhoto_view_controller new];
		c.base_url = base_url;
		c.cache_token = token;
		c.item = self;
		controller = [c autorelease];
	} else {
		controller = [super get_controller:base_url];
	}

	return controller;
}

- (UIViewController*)get_controller:(NSString*)base_url token:(int)token
	group:(NSArray*)group
{
	LASSERT(base_url, @"Bad base_url pointer");
	LASSERT(group, @"Bad group pointer");
	if (!self.url)
		return nil;

	UIViewController *controller = nil;
	if ([self.class_type isEqualToString:self.default_controller]) {
		FLStrip_view_controller *c = [FLStrip_view_controller new];
		c.base_url = base_url;
		c.cache_token = token;
		c.group = group;
		c.item = self;
		controller = [c autorelease];
	} else {
		controller = [super get_controller:base_url];
	}

	return controller;
}

@end
