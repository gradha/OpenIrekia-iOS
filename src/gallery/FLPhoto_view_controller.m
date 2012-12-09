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
#import "gallery/FLPhoto_view_controller.h"

#import "models/FLGallery_item.h"
#import "global/FLi18n.h"

#import "ELHASO.h"


@interface FLPhoto_view_controller ()
- (void)set_image:(UIImage*)image;
- (void)reposition_activity_indicator;
- (void)center_image_after_scroll;
@end

/** Special wrapper class to avoid strange frame positioning.
 * Just like in the FLCentered_scroll_view setFrame method, this class also
 * suffers from 'magical' frame resetting calls. Just after the controller is
 * being pushed on the navigation the frame is reset to the screen size, which
 * is good for many cases/controllers, but not ours.
 *
 * So we override the normal view with this class to force a specific rectangle
 * positioning, specified by the FLPhoto_view_controller::resize_frame method.
 */
@interface FLStatic_view : UIView
{
@public
	CGRect *true_frame;
}
@end

@implementation FLStatic_view

// Overrides the call rect with our pointer to a rect if available.
- (void)setFrame:(CGRect)rect
{
	if (true_frame)
		rect = *true_frame;
	[super setFrame:rect];
}

@end


@implementation FLPhoto_view_controller

@synthesize item = item_;

/** Handles creation of the view, pseudo constructor.
 */
- (void)loadView
{
	[super loadView];

	// Replace the view with our static version.
	FLStatic_view *w = [[FLStatic_view alloc] initWithFrame:self.view.frame];
	self.view = w;
	w->true_frame = &pos_rect_;
	[w release];

	/* Create scroll view... */
	scroll_view_ = [FLCentered_scroll_view new];
	scroll_view_.backgroundColor = [UIColor blackColor];
	CGRect rect = CGRectZero;
	rect.size = [self get_visible_area];
	scroll_view_.frame = rect;
	scroll_view_.scrollEnabled = YES;
	scroll_view_.bouncesZoom = YES;
	scroll_view_.scrollsToTop = NO;
	scroll_view_.maximumZoomScale = 2;
	scroll_view_.showsHorizontalScrollIndicator = NO;
	scroll_view_.showsVerticalScrollIndicator = NO;
	scroll_view_.multipleTouchEnabled = YES;
	[self.view insertSubview:scroll_view_ atIndex:0];
}

- (void)dealloc
{
	scroll_view_.tap_delegate = nil;
	scroll_view_.delegate = nil;
	[scroll_view_ release];
	[item_ release];
	[super dealloc];
}

/** Sets the item and starts a download fetch. */
- (void)setItem:(FLGallery_item*)item
{
	LASSERT(self.base_url, @"Base url not initialised");
	LASSERT(self.cache_token, @"db_cache not initialised");

	UIView *v = self.view; // Hack to force loading of the view. Ugly!
	v = nil;

	if (item_ == item)
		return;

	[item retain];
	[item_ release];
	item_ = item;
	[self set_image:nil];

	[self download_content:item selector:@selector(did_receive_url:error:)
		target:self cache_type:CACHE_CONTENT cache_tables:GALLERY_CACHE_TABLES
		force:NO];
	//DLOG(@"Setting zoom to %0.4f", scroll_view_.minimumZoomScale);
	scroll_view_.zoomScale = scroll_view_.minimumZoomScale;
}

/** Changes the scrollable content to the specified view.
 * You can pass nil to prepare the image view holding the future
 * image. The size of the new image view will be forced to what self.item
 * holds as width/height.
 */
- (void)set_image:(UIImage*)image
{
	LASSERT(scroll_view_, @"Internal error");

	if (image && self.item && (self.item.width != image.size.width ||
			self.item.height != image.size.height)) {
		image = [FLMeta_data_connection scale_image:image
			size:CGSizeMake(self.item.width, self.item.height) proportional:NO];
		LASSERT(image, @"Bad conversion");
	}

	UIImageView *view = (UIImageView*)scroll_view_.content_view;
	if (!view && self.item) {
		scroll_view_.delegate = self;
		scroll_view_.tap_delegate = self;
		scroll_view_.contentSize =
			CGSizeMake(self.item.width, self.item.height);

		image_view_ = [[UIImageView alloc] initWithImage:image];
		if (!image)
			image_view_.frame = CGRectMake(0, 0,
				self.item.width, self.item.height);
		scroll_view_.content_view = image_view_;
		[image_view_ release];
	} else {
		view.image = image;
	}

	[self reposition_activity_indicator];
	[self center_image_after_scroll];

	// Reset the maximum scale based on the minimum one, which
	// was somehow set magically by the UIScrollView.
	if (self.item) {
		LASSERT(self.item.max_zoom >= 1, @"Bad maximum zoom factor");
		scroll_view_.maximumZoomScale =
			scroll_view_.minimumZoomScale * self.item.max_zoom;
	}
}

/** Recalculates the sizes of the frames.
 * The parent method will reposition the frame of the activity
 * indicator. At this level we will update the zoom levels. If this
 * is the first time of the calculation, the zoom level will be forced
 * to the minimum, so the user sees the full picture.
 *
 * The function is called several times, and if the minimum scroll
 * is decreased from a previous moment, the current zoom is also
 * scaled to that level.
 */
- (void)reposition_activity_indicator
{
	if (!self.item)
		return;

	/* I hate this shit about views not being loaded... */
	CGRect rect = CGRectZero;
	rect.size = [self get_visible_area];
	//scroll_view_.frame = rect;

	const CGSize target_size = scroll_view_.bounds.size;
	//DLOG(@"Using target size %0.2f,%0.2f", target_size.width, target_size.height);

	CGSize size = { self.item.width, self.item.height };
	CGFloat factor = target_size.width / size.width;
	size.width *= factor;
	size.height *= factor;

	if (size.height > target_size.height) {
		factor = target_size.height / size.height;
		size.width *= factor;
		size.height *= factor;
	}
	const CGFloat scale_w = size.width / (float)self.item.width;
	const CGFloat scale_h = size.height / (float)self.item.height;
	const CGFloat final = MIN(scale_w, scale_h);

	//DLOG(@"Was %0.4f, will be %0.4f", scroll_view_.minimumZoomScale, final);
	if (final < scroll_view_.minimumZoomScale) {
		scroll_view_.minimumZoomScale = final;
	} else {
		scroll_view_.minimumZoomScale = final;
#if 0
		This used to be necessary in the early stages of
		development. However, it doesn't seem to be useful
		now, and it breaks paging when new images are being
		loaded in the background, so let's disable it.
		/* Just in case, don't let ourselves be zoomed out of the minimum. */
		if (scroll_view_.zoomScale < scroll_view_.minimumZoomScale) {
			DLOG(@"brak Setting zoom to %0.4f", final);
			[scroll_view_ setZoomScale:scroll_view_.minimumZoomScale
				animated:YES];
		}
#endif
	}

	[super reposition_activity_indicator];
}

/** Modifies the frame of the zoomed content, and also zooms out to it.
 * Use this method instead of setting the frame. If you only set
 * the frame after a landscape reorientation, for instance, you will
 * notice that the zoom levels are not good.
 *
 * This method will reset the zoom level to zoom out the image.
 */
- (void)resize_frame:(CGRect)rect
{
	pos_rect_ = rect;
	self.view.frame = rect;
	rect.origin.x = rect.origin.y = 0;
	scroll_view_.frame = rect;
	[self reposition_activity_indicator];
	scroll_view_.zoomScale = scroll_view_.minimumZoomScale;
}

#pragma mark Network connection handler

- (void)did_receive_url:(FLMeta_data_connection*)response error:(NSError*)error
{
	UIImage *image = nil;
	if (error) {
		[self show_error:_e(21) error:error];
		// _21: Connection error
	} else
		image = [UIImage imageWithData:[response data]];

	if (!image)
		image = [UIImage imageNamed:@"Broken-icon.png"];

	[activity_indicator_ stopAnimating];
	[self set_image:image];
}

#pragma mark UIScrollViewDelegate protocol

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return image_view_;
}

/** Method for 3.2 and above.
 * Doesn't hurt to implement it. Makes sure that zooming out still
 * shows correctly the image. Previous firmware versions have to suck
 * it up and wait until scrollViewDidEndZooming is called.
 */
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	[self center_image_after_scroll];
}

/** Called when the user finished doing a zoom action.
 * Calculates the visible rect and makes it fit inside the screen.
 */
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
	withView:(UIView *)view atScale:(float)scale
{
	/* These two lines are to work around a bug in zoomToRect:animated:. */
	[scrollView setZoomScale:scale+0.01 animated:NO];
	[scrollView setZoomScale:scale animated:NO];

	[self center_image_after_scroll];
}

- (void)center_image_after_scroll
{
	const CGSize screen = scroll_view_.frame.size;

	CGPoint offset = scroll_view_.contentOffset;
	BOOL reset = NO;

	/* Check if we are getting outside of the top left corner of the content. */
	if (offset.x < 0) {
		offset.x = 0;
		reset = YES;
	}

	if (offset.y < 0) {
		offset.y = 0;
		reset = YES;
	}

	/* Same check for the bottom right corner. */
	const CGFloat scale = scroll_view_.zoomScale;
	const CGFloat out_w = self.item.width * scale - (offset.x + screen.width);
	if (out_w < 0) {
		offset.x += out_w;
		reset = YES;
	}

	const CGFloat out_h = self.item.height * scale - (offset.y + screen.height);
	if (out_h < 0) {
		offset.y += out_h;
		reset = YES;
	}

	if (reset)
		scroll_view_.contentOffset = offset;
}

#pragma mark Tapping delegates

/** Set a single tap handler.
 * This allows a parent class, for instance, to be notified whenever
 * a single tap happens. This could be used for example to toggle the
 * hud translucency on/off.
 */
- (void)set_tap_handler:(id)object selector:(SEL)selector
{
	tap_handler_ = object;
	tap_selector_ = selector;
}

- (void)tapDetectingImageView:(FLCentered_scroll_view *)view
	gotSingleTapAtPoint:(CGPoint)tapPoint;
{
	if (tap_handler_ && tap_selector_)
		[tap_handler_ performSelector:tap_selector_ withObject:self];
}

- (void)tapDetectingImageView:(FLCentered_scroll_view *)view
	gotDoubleTapAtPoint:(CGPoint)tap_point
{
	LASSERT(self.item, @"Bad internal pointer");
	const CGFloat scale = scroll_view_.zoomScale;
	/* Calculate the zoom threshold to know if we have to zoom in or out. */
	const CGFloat threshold = scroll_view_.minimumZoomScale + 0.5 *
		(scroll_view_.maximumZoomScale - scroll_view_.minimumZoomScale);

	/* By default zoom out. */
	CGRect rect = { 0, 0, self.item.width, self.item.height };

	if (scale < threshold) {
		LASSERT(self.item.max_zoom >= 1, @"Bad maximum zoom factor");
		/* Zooming in, create zoomed rect... */
		rect.size.width = self.item.width / self.item.max_zoom;
		rect.size.height = self.item.height / self.item.max_zoom;
		rect.origin.x = tap_point.x - rect.size.width / 2.0f;
		rect.origin.y = tap_point.y - rect.size.height / 2.0f;

		/* Force rectangle to fit inside image area. */
		if (rect.origin.x < 0) rect.origin.x = 0;
		if (rect.origin.y < 0) rect.origin.y = 0;
		if (rect.origin.x + rect.size.width > self.item.width)
			rect.origin.x = self.item.width - rect.size.width;
		if (rect.origin.y + rect.size.height > self.item.height)
			rect.origin.y = self.item.height - rect.size.height;
	}
	[scroll_view_ zoomToRect:rect animated:YES];
}

@end
