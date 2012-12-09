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
#import "categories/NSDictionary+Floki.h"

#import "ELHASO.h"

#import "gloss-caustic-shader/UIColor+RRUIKit.h"

@implementation NSDictionary (Floki)

/** Stores an UIColor in the dictionary as array of three RGB integers.
 * You can pass nil, which avoids storing anything.
 */
- (void)setColor:(UIColor*)color forKey:(NSString*)key
{
	if (!color)
		return;

	const int r = [color redComponent] * 255;
	const int g = [color greenComponent] * 255;
	const int b = [color blueComponent] * 255;
	NSNumber *red = [NSNumber numberWithInt:MID(0, r, 255)];
	NSNumber *green = [NSNumber numberWithInt:MID(0, g, 255)];
	NSNumber *blue = [NSNumber numberWithInt:MID(0, b, 255)];
	[self setValue:[NSArray arrayWithObjects:red, green, blue, nil] forKey:key];
}

/** Wrapper over get_string which tries to clean up spaces and stuff.
 * Note that this does NOT a full url encoding, because doing so we would then
 * translate also the path separators, colons, etc. This is pretty much a "try
 * to parse a few bad characters without breaking the rest", since url encoding
 * is not "reentrant".
 *
 * @return Returns the value of the string, as much clean and URL valid as
 * possible.
 */
- (NSString*)get_url:(NSString*)key def:(NSString*)def
{
	NSString *raw_url = [self get_string:key def:def];
	if (!raw_url)
		return def;

	NSString *url = [raw_url stringByTrimmingCharactersInSet:[NSCharacterSet
		whitespaceAndNewlineCharacterSet]];

	const int total_chars = url.length;
	NSMutableString *buf = [NSMutableString stringWithCapacity:total_chars];

	for (int f = 0; f < total_chars; f++) {
		const unichar letter = [url characterAtIndex:f];
		// These are the valid characters we want to preserve unfiltered.
		switch (letter) {
			case ';': [buf appendString:@";"]; break;
			case '/': [buf appendString:@"/"]; break;
			case '?': [buf appendString:@"?"]; break;
			case ':': [buf appendString:@":"]; break;
			case '@': [buf appendString:@"@"]; break;
			case '&': [buf appendString:@"&"]; break;
			case '=': [buf appendString:@"="]; break;
			case '_': [buf appendString:@"_"]; break;
			case '+': [buf appendString:@"+"]; break;
			case '.': [buf appendString:@"."]; break;
			case ',': [buf appendString:@","]; break;
			case '%': [buf appendString:@"%"]; break;
			default:
				// Still, don't filter all chars.
				if ((letter >= '0' && letter <= '9') ||
						(letter >= 'A' && letter <= 'Z') ||
						(letter >= 'a' && letter <= 'z')) {
					[buf appendString:[NSString stringWithCharacters:&letter
						length:1]];
				} else {
					[buf appendFormat:@"%%%x", letter];
				}
				break;
		}
	}
	return buf;
}

@end
