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
#import "news/FLNews_cell.h"

#import "FLi18n.h"
#import "categories/NSString+Floki.h"
#import "controllers/FLContent_view_controller.h"
#import "models/FLNews_item.h"
#import "net/FLMeta_data_connection.h"
#import "structures/FLNews_cell_data.h"

#import "ELHASO.h"


#define _SCROLLBAR_SPACE			7


/// Small subclass to handle custom drawing of cells.
@interface FLNews_cell_view : UIView
@end

@implementation FLNews_cell_view

- (void)drawRect:(CGRect)rect
{
	[(FLNews_cell*)[self superview] drawContentView:rect];
}

@end


@implementation FLNews_cell

@synthesize item = item_;
@synthesize cache_owner = cache_owner_;
@synthesize data = data_;

- (id)initWithIdentifier:(NSString *)identifier
{
	return [self initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:identifier];
}

/** This constructors prevents using the code on target 2.0 devices. */
- (id)initWithStyle:(UITableViewCellStyle)style
	reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		self.cache_owner = -1;
		content_view_ = [[FLNews_cell_view alloc]
			initWithFrame:self.contentView.bounds];
		content_view_.opaque = YES;
		content_view_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
			UIViewAutoresizingFlexibleHeight;
		content_view_.autoresizesSubviews = YES;
		content_view_.contentMode = UIViewContentModeRedraw;
		[self addSubview:content_view_];
		[content_view_ release];
	}
	return self;
}

- (void)dealloc
{
	[thumb_connection_ cancel];
	[thumb_connection_ release];
	thumb_connection_ = nil;
	self.item = nil;
	[data_ release];
	[super dealloc];
}

/** Sets the item of the cell.
 * Since cells are reused, this method practically does the equivalent
 * of deallocating and reallocating memory and other data, but without
 * actually doing so. The only new allocations done are for images
 * and network connections.
 */
- (void)setItem:(FLNews_item*)the_item
{
	LASSERT(self.data, @"Before setting an item put some data there.");

	if (item_ == the_item)
		return;

	[thumb_connection_ cancel];
	[image_ release];
	image_ = nil;
	[the_item retain];
	[item_ release];
	item_ = the_item;

	if (self.item.image) {
		if (!thumb_connection_)
			thumb_connection_ = [[FLMeta_data_connection alloc]
				init_with_action:@selector(did_receive_image:error:)
				target:self];

		thumb_connection_.target_size = self.data->image_size;
		NSString *pretty_url = [FLContent_view_controller
			prettify_request_url:self.item.image];
		[thumb_connection_ request:pretty_url news_id:self.item.id_
			cache_token:self.cache_owner cache_type:CACHE_THUMB
			cache_tables:NEWS_CACHE_TABLES force:NO];
	}

	[self setNeedsDisplay];
}

/** Handles reception of image from the net.
 * An UIImage will be created with the response data. If the UIImage can't be
 * created or the data ara corrupted, a broken icon will be shown instead.
 */
- (void)did_receive_image:(id)response error:(NSError*)error
{
	if (error)
		DLOG(@"Error receiving image: %@", error);
	else
		image_ = (id)[[response data] retain];

	/* Just in case, set broken image if nothing really came out. */
	if (!image_ || ![image_ isKindOfClass:[UIImage class]])
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

/** Special method that draws the custom cell content.
 * Text is recalculated to the width of the cell, which supports
 * portrait and landscape modes. Footers push up space for text and images.
 * Images can be left/right aligned.
 */
- (void)drawContentView:(CGRect)cell_rect
{
	LASSERT(self.data, @"Bad pointers");
	LASSERT(self.data.disclosure_image, @"No disclosure image?");
	LASSERT(self.data->title_lines >= 1, @"Bad number of lines");
	const CGFloat width = CGRectGetWidth(cell_rect) - _SCROLLBAR_SPACE;
	const CGFloat height = CGRectGetHeight(cell_rect);
	CGFloat usable_height = height - 2 * self.data->padding;

	/* Should we push up space due to a footer? */
	UIFont *footer_font = [UIFont systemFontOfSize:self.data->footer_size];
	if (self.item.footer) {
		CGSize footer_size = [@"." sizeWithFont:footer_font];
		LASSERT(usable_height > footer_size.height, @"Too many small things?");
		usable_height -= footer_size.height;
		if (usable_height < 1)
			return;
	}

	CGContextRef context = UIGraphicsGetCurrentContext();

	if (self.selected || self.highlighted)
		[self.data.back_highlight_color set];
	else
		[self.data.back_normal_color set];
	CGContextFillRect(context, cell_rect);

	const BOOL show_image = (thumb_connection_.working || image_);

	/* Calculate text position for the first title bold line. */
	CGPoint p = { self.data->padding, self.data->padding };
	if (show_image && !self.data->image_right)
		p.x += self.data->image_size.width + self.data->padding;

	const CGFloat disclosure_width = (self.item.url && !IS_IPAD) ?
		self.data.disclosure_image.size.width + self.data->padding : 0;

	const CGFloat usable_width = width - 2 * self.data->padding -
		disclosure_width - ((show_image && self.data->image_right) ?
			self.data->image_size.width + self.data->padding : 0);

#ifdef DEBUG_ID
	/* Show the internal cell identifier. */
	NSString *debug_id = [NSString stringWithFormat:@"%d", self.item.id_];
	CGSize id_width = [debug_id sizeWithFont:[UIFont boldSystemFontOfSize:30]];
	const CGPoint id_p = { width - id_width.width, 2 };
	[[UIColor lightGrayColor] set];
	[debug_id drawAtPoint:id_p withFont:[UIFont boldSystemFontOfSize:30]];
#endif

	[self.data.title_color set];
	UIFont *title_font = [UIFont boldSystemFontOfSize:self.data->title_size];
	/* Figure out how much space do we have for the title. */
	CGRect title_rect;
	title_rect.origin = p;
	title_rect.size = [@"." sizeWithFont:title_font];
	title_rect.size.width = usable_width + self.data->padding - p.x;
	title_rect.size.height = MIN(usable_height,
		self.data->title_lines * title_rect.size.height);

	CGSize size = [self.item.title drawInRect:title_rect
		withFont:title_font lineBreakMode:UILineBreakModeTailTruncation];

	/* The second text can span multiple rows, reserve the rest of the rect. */
	[self.data.text_color set];
	const CGRect text_rect = CGRectMake(p.x, p.y + size.height,
		usable_width + self.data->padding - p.x, usable_height - size.height);

	[self.item.body drawInRect:text_rect
		withFont:[UIFont systemFontOfSize:self.data->text_size]
		lineBreakMode:UILineBreakModeTailTruncation];

	/* Show the image, if any is available. */
	if (show_image) {
		CGRect rect = { self.data->padding, self.data->padding,
			self.data->image_size.width,
			MIN(usable_height, self.data->image_size.height) };

		/* Are we right aligned? */
		if (self.data->image_right)
			rect.origin.x = width - self.data->padding -
				self.data->image_size.width - disclosure_width;

		static UIImage *loading_image = 0;
		if (!loading_image)
			loading_image = [[UIImage imageNamed:@"loading.png"] retain];

		if (image_)
			[image_ drawInRect:rect];
		else
			[loading_image drawInRect:rect];
	}

	/* Draw the disclosure button if there is content. */
	if (disclosure_width) {
		const CGFloat button_height = MIN(height - 2 * self.data->padding,
			self.data.disclosure_image.size.height);

		const CGRect rect = { width - disclosure_width,
			height / 2 - button_height / 2,
			disclosure_width - self.data->padding, button_height };

		[self.data.disclosure_image drawInRect:rect];
	}

	/* Draw the footer. */
	if (self.item.footer) {
		p.x = self.data->padding;
		p.y = self.data->padding + usable_height;
		[self.data.footer_color set];

		if (self.data->footer_alignment < 0)
			[self.item.footer drawAtPoint:p
				forWidth:width - 2 * self.data->padding withFont:footer_font
				lineBreakMode:UILineBreakModeTailTruncation];
		else {
			/* For right/center alignment we have to precalculate the length. */
			CGRect footer_rect = CGRectMake(p.x, p.y, 0, 0);
			footer_rect.size = [self.item.footer sizeWithFont:footer_font];
			footer_rect.size.width = MIN(usable_width, footer_rect.size.width);

			if (self.data->footer_alignment > 0)
				footer_rect.origin.x =
					width - self.data->padding - footer_rect.size.width;
			else
				footer_rect.origin.x = (width - footer_rect.size.width) / 2.0f;

			[self.item.footer drawInRect:footer_rect withFont:footer_font
				lineBreakMode:UILineBreakModeTailTruncation];
		}
	}
}

- (NSString*)accessibilityLabel
{
	if (!self.item)
		return nil;

	NSMutableArray *texts = [NSMutableArray arrayWithCapacity:3];
	if (self.item.title.length > 1)
		[texts addObject:self.item.title];
	if (self.item.body.length > 1)
		[texts addObject:self.item.body];
	if (self.item.footer.length > 1)
		[texts addObject:self.item.footer];

	return [texts componentsJoinedByString:@". "];
}

- (NSString*)accessibilityLanguage
{
	return [[FLi18n get] current_langcode];
}

@end

// vim:tabstop=4 shiftwidth=4 syntax=objc
