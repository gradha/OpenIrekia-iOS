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
#import <Foundation/Foundation.h>

/** \file FLi18n.h
 * Internationalization.
 */

/// Possible values for the system string runtime identifiers.
enum SYS_STR_ENUM
{
	STR_FIRST = 9999,
	STR_NEWS_SHARING_TITLE,
	STR_PICTURE_SHARING_TITLE,
	STR_COPY_TO_CLIPBOARD,
	STR_SEND_EMAIL,
	STR_CANCEL_ACTION,
	STR_MAIL_NEWS_SUBJECT,
	STR_MAIL_PICTURE_SUBJECT,
	STR_MAIL_NEWS_BODY,
	STR_MAIL_PICTURE_BODY,
	STR_MAIL_PICTURE_BODY_DESC,
	STR_MOVIE_SHARING_TITLE,
	STR_MAIL_MOVIE_SUBJECT,
	STR_MAIL_MOVIE_BODY,
	STR_TWITTER_BUTTON,
	STR_FACEBOOK_BUTTON,
	STR_BROWSE_IPAD_SECTIONS,
	STR_IPAD_SECTION_BUTTON,
	STR_LAST,
};
/// Required alias for enum.
typedef enum SYS_STR_ENUM SYS_STR;

/** Internationalization functions, runtime and static.
 *
 * Supports runtime localization changes through network updates
 * through the _() and _s() macros. Embedded string internationalization,
 * that for strings that have to be shown before any text is loaded
 * at runtime can be accessed through the _e() macro.
 */
@interface FLi18n : NSObject
{
	NSArray *strings_;
	NSString *code_;
}

- (id)init_with_langs:(NSArray*)json_data;
- (NSString*)string_by_number:(int)string_id;
- (NSString*)string_by_string:(NSString*)number;
- (NSString*)current_langcode;

+ (FLi18n*)get;
+ (void)set:(FLi18n*)langs;
+ (BOOL)did_last_used_language_change;
+ (NSString*)embeded_string:(int)string_id;
+ (void)fixup_unsupported_languages;

@end

/* Helpers to type less. */
/// Retrieves a runtime string by number. See FLi18n::string_by_number:.
#define _(NUM)		[[FLi18n get] string_by_number:NUM]
/// Retrieves a runtime string by string. See FLi18n::string_by_string:.
#define _s(NUM)		[[FLi18n get] string_by_string:NUM]
/// Retrieves an embedded string by number. See FLi18n::embeded_string:.
#define _e(NUM)		[FLi18n embeded_string:NUM]

/// Accessibility macro to set the current langcode. Backwards compatible.
#define SET_ACCESSIBILITY_LANGUAGE(VAR) do { \
	if ([VAR respondsToSelector:@selector(setAccessibilityLanguage:)]) \
		VAR.accessibilityLanguage = [[FLi18n get] current_langcode]; \
} while (0)

/// Accessibility macro to set the label. Backwards compatible.
#define SET_ACCESSIBILITY_LABEL(VAR, TEXT) do { \
	if ([VAR respondsToSelector:@selector(setAccessibilityLabel:)]) \
		VAR.accessibilityLabel = TEXT; \
} while (0)
