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
#import "global/FLi18n.h"

#import "global/settings.h"

#import "ELHASO.h"

#import <Foundation/Foundation.h>

#import <assert.h>
#import <stdlib.h>

static FLi18n *_global_i18n;

// Forward internal declarations.
static int _get_max_string_id(NSDictionary *strings);

static NSString *_default_strings[STR_LAST - STR_FIRST - 1] = {
	@"Share this news...",
	@"Share this picture...",
	@"Copy address",
	@"Send email",
	@"Cancel",
	@"<TITLE>",
	@"<TITLE>",
	@"<A HREF=\"<URL>\"><URL></A>",
	@"<A HREF=\"<URL>\"><URL></A>",
	@"<A HREF=\"<URL>\"><PHOTO_DESC></A>",
	@"Share this movie...",
	@"<TITLE>",
	@"<A HREF=\"<URL>\"><URL></A>",
	@"Twitter",
	@"Facebook",
	@"Browse the sections and select an item",
	@"Sections",
};

@interface FLi18n ()
- (NSArray*)alloc_strings:(NSArray*)langcodes;
- (NSDictionary*)scan_for_ui_lang:(NSArray*)langcodes;
+ (NSString*)get_effective_language;
@end

@implementation FLi18n

/** Initialises the i18n language array.
 *
 * The function will retrieve the strings stored in the langcodes
 * array according to the application data protocol. The strings
 * retrieved will be those specified by the user preferred language.
 * If it doesn't exist, the first language will be set.
 *
 * The logic to retrieve the user preferred language is to look at
 * the application preferences. If auto is set, that will use the
 * current OS's language code for the language. If the selected
 * language is not found among those available, the first (master)
 * language in the array will be set.
 *
 * Call [FLi18n set] with the returned object to be able to use the
 * _() and _s() macros safely.
 *
 * Returns nil if there were problems.
 */
- (id)init_with_langs:(NSArray*)json_data
{
	if (self = [super init]) {
		strings_ = [self alloc_strings:json_data];
		if (!strings_) {
			[code_ release];
			[self release];
			self = nil;
		} else {
			LASSERT(code_, @"Uh, something didn't work right");
		}
	}
	return self;
}

- (void)dealloc
{
	[strings_ release];
	[code_ release];
	[super dealloc];
}

/** Retrieves a string by integer.
 * Returns nil if there was some problem.
 */
- (NSString*)string_by_number:(int)string_id
{
	if (string_id < [strings_ count]) {
		return [strings_ objectAtIndex:string_id];
	} else {
		DLOG(@"Requested string %d out of range %d",
			string_id, [strings_ count]);
		return nil;
	}
}

/** Retrieves a string by another string containing an integer.
 * Returns nil if there was some problem.
 */
- (NSString*)string_by_string:(NSString*)number
{
	assert(number);
	return [self string_by_number:[number intValue]];
}

/** Builds the string array from the input langcodes.
 * Returns the retained array or NULL with problems. Free it when possible.
 * If the return value is successfull, the variable code_ will be
 * set with the found langcode used to fill the strings_ array.
 */
- (NSArray*)alloc_strings:(NSArray*)langcodes
{
	LASSERT(!code_, @"Reinitialisation?");
	if (!langcodes || [langcodes count] < 1) {
		DLOG(@"No langcodes in input '%@'", langcodes);
		return nil;
	}

	NSDictionary *master_lang = [[[langcodes objectAtIndex:0] allValues]
		objectAtIndex:0];

	NSDictionary *lang = [self scan_for_ui_lang:langcodes];
	if (!lang)
		lang = master_lang;
	if (!lang) {
		DLOG(@"Didn't find the user preferred langcode.");
		return nil;
	}

	const int num_strings = _get_max_string_id(master_lang) + 1;
	if (num_strings < 1) {
		DLOG(@"Input JSON doesn't contain strings? '%@'", langcodes);
		return nil;
	}

	NSMutableArray *strings = [NSMutableArray arrayWithCapacity:num_strings];
	assert(strings && "Not enough memory");
	/* Stupid class doesn't have a way to initialise with nil entries. */
	LASSERT(STR_LAST - STR_FIRST - 1 == DIM(_default_strings), @"Bad array");
	for (int f = 0; f < num_strings; f++) {
		if (f > STR_FIRST && f < STR_LAST)
			[strings addObject:_default_strings[f - STR_FIRST - 1]];
		else
			[strings addObject:@"!empty!"];
	}

	/* Iterate the master language dictionary getting strings. */
	for (NSString *master_key in master_lang) {
		NSString *s = [lang objectForKey:master_key];
		if (!s)
			s = [master_lang objectForKey:master_key];
		assert(s);
		const int string_id = [master_key intValue];
		[strings replaceObjectAtIndex:string_id withObject:s];
	}

	return [[NSArray arrayWithArray:strings] retain];
}

/** Searches for langcode in the array.
 * Returns the pointer to the NSDictionary holding the strings for
 * langcode or nil.
 *
 * Also sets code_ to the used language code. If the function returns
 * nil, code_ will be set to the first entry in the language code.
 */
- (NSDictionary*)scan_for_ui_lang:(NSArray*)langcodes
{
	LASSERT([langcodes count] > 0, @"Bad initialisation");

	NSString *preferred_langcode = [FLi18n get_effective_language];

	for (NSDictionary *dict in langcodes) {
		NSDictionary *result = [dict objectForKey:preferred_langcode];
		if (result) {
			code_ = [preferred_langcode retain];
			return result;
		}
	}

	NSDictionary *first = [langcodes objectAtIndex:0];
	if ([first count] > 0) {
		NSString *first_code = [[first allKeys] objectAtIndex:0];
		LASSERT([first_code length] > 1, @"Bad langcode key");
		if ([first_code length] > 1)
			code_ = [first_code retain];
	}
	DLOG(@"Didn't find langcode %@, setting %@...", preferred_langcode, code_);
	return nil;
}

/** Retrieves the currently used langcode by the language system.
 * Always returns a valid two letter code. Note that the current
 * langcode doesn't have much to do with the system language, since
 * the user can override it through preferences to another language.
 */
- (NSString*)current_langcode
{
	return code_;
}

/** Returns the currently effective selected user language.
 * This function only looks at the system preferences, the global
 * OS language, and returns the string it thinks should be used by
 * the code. This transforms the auto setting too. The final returned
 * string should be two characters long, or something like that.
 */
+ (NSString*)get_effective_language
{
	/* Read the user's language preferences. */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *preferred_langcode = [defaults objectForKey:DEFAULTS_LANGCODE];
	if (!preferred_langcode || [preferred_langcode isEqualToString:@"auto"]) {
		/* Retrieve system language code. */
		NSArray *languages = [defaults objectForKey:DEFAULTS_APPLE_LANGUAGES];
		preferred_langcode = [languages objectAtIndex:0];
	}

	/* Just in case we get something weird. */
	if ([preferred_langcode length] < 2) {
		DLOG(@"We got some weird code '%@', setting en", preferred_langcode);
		preferred_langcode = @"en";
	}
	return preferred_langcode;
}

/** Sets the global language.
 * If you pass nil, the current language will be freed.
 */
+ (void)set:(FLi18n*)langs
{
	[langs retain];
	[_global_i18n release];
	_global_i18n = langs;
}

/** Returns the currently set language.
 * Returns nil if nothing was previously set.
 */
+ (FLi18n*)get
{
	return _global_i18n;
}

/** Checks get_effective_language against the last stored used language.
 * If the languages don't match, the function will return YES and
 * also set the last stored used language to this code.
 *
 * Note that this doesn't have to do anything with the languages
 * provided by the server: the checks are done without context, only
 * detecting whatever the user has selected in the system preferences.
 * So maybe the effective language doesn't even exist in your
 * application, but that's not what is important here.
 */
+ (BOOL)did_last_used_language_change
{
	NSString *current = [FLi18n get_effective_language];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *last = [defaults objectForKey:LAST_LANGCODE];
	if ([last isEqualToString:current])
		return NO;

	/* Ok, update the last used code and return YES. */
	DLOG(@"Previos language was %@, now %@. Resetting cache.", last, current);
	[defaults setObject:current forKey:LAST_LANGCODE];
	return YES;
}

/** Returns the identifier string from the embedded resource files.
 * If the string doesn't exist, an automatically made string is returned.
 *
 * Note that this bypasses whatever language selection/content is
 * offered by the server and looks only on the local disk for
 * internationalized resources.
 */
+ (NSString*)embeded_string:(int)string_id
{
	static NSArray *strings = 0;

	/* Should we load the messages from disk? */
	if (!strings) {
		NSString *name = [NSString stringWithFormat:@"str_%@",
			[FLi18n get_effective_language]];
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *path = [bundle pathForResource:name ofType:@"plist"];
		strings = [[NSArray alloc] initWithContentsOfFile:path];

		/* Ok, if not found, load english version. */
		if (!strings) {
			path = [bundle pathForResource:@"str_en" ofType:@"plist"];
			strings = [[NSArray alloc] initWithContentsOfFile:path];

			/* Give up, just set up a default array. */
			LASSERT(strings, @"Didn't load even language embedded strings!");
			if (!strings)
				strings = [[NSArray array] retain];
		}
	}

	if (string_id < 0 || string_id >= strings.count) {
		DLOG(@"Requested embedded string %d out of range %d", string_id,
			strings.count);
		return [NSString stringWithFormat:@"ESTR %d", string_id];
	} else {
		return [strings objectAtIndex:string_id];
	}
}

/** Corrects the system language for unsupported things like Euskara.
 * This function checks the user settings and sets the Apple default
 * global system language variable to be the setting if it doesn't
 * exist in the array.
 *
 * The array is only modified if the application language is not
 * in the array. Also, to prevent the new array from being "cached"
 * permanently, remember to remove the array from the preferences
 * before exitting the application. Thanks to the deletion, the next
 * time the application launches the apple languages will be reset
 * to that provided by the OS.
 */
+ (void)fixup_unsupported_languages
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *preferred_langcode = [defaults objectForKey:DEFAULTS_LANGCODE];
	if (preferred_langcode.length > 0 &&
			![preferred_langcode isEqualToString:@"auto"]) {
		NSArray *langs = [defaults objectForKey:DEFAULTS_APPLE_LANGUAGES];
		for (NSString *code in langs) {
			if ([code isEqualToString:preferred_langcode])
				return;
		}

		DLOG(@"Mangling language list to have '%@'.", preferred_langcode);
		/* The list was exhausted, and we didn't find Euskara. Add it then. */
		NSArray *euskara = [NSArray arrayWithObject:preferred_langcode];
		NSArray *final = [euskara arrayByAddingObjectsFromArray:langs];
		[defaults setObject:final forKey:DEFAULTS_APPLE_LANGUAGES];
	}
}

@end

/** Scans all keys in the dictionary converting them to integers.
 * Returns the biggest integer key.
 */
static int _get_max_string_id(NSDictionary *strings)
{
	int max_id = -1;
	assert(strings);
	for (NSString *key in [strings allKeys]) {
		const int key_value = [key intValue];
		max_id = MAX(max_id, key_value);
	}
	return MAX(max_id, STR_LAST);
}

