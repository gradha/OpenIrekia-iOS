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
@class FLCentered_scroll_view;

/// Protocol for the tap-detecting image view's delegate.
@protocol FLTap_delegate <NSObject>

@optional
- (void)tapDetectingImageView:(FLCentered_scroll_view *)view gotSingleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingImageView:(FLCentered_scroll_view *)view gotDoubleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingImageView:(FLCentered_scroll_view *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint;

@end

/** Tricky hack to have images center in the middle.
 *
 * Comes from https://devforums.apple.com/message/9501#9501
 * At some point this should be ditched and replaced by other open
 * source photo viewers available which don't have a zooming in/out
 * stutter. Or review that thread to see if there are new solutions.
 */
@interface FLCentered_scroll_view : UIScrollView
{
	/// Needed to record location of single tap, which will only
	/// be registered after delayed perform.
	CGPoint tapLocation;         
	/// YES if a touch event contains more than one touch; reset
	/// when all fingers are lifted.
	BOOL multipleTouches;        
	/// Set to NO when 2-finger tap can be ruled out (e.g. 3rd
	/// finger down, fingers touch down too far apart, etc).
	BOOL twoFingerTapIsPossible;
}

/// The actual view for the centered scroll.
@property (nonatomic, retain) UIView *content_view;
/// Delegate handling the taps for the view.
@property (nonatomic, assign) id <FLTap_delegate> tap_delegate;

@end

