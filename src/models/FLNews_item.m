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
#import "models/FLNews_item.h"

#import "categories/NSDictionary+Floki.h"
#import "categories/NSString+Floki.h"
#import "news/FLItem_view_controller.h"
#import "protocols/FLTab_protocol.h"

#import "ELHASO.h"
#import "SBJson.h"


NSString *NEWS_CACHE_TABLES[] = { @"News_thumbs", @"Item_contents", nil };


@implementation FLNews_item

@synthesize body = body_;
@synthesize footer = footer_;
@synthesize follow_content = follow_content_;

/** Creates a FLNews_item element from NSDictionary of the JSON string.
 * Returns nil if there was a problem generating the object.
 */
- (id)initWithAPIDictionary:(NSDictionary *)dict
{
	if (self = [super initWithAPIDictionary:dict]) {
		self.body = [dict get_string:@"body" def:nil];
		self.footer = [dict get_string:@"footer" def:nil];
		self.follow_content = [dict get_bool:@"follow_content" def:YES];

		if (!self.body) {
			LOG(@"Invalid FLNews_item was created: %@", dict);
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[footer_ release];
	[body_ release];
	[super dealloc];
}

/** Returns the default controller class name for this item.
 * See parent definition for notes.
 */
- (NSString*)default_controller
{
	return @"Item_view_controller";
}

/** Generates the JSON string with the object representation.
 * Returns an NSString object which has to be released by the receiver.
 */
- (NSString*)create_json
{
	NSMutableDictionary *dict = [super create_json_dict];
	[dict setValue:self.body forKey:@"body"];
	if (self.footer) [dict setValue:self.footer forKey:@"footer"];
	[dict setValue:[NSNumber numberWithBool:self.follow_content]
		forKey:@"follow_content"];

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
		FLItem_view_controller *c = [FLItem_view_controller new];
		c.base_url = base_url;
		c.cache_token = token;
		c.item = self;
		controller = [c autorelease];
	} else {
		controller = [super get_controller:base_url];
	}

	return controller;
}

@end
