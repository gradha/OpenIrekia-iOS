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
/* Constants to access NSUserDefaults dictionary.
 * These should be the same as in the settings package.
 */
#define DEFAULTS_APPLE_LANGUAGES			@"AppleLanguages"
#define DEFAULTS_BEACON_URL					@"beacon_url"
#define DEFAULTS_CACHE_SIZE					@"cache_size"
#define DEFAULTS_CLEAR_CACHE_ON_BOOT		@"clear_cache_on_boot"
#define DEFAULTS_LANGCODE					@"lang"
#define LAST_BEACON_URL						@"last_beacon_url"
#define LAST_DEVICE_ID						@"last_device_id"
#define LAST_LANGCODE						@"last_lang"
#define LAST_TAB							@"last_tab"
#define LAST_VERSION						@"last_run_version"
#define LAST_VIEWED_ID						@"last_viewed_id"

/* Turned on for debugging purposes. See application protocol. */
extern BOOL gSlash_scaled_images;

int read_and_reset_last_viewed_id(void);
int get_device_identifier(void);
BOOL did_beacon_url_change(void);
NSString *get_beacon_url(void);
NSString *get_reachability_host(void);

// vim:tabstop=4 shiftwidth=4 syntax=objc
