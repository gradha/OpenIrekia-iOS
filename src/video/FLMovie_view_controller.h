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
#import "controllers/FLContent_table_view_controller.h"
#import "protocols/FLTab_protocol.h"


@class FLMovie_cell_data;
@class MPMoviePlayerController;


/** Handles a facade view for a video.
 *
 * Unlike the FLGallery_view_controller or the FLNews_view_controller
 * which handle groups of items, the FLMovie_view_controller handles a
 * single item. The reason is that videos cannot me "manipulated".
 * You need a previous facade screen to allow the user see the
 * description or share the video without actually having to download
 * it.
 *
 * The view will show some preview image and text before loading the movie.
 */
@interface FLMovie_view_controller :
	FLContent_table_view_controller <FLTab_protocol>
{
	/// Stores the generated string for cell reuse. Different on each tab.
	NSString *cell_identifier_;

	/// The movie's URL.
	NSString *url_;

	/// Handler of the movie.
	MPMoviePlayerController *movie_;
	/// View controller for 3.2 iPad and above. Argh... ugly code.
	id movie_controller_;

	/// Stores the state of the view's visibility.
	BOOL is_visible_;
	/// Stores a request to reload the table whenever it becomes visible.
	BOOL queue_reload_;
	/// Remembers if the video did already play once.
	BOOL did_play_once_;

	/// Remembers if we are running on iPad or iOS4 device. Need special code.
	BOOL is_ipad_or_ios4_;
}

/// Set to the URL you would like the user to share, different from main one.
@property (nonatomic, retain) NSString *share_url;

/// Optional property, stores a pointer to an NSNumber with the identifier.
@property (nonatomic, retain) NSNumber *item_id;

/// Common cell attributes, nil until successfull call to init_with_data:
@property (nonatomic, retain) FLMovie_cell_data *cell_data;


- (int)unique_id;
- (void)download_json:(NSString*)url;

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
