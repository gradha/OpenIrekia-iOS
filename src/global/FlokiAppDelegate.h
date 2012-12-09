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
@class FLBootstrap_controller;
@class FLDB;
@class FLISplit_view_controller;
@class FLRemote_connection;
@class FLTab_controller;
@class FLRegex_match;
@class NSThread;

/** Application delegate
 *
 * Only used to instantiate the main window view and create the
 * FLTab_controller class that will handle the navigation controllers
 * for each tab.
 */
@interface FlokiAppDelegate : NSObject
	<UIApplicationDelegate, UIAlertViewDelegate>
{
	/// Split controler view for the ipad only. Nil in other platforms.
	FLISplit_view_controller *split_view_;

	/// Set to true if you want the next UIAlertView to exit the program.
	BOOL abort_after_alert_;

	/// Stores the connection object used to retrieve the application protocol.
	FLRemote_connection *connection_;

	/// Simple sentinel, used by connection functions to avoid reinitialisation.
	BOOL app_is_initialised_;

	/// Temporary holder of the beacon JSON string for the application.
	NSString *beacon_string_;

	/// In memory value of the beacon cached version.
	int beacon_cached_version_;

	/// Stores if we are alive or our background threads should die.
	BOOL background_thread_alive_;
}

/// Window object for the application.
@property (nonatomic, retain) UIWindow *window;

/// Pointer to the global database access object.
@property (nonatomic, retain) FLDB *db;

/// Pointer to the reachability alert, we might need to close it.
@property (nonatomic, retain) UIAlertView *reachability_alert;

/// Counts the number of network threads, for the global activity stuff.
@property (nonatomic, assign) int active_downloads;

/// Root class controlling the application tab interface.
@property (nonatomic, retain) FLTab_controller *tab_controller;


+ (UIViewController*)spawn_tag_controller:(FLRegex_match*)match;
+ (UIViewController*)spawn_video_controller:(FLRegex_match*)match;
+ (UIViewController*)spawn_gallery_controller:(FLRegex_match*)match;

@end

extern NSThread *serial_background_thread;

Class FLClassFromString(NSString *class_name);
