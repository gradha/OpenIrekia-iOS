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
#import "global/settings.h"

#import "ELHASO.h"

BOOL gSlash_scaled_images = NO;

// Put here the default beacon URL for release distribution.
static NSString *BEACON_URL = @"http://www.irekia.euskadi.net/mob_app/2";

/** Returns and resets the last viewed identifier value.
 * When the application exists, it asks the tabs to save the last
 * viewed item and store it in the LAST_VIEWED_ID user defaults
 * settings. In order to restore the item, when the application is
 * run again, control is passed to the last used tab and it can read
 * the value.
 *
 * However, this value should be resetted because otherwise opening
 * another tab would cause the value to still be reread, and tabs
 * could have similar or equal identifiers.
 *
 * Therefore this function has the sideeffect of resettiing the
 * last viewed id as well as returning it. The default reset value
 * is negative, which according to application protocols nothing
 * should be using it.
 */
int read_and_reset_last_viewed_id(void)
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	const int ret = [defaults integerForKey:LAST_VIEWED_ID];
	[defaults setInteger:-1 forKey:LAST_VIEWED_ID];
	return ret;
}

/** Returns the device identifier according to the server protocol.
 * The devide identifier is a default number of zero. But it can
 * be a different value for different hardware, like 1 for the iPad
 * and 2 for the iPhone 4. Note that this device identifier doesn't
 * necessarily match a type of hardware or software. It simply
 * differentiates client necessities with regards to served content.
 * Two hardware devices may request different values depending on the
 * settings of the device, for example.
 *
 * The result is cached since it can't change during runtime, so
 * the call should be most of the time pretty fast.
 */
int get_device_identifier(void)
{
	static int device = 0;
	static BOOL virgin = YES;
	if (!virgin)
		return device;

	virgin = NO;
	if (IS_IPAD) {
		device = 1;
		return device;
	}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	/* Check if we are on an iPhone 4 doubled resolution. */
	UIScreen *screen = [UIScreen mainScreen];
	if ([screen respondsToSelector:@selector(scale)]) {
		if ([screen scale] > 1)
			device = 2;
	}
#endif

	return device;
}

/** Returns false if the current and previously used beacons are the same.
 * This is usually checked to see if the user changed the host
 * setting in the preferences.
 */
BOOL did_beacon_url_change(void)
{
	NSString *beacon_url = get_beacon_url();
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *last_url = [defaults stringForKey:LAST_BEACON_URL];

	return ![beacon_url isEqualToString:last_url];
}

/** Returns the currently active beacon URL.
 * If the settings bundle doesn't contain any, returns hardcoded BEACON_URL.
 */
NSString *get_beacon_url(void)
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *url = [defaults stringForKey:DEFAULTS_BEACON_URL];
	if (url && url.length > 0)
		return url;
	else
		return BEACON_URL;
}

/** Small wrapper around get_beacon_url(), returns only the host name.
 * The host is taken from the currently active host according to
 * the user preferences.
 */
NSString *get_reachability_host(void)
{
	return [[NSURL URLWithString:get_beacon_url()] host];
}

// vim:tabstop=4 shiftwidth=4 syntax=objc
