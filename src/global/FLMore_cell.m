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
#import "global/FLMore_cell.h"

#import "global/FLi18n.h"
#import "models/FLMore_item.h"

#import "ELHASO.h"
#import "UIActivity.h"
#import "UIColor+RRUIKit.h"

#define _PADDING			10

@implementation FLMore_cell

@synthesize label = label_;

/// Add our own widgets to the cell.
- (id)initWithStyle:(UITableViewCellStyle)style
	reuseIdentifier:(NSString *)reuseIdentifier
{
	if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
		return nil;

	// White background cell.
	content_view_.backgroundColor = [UIColor whiteColor];

	// Create activity spinner, by default not active.
	activity_ = [[UIActivity get_gray] retain];
	activity_.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	activity_.contentMode = UIViewContentModeCenter;
	CGRect rect = activity_.bounds;
	rect.size.width += _PADDING * 2;
	rect.size.height = content_view_.bounds.size.height;
	activity_.frame = rect;
	[content_view_ addSubview:activity_];

	// Reduce the rectangle to the rest of the cell.
	rect.origin.x = rect.size.width;
	rect.size.width = content_view_.bounds.size.width - rect.origin.x;

	// Create text label.
	UILabel *label = [[UILabel alloc] initWithFrame:rect];
	label.autoresizingMask = FLEXIBLE_SIZE;
	label.numberOfLines = 0;
	label.backgroundColor = [UIColor clearColor];
	[content_view_ addSubview:label];
	self.label = label;
	[label release];

	// Set the interface as if the cell was stopped, waiting for interaction.
	[self stop];

	return self;
}

- (void)dealloc
{
	[activity_ release];
	[label_ release];
	[super dealloc];
}

/// Don't use fast drawing, let UIKit do it for us.
- (void)draw_content:(CGRect)rect
{
	[self drawRect:rect];
}

/// Stops the animation and changes the text to "get more items".
- (void)stop
{
	[activity_ stopAnimating];
	self.label.text = _e(35);
	// _35: Get more...
}

/// Starts the animation and changes the text to "downloading".
- (void)start
{
	[activity_ startAnimating];
	self.label.text = _e(36);
	// _36: Downloading data
}

/// Returns the state of the animating spinner.
- (BOOL)isAnimating
{
	return [activity_ isAnimating];
}

/** Updates a cell from the logical state of a "more" item.
 * The state might be working, or stopped, dislaying possibly an error message.
 * Usually you call this method when restoring a cell for a tableview.
 */
- (void)update_state_from:(FLMore_item*)item
{
	RASSERT([item isKindOfClass:[FLMore_item class]], @"Bad type!", return);
	if (item.is_working) {
		[self start];
	} else {
		[self stop];
		// If the cell is stopped, see if we have to display any message.
		if (item.title.length)
			self.label.text = item.title;
	}
}

/** Sets the colors for the cell.
 * The color of the text label will be chosen automatically as white or black
 * depending on the background color, to stand out. The highlight_color is
 * optional and can be nil. If not nil, the selection of the cell will show a
 * solid color rather than the usual system blue gradient.
 */
- (void)set_background_color:(UIColor*)background_color
	highlight_color:(UIColor*)highlight_color
{
	RASSERT(background_color, @"Invalid nil parameter", return);
	content_view_.backgroundColor = background_color;
	content_view_.opaque = YES;

	if (background_color.redComponent > 0.5f) {
		self.label.textColor = [UIColor blackColor];
	} else {
		self.label.textColor = [UIColor whiteColor];
		// Replace the activity widget with a white one.
		UIActivity *activity = [[UIActivity get_white] retain];
		activity.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		activity.contentMode = UIViewContentModeCenter;
		activity.frame = activity_.frame;
		UNLOAD_VIEW(activity_);
		[content_view_ addSubview:activity];
		activity_ = activity;
	}

	if (highlight_color) {
		// By default create a transparent selected background view.
		UIView *view = [[UIView alloc] initWithFrame:self.bounds];
		view.opaque = YES;
		view.backgroundColor = highlight_color;
		self.selectedBackgroundView = view;
		[view release];
	} else {
		self.selectedBackgroundView = nil;
	}
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
