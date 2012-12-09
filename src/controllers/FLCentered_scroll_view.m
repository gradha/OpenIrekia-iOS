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
#import "FLCentered_scroll_view.h"

#import "ELHASO.h"

#define DOUBLE_TAP_DELAY 0.35

static CGPoint midpointBetweenPoints(CGPoint a, CGPoint b);

@interface FLCentered_scroll_view ()
- (void)handleSingleTap;
- (void)handleDoubleTap;
- (void)handleTwoFingerTap;
@end

@implementation FLCentered_scroll_view

@synthesize content_view = content_view_;
@synthesize tap_delegate = tap_delegate_;

- (void)dealloc
{
	self.content_view = nil;
	[super dealloc];
}

- (void)setContent_view:(UIView*)view
{
	if (content_view_ == view)
		return;

	[content_view_ removeFromSuperview];
	[content_view_ release];
	content_view_ = [view retain];
	if (content_view_)
		[self addSubview:content_view_];
}

/** Sets the frame.
 * Actually, for the iPad version there seems to be "sometimes" a
 * rounding error by some internal UIKit classes which set the frame
 * width to the correct width +/- one pixel. This makes the scroll
 * look like shit when you go to an advanced item, because every item
 * more you go to the end, the scroll gets more offseted.
 * I'm really sure that it's because I'm doing something really
 * wrong, Apple engineers never commit mistakes. Well, at least on
 * the iPhone the scrolling never gets weird, so I wonder what they
 * did with the iPad.
 */
- (void)setFrame:(CGRect)r
{
	if (IS_IPAD) {
		int test = r.size.width;
		if (test % 2) {
			DLOG(@"Avoiding odd frame size %0.0fx%0.0f",
				r.size.width, r.size.height);
			return;
		}
		test = r.size.height;
		if (test % 2) {
			DLOG(@"Avoiding odd frame size %0.0fx%0.0f",
				r.size.width, r.size.height);
			return;
		}
	}

	[super setFrame:r];
}

- (void)setContentOffset:(CGPoint)p
{
	if (content_view_) {
		const CGSize viewSize = content_view_.frame.size;
		const CGSize scrollSize = self.bounds.size;

		if (viewSize.width < scrollSize.width)
			p.x = -(scrollSize.width - viewSize.width) / 2.0;

		if (viewSize.height < scrollSize.height)
			p.y = -(scrollSize.height - viewSize.height) / 2.0;
	}
	super.contentOffset = p;
}

#pragma mark Coming from Apple's scroll tab example

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// cancel any pending handleSingleTap messages
	[NSObject cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(handleSingleTap) object:nil];

	// update our touch state
	if ([[event touchesForView:self] count] > 1)
		multipleTouches = YES;
	if ([[event touchesForView:self] count] > 2)
		twoFingerTapIsPossible = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	BOOL allTouchesEnded =
		([touches count] == [[event touchesForView:self] count]);

	// first check for plain single/double tap, which is only
	// possible if we haven't seen multiple touches
	if (!multipleTouches) {
		UITouch *touch = [touches anyObject];
		tapLocation = [touch locationInView:content_view_];

		if ([touch tapCount] == 1) {
			[self performSelector:@selector(handleSingleTap) withObject:nil
				afterDelay:DOUBLE_TAP_DELAY];
		} else if([touch tapCount] == 2) {
			[self handleDoubleTap];
		}
	}

	// check for 2-finger tap if we've seen multiple touches
	// and haven't yet ruled out that possibility
	else if (multipleTouches && twoFingerTapIsPossible) {

		// case 1: this is the end of both touches at once
		if ([touches count] == 2 && allTouchesEnded) {
			int i = 0;
			int tapCounts[2]; CGPoint tapLocations[2];
			for (UITouch *touch in touches) {
				tapCounts[i] = [touch tapCount];
				tapLocations[i] = [touch locationInView:content_view_];
				i++;
			}
			if (tapCounts[0] == 1 && tapCounts[1] == 1) {
				// it's a two-finger tap if they're both single taps
				tapLocation = midpointBetweenPoints(tapLocations[0],
					tapLocations[1]);
				[self handleTwoFingerTap];
			}
		}

		// case 2: this is the end of one touch, and the other hasn't ended yet
		else if ([touches count] == 1 && !allTouchesEnded) {
			UITouch *touch = [touches anyObject];
			if ([touch tapCount] == 1) {
				// if touch is a single tap, store
				// its location so we can average it
				// with the second touch location
				tapLocation = [touch locationInView:content_view_];
			} else {
				twoFingerTapIsPossible = NO;
			}
		}

		// case 3: this is the end of the second of the two touches
		else if ([touches count] == 1 && allTouchesEnded) {
			UITouch *touch = [touches anyObject];
			if ([touch tapCount] == 1) {
				// if the last touch up is a single
				// tap, this was a 2-finger tap
				tapLocation = midpointBetweenPoints(tapLocation,
					[touch locationInView:content_view_]);
				[self handleTwoFingerTap];
			}
		}
	}

	// if all touches are up, reset touch monitoring state
	if (allTouchesEnded) {
		twoFingerTapIsPossible = YES;
		multipleTouches = NO;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	twoFingerTapIsPossible = YES;
	multipleTouches = NO;
}

#pragma mark Private

- (void)handleSingleTap
{
	if ([tap_delegate_ respondsToSelector:
			@selector(tapDetectingImageView:gotSingleTapAtPoint:)]) {

		[tap_delegate_ tapDetectingImageView:self
			gotSingleTapAtPoint:tapLocation];
	}
}

- (void)handleDoubleTap
{
	if ([tap_delegate_ respondsToSelector:
		@selector(tapDetectingImageView:gotDoubleTapAtPoint:)]) {

		[tap_delegate_ tapDetectingImageView:self
			gotDoubleTapAtPoint:tapLocation];
	}
}

- (void)handleTwoFingerTap
{
	if ([tap_delegate_ respondsToSelector:
			@selector(tapDetectingImageView:gotTwoFingerTapAtPoint:)]) {

		[tap_delegate_ tapDetectingImageView:self
			gotTwoFingerTapAtPoint:tapLocation];
	}
}

static CGPoint midpointBetweenPoints(CGPoint a, CGPoint b)
{
	CGFloat x = (a.x + b.x) / 2.0;
	CGFloat y = (a.y + b.y) / 2.0;
	return CGPointMake(x, y);
}

@end
