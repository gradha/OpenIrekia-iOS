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
#import "video/FLMovie_button_cell.h"

#import "FLi18n.h"
#import "categories/NSString+Floki.h"
#import "controllers/FLContent_view_controller.h"
#import "net/FLMeta_data_connection.h"
#import "structures/FLMovie_cell_data.h"

#import "ELHASO.h"


/// Small subclass to handle custom drawing of cells.
@interface FLMovie_button_cell_view : UIView
@end

@implementation FLMovie_button_cell_view

- (void)drawRect:(CGRect)rect
{
	[(FLMovie_button_cell*)[self superview] drawContentView:rect];
}

@end

// TODO: Move to parent class?
static UIImage *gPlayback;

@implementation FLMovie_button_cell

@synthesize data = data_;

- (id)initWithIdentifier:(NSString *)identifier
{
	return [self initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:identifier];
}

/** This constructors prevents using the code on target 2.0 devices.
 */
- (id)initWithStyle:(UITableViewCellStyle)style
	reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		content_view_ = [[FLMovie_button_cell_view alloc]
			initWithFrame:self.contentView.bounds];
		content_view_.opaque = YES;
		content_view_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
			UIViewAutoresizingFlexibleHeight;
		content_view_.autoresizesSubviews = YES;
		content_view_.contentMode = UIViewContentModeRedraw;
		[self addSubview:content_view_];
		[content_view_ release];

		// TODO: Move to parent class?
		if (!gPlayback)
			gPlayback = [[UIImage imageNamed:@"playback.png"] retain];

		// Create view for playback overlay and activity indicator.
		play_view_ = [[UIImageView alloc] initWithImage:gPlayback];
		[self addSubview:play_view_];
		activity_indicator_ = [[UIActivityIndicatorView alloc]
			initWithActivityIndicatorStyle:
				UIActivityIndicatorViewStyleWhiteLarge];
		[self addSubview:activity_indicator_];
	}
	return self;
}

- (void)dealloc
{
	[thumb_connection_ cancel];
	[thumb_connection_ release];
	thumb_connection_ = nil;
	[play_view_ release];
	[image_ release];
	[activity_indicator_ release];
	[data_ release];
	[super dealloc];
}

/** Sets the data for the cell.
 * This will generate a network connection to retrieve the preview thumbnail.
 */
- (void)setData:(FLMovie_cell_data*)data
{
	if (data == self.data)
		return;

	[thumb_connection_ cancel];
	[image_ release];
	image_ = nil;
	[data retain];
	[data_ release];
	data_ = data;

	if (self.data.preview_url) {
		if (!thumb_connection_)
			thumb_connection_ = [[FLCached_connection alloc]
				init_with_action:@selector(did_receive_image:error:)
				target:self];

		NSString *pretty_url = [FLContent_view_controller
			prettify_request_url:data.preview_url];
		[thumb_connection_ request:pretty_url cache_token:6666666];
	}

	[self setNeedsDisplay];
}

/** Handles reception of image from the net.
 * An UIImage will be created with the response data. If the UIImage can't be
 * created or the data ara corrupted, a broken icon will be shown instead.
 */
- (void)did_receive_image:(id)response error:(NSError*)error
{
	LASSERT(self.data, @"Invalid internal pointers");
	if (error || !self.data)
		DLOG(@"Error receiving image: %@", error);
	else
		image_ = [[FLMeta_data_connection data_to_image:[response data]
			size:CGSizeMake(self.data->preview_width, self.data->preview_height)
			proportional:YES] retain];

	/* Just in case, set broken image if nothing really came out. */
	if (!image_)
		image_ = [[UIImage imageNamed:@"Broken-icon.png"] retain];

	LASSERT([image_ isKindOfClass:[UIImage class]], @"Bad image object?");
	[self setNeedsDisplay];
}

/** Special handler method because of drawContentView and inheritance.
 * Forces a refresh of our custom view.
 */
- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[content_view_ setNeedsDisplay];
}

/** Returns the height that will be used for the cell content. */
+ (CGFloat)height_for_text:(FLMovie_cell_data*)data
{
	return 4 + data->preview_height;
}

/** Special method that draws the custom cell content.
 * An image is drawn to the left, or a special in-progress loading
 * icon. Text is recalculated to the width of the cell, which supports
 * portrait and landscape modes.
 */
- (void)drawContentView:(CGRect)cell_rect
{
	LASSERT(self.data, @"Bad pointers");
	CGContextRef context = UIGraphicsGetCurrentContext();

	if (play_view_.hidden)
		[self.data.playback_color set];
	else
		[self.data.back_color set];
	CGContextFillRect(context, cell_rect);

	/* Draw the thumbnail. */
	const CGFloat x = (cell_rect.size.width - self.data->preview_width) / 2.0f;
	CGRect dest = CGRectMake(x, 2,
		self.data->preview_width, self.data->preview_height);

	if (image_) {
		[image_ drawInRect:dest];
	} else {
		// Draw the default empty
		[[UIColor grayColor] set];
		CGContextFillRect(context, dest);
		CGRect inner_dest = dest;
		inner_dest.origin.x += 2;
		inner_dest.origin.y += 2;
		inner_dest.size.width -= 4;
		inner_dest.size.height -= 4;
		[[UIColor whiteColor] set];
		CGContextFillRect(context, inner_dest);
	}

	/* Recalculate the position and size of the overlays */
	float w = gPlayback.size.width;
	float h = gPlayback.size.height;

	if (w > self.data->preview_width) {
		const float factor = self.data->preview_width / w;
		w *= factor;
		h *= factor;
	}

	if (h > self.data->preview_height) {
		const float factor = self.data->preview_height / h;
		w *= factor;
		h *= factor;
	}
	dest.origin.x += (int)((dest.size.width - w) / 2.0f);
	dest.origin.y += (int)((dest.size.height - h) / 2.0f);
	dest.size.width = w;
	dest.size.height = h;
	play_view_.frame = dest;

	// Now recalculate the position of the activity indicator.
	dest = activity_indicator_.frame;
	dest.origin.x = x + (self.data->preview_width - dest.size.width) / 2.0f;
	dest.origin.y = 2 + (self.data->preview_height - dest.size.height) / 2.0f;
	activity_indicator_.frame = dest;
}

/** Call this to show that the user is starting video playback.
 * The activity indicator starts animating and the play button disappears.
 */
- (void)start
{
	[activity_indicator_ startAnimating];
	play_view_.hidden = YES;
	[self setNeedsDisplay];
}

/** Call this to show that the video playback finished.
 * The activity indicator stops animating and the play button reappears.
 */
- (void)stop
{
	[activity_indicator_ stopAnimating];
	play_view_.hidden = NO;
	[self setNeedsDisplay];
}

- (NSString*)accessibilityLabel
{
	if (!self.data)
		return nil;

	return _e(29);
	// _29: Play video
}

@end
