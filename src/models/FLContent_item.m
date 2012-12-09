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
#import "models/FLContent_item.h"

#import "FLi18n.h"
#import "categories/NSDictionary+Floki.h"
#import "categories/NSString+Floki.h"
#import "global/FlokiAppDelegate.h"
#import "protocols/FLTab_protocol.h"

#import "ELHASO.h"
#import "SBJson.h"


@implementation FLContent_item

@synthesize id_ = id__;
@synthesize expiration_date = expiration_date_;
@synthesize sort_id = sort_id_;
@synthesize title = title_;
@synthesize url = url_;
@synthesize share_url = share_url_;
@synthesize image = image_;
@synthesize online = online_;
@synthesize class_type = class_type_;
@synthesize data = data_;
@synthesize section_ids = section_ids_;


/** Creates a FLContent_item element from NSDictionary of the JSON string.
 * Note that you are unlikely to use this directly, content items
 * are pretty boring and you usually want to inherit this class.
 *
 * Returns nil if there was a problem generating the object.
 */
- (id)initWithAPIDictionary:(NSDictionary *)dict
{
	if (self = [super init]) {
		self.id_ = [dict get_int:@"id" def:-1];
		self.sort_id = [dict get_int64:@"sort_id" def:self.id_];
		self.title = [dict get_string:@"title" def:nil];
		self.url = [dict get_url:@"url" def:nil];
		self.share_url = [dict get_url:@"share_url" def:nil];
		self.image = [dict get_url:@"image" def:nil];
		self.online = [dict get_bool:@"online" def:NO];
		self.class_type = [dict get_string:@"class_type" def:nil];
		self.data = [dict get_dict:@"data" def:nil];
		self.section_ids = [dict get_array:@"section_ids"
			of:[NSNumber class] def:nil];
		self.expiration_date = [dict get_int:@"expiration_date" def:-1];

		if (!self.title || self.id_ < 1) {
			LOG(@"Invalid FLContent_item was created: %@", dict);
			[self release];
			return nil;
		}

		/* Verify that the type is one of the allowed types. */
		if (self.class_type) {
			bool valid =
				[self.default_controller isEqualToString:self.class_type];

			if (!valid) {
				valid = (nil != FLClassFromString(self.class_type));

				if (!valid) {
					LOG(@"Invalid FLContent_item class_type %@ in %@",
						self.class_type, dict);
					LASSERT(0, @"Invalid FLContent_item class_type");
					[self release];
					return nil;
				}
			}
		} else {
			self.class_type = self.default_controller;
		}
	}
	return self;
}

- (void)dealloc
{
	[section_ids_ release];
	[data_ release];
	[class_type_ release];
	[title_ release];
	[share_url_ release];
	[image_ release];
	[url_ release];
	[super dealloc];
}

/// Debugging helper, shows info about the object.
- (NSString*)description
{
	return [NSString stringWithFormat:@"FLContent_item {id:%d, sort_id:%lld, "
		@"title:%@}",
		id__, sort_id_, title_];
}

/** Returns the specific class name for the class.
 * Use this to let the FLContent_item class know the name of the specific
 * controller for the class inherithing from FLContent_item. This
 * should be the name of the default controller when the application
 * data protocol doesn't specify any.
 */
- (NSString*)default_controller
{
	return @"No controller";
}

/** Generates a mutable dictionary ready to be turned into JSON.
 */
- (NSMutableDictionary*)create_json_dict
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:17];
	[dict setValue:[NSNumber numberWithInt:self.id_] forKey:@"id"];
	[dict setValue:[NSDecimalNumber decimalNumberWithString:
		[NSString stringWithFormat:@"%lld", self.sort_id]] forKey:@"sort_id"];

	[dict setValue:self.title forKey:@"title"];
	if (self.url) [dict setValue:self.url forKey:@"url"];
	if (self.share_url) [dict setValue:self.share_url forKey:@"share_url"];
	if (self.image) [dict setValue:self.image forKey:@"image"];
	[dict setValue:[NSNumber numberWithBool:self.online] forKey:@"online"];
	if (self.class_type) [dict setValue:self.class_type forKey:@"class_type"];
	if (self.data) [dict setValue:self.data forKey:@"data"];

	if (self.section_ids.count > 0)
		[dict setValue:self.section_ids forKey:@"section_ids"];

	if (self.expiration_date > 0) [dict setValue:[NSNumber
		numberWithInt:self.expiration_date] forKey:@"expiration_date"];

	return dict;
}

/** Generates the JSON string with the object representation.
 * Returns an NSString object which has to be released by the receiver.
 */
- (NSString*)create_json
{
	return [[self create_json_dict] JSONRepresentation];
}

/** Returns the generic controller for this item.
 *
 * Returns nil if there was a problem or no controller is available
 * for this item.
 */
- (UIViewController*)get_controller:(NSString*)base_url;
{
	LASSERT(base_url, @"Bad pointer");
	if (!self.url)
		return nil;

	/* Construct the navigation controller with view controller. */
	DLOG(@"Creating class from string '%@'", self.class_type);
	UIViewController *controller = [FLClassFromString(self.class_type) new];
	if (!controller)
		return nil;
	controller = [controller autorelease];

	/* Modify the data bundle before passing it to the controller. */
	NSMutableDictionary *data = [NSMutableDictionary
		dictionaryWithDictionary:self.data];
	NSString *the_url = self.url;
	if ([the_url isRelativeURL])
		the_url = [NSString stringWithFormat:@"%@/%@", base_url, the_url];
	[data setValue:the_url forKey:@"main_url"];

	/* Let the class initialise itself. */
	id <FLTab_protocol> protocol_cast = (id)controller;
	if (![protocol_cast init_with_data:data unique_id:self.id_]) {
		LASSERT(0, @"Class doesn't support tab protocol. Bad");
		controller = nil;
	} else {
		[protocol_cast name_for_cache];
		//controller.title = @"Test title";
		if (self.share_url.length > 0) {
			if ([controller respondsToSelector:@selector(setShare_url:)])
				[controller performSelector:@selector(setShare_url:)
					withObject:self.share_url];
		}

		if ([controller respondsToSelector:@selector(setItem_id:)])
			[controller performSelector:@selector(setItem_id:)
				withObject:[NSNumber numberWithInt:self.id_]];
	}

	return controller;
}

- (NSString*)accessibilityLabel
{
	return NON_NIL_STRING(self.title);
}

- (NSString*)accessibilityLanguage
{
	return [[FLi18n get] current_langcode];
}

@end
