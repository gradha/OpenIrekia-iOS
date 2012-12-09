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
#import "video/FLMovie_text_cell.h"

#import "FLi18n.h"
#import "categories/NSString+Floki.h"
#import "net/FLMeta_data_connection.h"
#import "structures/FLMovie_cell_data.h"

#import "ELHASO.h"


#define _MAX_HEIGHT		2000


/// Small subclass to handle custom drawing of cells.
@interface FLMovie_text_cell_view : UIView
@end

@implementation FLMovie_text_cell_view

- (void)drawRect:(CGRect)rect
{
	[(FLMovie_text_cell*)[self superview] drawContentView:rect];
}

@end


@implementation FLMovie_text_cell

@synthesize cache_owner = cache_owner_;
@synthesize data = data_;

#pragma mark -
#pragma mark Methods

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
		cache_owner_ = -1;
		content_view_ = [[FLMovie_text_cell_view alloc]
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
	[data_ release];
	[super dealloc];
}

/** Special handler method because of drawContentView and inheritance.
 * Forces a refresh of our custom view.
 */
- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[content_view_ setNeedsDisplay];
}

/** Returns the height that will be used for the cell content.
 * Pass the screen width to know how wide the cell currently is.
 */
+ (CGFloat)height_for_text:(FLMovie_cell_data*)data width:(CGFloat)width
{
	UIFont *title_font = [UIFont boldSystemFontOfSize:data->title_size];

	/* Figure how much space do we have for the title. */
	CGSize title_size = [@"." sizeWithFont:title_font];
	title_size.height *= data->title_lines;
	title_size.width = width - data->padding * 2;
	LASSERT(title_size.width > 0, @"Bad cell width");
	LASSERT(title_size.height > 0, @"Bad cell height");

	CGSize size1 = [data.title sizeWithFont:title_font
		constrainedToSize:title_size
		lineBreakMode:UILineBreakModeTailTruncation];

	CGSize size2 = [data.text
		sizeWithFont:[UIFont systemFontOfSize:data->text_size]
		constrainedToSize:CGSizeMake(title_size.width,
			_MAX_HEIGHT - size1.height)
		lineBreakMode:UILineBreakModeTailTruncation];

	return size1.height + size2.height + data->padding * 2;
}

/** Special method that draws the custom cell content.
 * An image is drawn to the left, or a special in-progress loading
 * icon. Text is recalculated to the width of the cell, which supports
 * portrait and landscape modes.
 */
- (void)drawContentView:(CGRect)cell_rect
{
	LASSERT(self.data, @"Bad pointers");
	LASSERT(self.data->title_lines >= 1, @"Bad number of lines");
	CGContextRef context = UIGraphicsGetCurrentContext();

	[self.data.back_color set];
	CGContextFillRect(context, cell_rect);

	[self.data.title_color set];
	UIFont *title_font = [UIFont boldSystemFontOfSize:self.data->title_size];
	/* Figure how much space do we have for the title. */
	CGRect title_rect =
		CGRectMake(self.data->padding, self.data->padding, 0, 0);
	title_rect.size = [@"." sizeWithFont:title_font];
	title_rect.size.width = cell_rect.size.width - 2 * self.data->padding;
	title_rect.size.height *= self.data->title_lines;

	CGSize size = [self.data.title drawInRect:title_rect
		withFont:title_font lineBreakMode:UILineBreakModeTailTruncation];

	[self.data.text_color set];
	[self.data.text drawInRect:CGRectMake(self.data->padding,
		size.height + self.data->padding, title_rect.size.width, _MAX_HEIGHT)
		withFont:[UIFont systemFontOfSize:self.data->text_size]];
}

- (NSString*)accessibilityLabel
{
	if (!self.data)
		return nil;

	NSMutableArray *texts = [NSMutableArray arrayWithCapacity:3];
	if (self.data.title.length > 1)
		[texts addObject:self.data.title];
	if (self.data.text.length > 1)
		[texts addObject:self.data.text];

	return [texts componentsJoinedByString:@". "];
}

- (NSString*)accessibilityLanguage
{
	return [[FLi18n get] current_langcode];
}

@end
