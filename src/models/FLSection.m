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
#import "models/FLSection.h"

#import "categories/NSDictionary+Floki.h"
#import "categories/NSString+Floki.h"

#import "ELHASO.h"
#import "SBJson.h"


@implementation FLSection

@synthesize id_ = id__;
@synthesize sort_id = sort_id_;
@synthesize name = name_;
@synthesize visible = visible_;
@synthesize interactive = interactive_;
@synthesize starts_collapsed = starts_collapsed_;
@synthesize autocollapse_others = autocollapse_others_;
@synthesize hide_if_empty = hide_if_empty_;
@synthesize show_count = show_count_;
@synthesize collapsed_text_color = collapsed_text_color_;
@synthesize collapsed_back_color = collapsed_back_color_;
@synthesize expanded_text_color = expanded_text_color_;
@synthesize expanded_back_color = expanded_back_color_;

/** Creates a FLSection element from NSDictionary of the JSON string.
 *
 * Returns nil if there was a problem generating the object. This
 * could happen if you specify a section with zero or negative
 * identifier.
 */
- (id)initWithAPIDictionary:(NSDictionary *)dict
{
	if (self = [super init]) {
		self.id_ = [dict get_int:@"id" def:-1];
		self.sort_id = [dict get_int64:@"sort_id" def:self.id_];
		self.name = [dict objectForKey:@"name"];
		self.visible = [dict get_bool:@"visible" def:YES];
		self.interactive = [dict get_bool:@"interactive" def:YES];
		self.starts_collapsed = [dict get_bool:@"starts_collapsed" def:YES];
		self.autocollapse_others = [dict get_bool:@"autocollapse_others"
			def:YES];
		self.hide_if_empty = [dict get_bool:@"hide_if_empty" def:YES];
		self.show_count = [dict get_bool:@"show_count" def:NO];

		self.collapsed_text_color = [dict get_color:@"collapsed_text_color"
			def:nil];
		self.collapsed_back_color = [dict get_color:@"collapsed_back_color"
			def:nil];
		self.expanded_text_color = [dict get_color:@"expanded_text_color"
			def:nil];
		self.expanded_back_color = [dict get_color:@"expanded_back_color"
			def:nil];

		if (self.id_ < 1) {
			LOG(@"Invalid FLSection was created: %@", dict);
			[self release];
			return nil;
		}
		/* Correct some attributes if they were specified incorrectly. */
		if (!self.visible)
			self.interactive = NO;
		if (!self.interactive)
			self.starts_collapsed = NO;

	}
	return self;
}

- (void)dealloc
{
	[collapsed_text_color_ release];
	[collapsed_back_color_ release];
	[expanded_text_color_ release];
	[expanded_back_color_ release];
	[name_ release];
	[super dealloc];
}

/** Generates a mutable dictionary ready to be turned into JSON.
 */
- (NSMutableDictionary*)create_json_dict
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:14];
	[dict setValue:[NSNumber numberWithInt:self.id_] forKey:@"id"];
	[dict setValue:[NSDecimalNumber decimalNumberWithString:
		[NSString stringWithFormat:@"%lld", self.sort_id]] forKey:@"sort_id"];

	if (self.name.length > 0)
		[dict setValue:self.name forKey:@"name"];

	[dict setValue:[NSNumber numberWithBool:self.visible] forKey:@"visible"];

	[dict setValue:[NSNumber numberWithBool:self.interactive]
		forKey:@"interactive"];

	[dict setValue:[NSNumber numberWithBool:self.starts_collapsed]
		forKey:@"starts_collapsed"];

	[dict setValue:[NSNumber numberWithBool:self.autocollapse_others]
		forKey:@"autocollapse_others"];

	[dict setValue:[NSNumber numberWithBool:self.hide_if_empty]
		forKey:@"hide_if_empty"];

	[dict setValue:[NSNumber numberWithBool:self.show_count]
		forKey:@"show_count"];

	[dict setColor:self.expanded_back_color forKey:@"expanded_back_color"];
	[dict setColor:self.expanded_text_color forKey:@"expanded_text_color"];
	[dict setColor:self.collapsed_back_color forKey:@"collapsed_back_color"];
	[dict setColor:self.collapsed_text_color forKey:@"collapsed_text_color"];

	return dict;
}

/** Generates the JSON string with the object representation.
 * Returns an NSString object.
 */
- (NSString*)create_json
{
	return [[self create_json_dict] JSONRepresentation];
}

/** Returns YES if the object is the same as this one.
 * The comparison is performed at the content level, not just pointers.
 */
- (BOOL)is_equal_to:(FLSection*)other
{
	if (self == other) return YES;	
	if (self.id_ != other.id_) return NO;
	if (self.sort_id != other.sort_id) return NO;
	if (self.visible != other.visible) return NO;
	if (self.interactive != other.interactive) return NO;
	if (self.starts_collapsed != other.starts_collapsed) return NO;
	if (self.autocollapse_others != other.autocollapse_others) return NO;
	if (self.hide_if_empty != other.hide_if_empty) return NO;
	if (self.show_count != other.show_count) return NO;
	// TODO: Is this comparison right?
	if (![self.expanded_back_color isEqual:other.expanded_back_color])
		return NO;
	if (![self.expanded_text_color isEqual:other.expanded_text_color])
		return NO;
	if (![self.collapsed_back_color isEqual:other.collapsed_back_color])
		return NO;
	if (![self.collapsed_text_color isEqual:other.collapsed_text_color])
		return NO;
	if (![self.name isEqualToString:other.name]) return NO;
	return YES;
}

@end
