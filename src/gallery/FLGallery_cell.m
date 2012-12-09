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
#import "gallery/FLGallery_cell.h"

#import "FLi18n.h"
#import "categories/NSString+Floki.h"
#import "controllers/FLContent_view_controller.h"
#import "models/FLGallery_item.h"
#import "net/FLMeta_data_connection.h"
#import "structures/FLGallery_cell_data.h"
#import "structures/FLAccessibility_cell.h"

#import "ELHASO.h"
#import "NSArray+ELHASO.h"
#import "NSMutableArray+ELHASO.h"


/// Small subclass to handle custom drawing of cells.
@interface FLGallery_cell_view : UIView
@end

@implementation FLGallery_cell_view

- (void)drawRect:(CGRect)rect
{
	[(FLGallery_cell*)[self superview] drawContentView:rect];
}

@end


@implementation FLGallery_cell

@synthesize items = items_;
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
		content_view_ = [[FLGallery_cell_view alloc]
			initWithFrame:self.contentView.bounds];
		content_view_.opaque = YES;
		content_view_.autoresizingMask = UIViewAutoresizingFlexibleWidth |
			UIViewAutoresizingFlexibleHeight;
		content_view_.autoresizesSubviews = YES;
		content_view_.contentMode = UIViewContentModeRedraw;
		[self addSubview:content_view_];
		[content_view_ release];
		selected_ = -1;
	}
	return self;
}

- (void)dealloc
{
	for (FLMeta_data_connection* f in connections_) [f cancel];
	[connections_ release];
	connections_ = nil;
	self.items = nil;
	[accessible_items_ release];
	[data_ release];
	[images_ release];
	[super dealloc];
}

/** Sets the item of the cell.
 * Since cells are reused, this method practically does the equivalent
 * of deallocating and reallocating memory and other data, but without
 * actually doing so. The only new allocations done are for images
 * and network connections.
 */
- (void)setItems:(NSArray*)items
{
	LASSERT(self.data, @"Before setting an item put some data there.");

	if (self.items == items)
		return;

	/* Cancel whatever might have been selected or connected. */
	selected_ = -1;
	for (FLMeta_data_connection* f in connections_) [f cancel];

	[accessible_items_ release];
	[items retain];
	[items_ release];
	items_ = items;

	NSMutableArray *valid_items = [items get_holder];

	/* Set up loading image. TODO: move to FLGallery_view_controller. */
	static UIImage *loading_image = 0;
	if (!loading_image)
		loading_image = [[UIImage imageNamed:@"loading.png"] retain];

	const int num = [items count];
	/* If the number of items increased, recreate the array. */
	if (!connections_ || [connections_ count] < num) {
		[connections_ release];
		connections_ = [[NSMutableArray alloc] initWithCapacity:num];
		images_ = [[NSMutableArray alloc] initWithCapacity:num];
		for (FLGallery_item *item in self.items) {

			FLMeta_data_connection *c = [[FLMeta_data_connection alloc]
				init_with_action:@selector(did_receive_image:error:)
				target:self];

			c.target_size = self.data->image_size;
			c.proportional_scaling = !self.data->stretch_images;
			[connections_ append:c];
			[c release];

			[images_ addObject:loading_image];
		}
	} else {
		for (int f = 0; f < [images_ count]; f++)
			[images_ replaceObjectAtIndex:f withObject:loading_image];
	}

	/* Fire up connections. */
	for (int f = 0; f < num; f++) {
		FLGallery_item *item = [self.items objectAtIndex:f];
		FLAccessibility_cell *helper = [[FLAccessibility_cell alloc]
			initWithAccessibilityContainer:self];
		SET_ACCESSIBILITY_LANGUAGE(helper);
		SET_ACCESSIBILITY_LABEL(helper, _e(30));
		// _30: Photo
		helper.accessibilityTraits = UIAccessibilityTraitButton;
		// On iOS 3.x helper might be nil, careful when adding it.
		[valid_items append:helper];
		[helper release];

		FLMeta_data_connection *connection = [connections_ objectAtIndex:f];
		NSString *pretty_url = [FLContent_view_controller
			prettify_request_url:item.image];
		[connection request:pretty_url news_id:item.id_
			cache_token:self.cache_owner cache_type:CACHE_THUMB
			cache_tables:GALLERY_CACHE_TABLES force:NO];
	}

	accessible_items_ = [valid_items retain];
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
		nil);

	[self setNeedsDisplay];
}

/** Handles reception of image from the net.
 * An UIImage will be created with the response data. If the UIImage can't be
 * created or the data ara corrupted, a broken icon will be shown instead.
 */
- (void)did_receive_image:(FLMeta_data_connection*)response
	error:(NSError*)error
{
	UIImage *image = nil;
	if (error)
		DLOG(@"Error receiving image: %@", error);
	else
		image = [[response data] retain];

	/* Just in case, set broken image if nothing really came out. */
	if (!image)
		image = [[UIImage imageNamed:@"Broken-icon.png"] retain];

	LASSERT([image isKindOfClass:[UIImage class]], @"Bad image object?");

	/* Find object and replace the image to that. */
	const int num = MIN(self.items.count, connections_.count);
	for (int f = 0; f < num; f++) {
		FLMeta_data_connection *connection = [connections_ objectAtIndex:f];
		if (connection == response) {
			[images_ replaceObjectAtIndex:f withObject:image];
			UNLOAD_OBJECT(image);
			break;
		}
	}
	LASSERT(!image, @"Didn't replace any image?");
	UNLOAD_OBJECT(image);

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
 * An image is drawn to the left, or a special in-progress loading
 * icon. Text is recalculated to the width of the cell, which supports
 * portrait and landscape modes.
 */
- (void)drawContentView:(CGRect)cell_rect
{
	LASSERT(self.data, @"Bad pointers");
	CGContextRef context = UIGraphicsGetCurrentContext();

	[self.data.normal_color set];
	CGContextFillRect(context, cell_rect);

	const CGFloat center_x = (cell_rect.size.width - gallery_width()) / 2;
	const CGFloat width = 2 * self.data->padding + self.data->image_size.width;
	CGRect outside_rect = { center_x + self.data->start_x, 0, width,
		2 * self.data->padding + self.data->image_size.height };
	CGRect inside_rect = { center_x + self.data->start_x + self.data->padding,
		self.data->padding, self.data->image_size.width,
		self.data->image_size.height };

	/* Since selected_ retains last state, draw it only if highlighted. */
	const int currently_selected = self.highlighted ? selected_ : -1;

	/* Loop through images, drawing selection status. */
	const int num = self.items.count;
	for (int f = 0; f < num; f++) {
		if (currently_selected == f) {
			[self.data.highlight_color set];
			CGContextFillRect(context, outside_rect);
		}
		UIImage *image = [images_ objectAtIndex:f];
		[image drawInRect:inside_rect];
		/// Update the accesibility element frame.
		FLAccessibility_cell *element = [accessible_items_ get:f];
		if (element) {
			element->local_frame = outside_rect;
			element.accessibilityFrame = [self.window
				convertRect:[self convertRect:outside_rect toView:self.window]
				toWindow:nil];
		}

		if (currently_selected == f) {
			[[UIColor blackColor] set];
			CGContextSetAlpha(context, 0.5f);
			CGContextFillRect(context, inside_rect);
			CGContextSetAlpha(context, 0);
		}

		/* Slide rects for next interation. */
		inside_rect.origin.x += width;
		outside_rect.origin.x += width;
	}
}

/** Returns the selected item, or nil if none was selected. */
- (FLGallery_item*)selected_item;
{
	LASSERT(self.items, @"Bad pointers");
	if (selected_ >= 0 && selected_ < self.items.count)
		return [self.items objectAtIndex:selected_];
	else
		return nil;
}

#pragma mark UIResponder touches override

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	LASSERT(self.data, @"Bad pointers");
	const int num = self.items.count;

	/* We don't allow multiple touches. */
	if (1 != [touches count])
		goto exit;

	UITouch *touch = [touches anyObject];
	first_touch_ = [touch locationInView:self];

	const CGFloat center_x = (self.frame.size.width - gallery_width()) / 2;
	const int top = first_touch_.x - center_x - self.data->start_x;
	// Avoid top being negative, objc rounds to zero.
	if (top >= 0) {
		const int bottom = self.data->padding * 2 + self.data->image_size.width;
		selected_ = top / bottom;
	} else {
		selected_ = -1;
	}

	if (selected_ >= num)
		selected_ = -1;
	else
		[self setNeedsDisplay];

exit:
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (selected_ < 0)
		goto exit;

	/* We don't allow multiple touches. */
	if (1 != [touches count]) {
		selected_ = -1;
		[self setNeedsDisplay];
		goto exit;
	}

	/* See if we moved too far horizontally and have to abort touch. */
	UITouch *touch = [touches anyObject];
	const CGPoint position = [touch locationInView:self];
	const int diff = first_touch_.x - position.x;
	if (diff > 9 || diff < -9) {
		selected_ = -1;
		[self setNeedsDisplay];
	}
exit:
	[super touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	selected_ = -1;
	[self setNeedsDisplay];
exit:
	[super touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self setNeedsDisplay];
exit:
	[super touchesEnded:touches withEvent:event];
}

#pragma mark -
#pragma mark Accesibility delegates

/// Say we don't have accesibility to be a container of views.
- (BOOL)isAccessibilityElement
{
	return NO;
}

/** Returns the accesibility element at the specified index.
 * This method also has the sideffect of calculating the cell's height in
 * window coordinates.
 */
- (id)accessibilityElementAtIndex:(NSInteger)index
{
	FLAccessibility_cell *element = [accessible_items_ get:index];
	if (element)
		element.accessibilityFrame = [self.window convertRect:[self
			convertRect:element->local_frame toView:self.window] toWindow:nil];
	return element;
}

/// Returns the number of accesibility items.
- (NSInteger)accessibilityElementCount
{
	return accessible_items_.count;
}

/// Returns the index of the accesibility item.
- (NSInteger)indexOfAccessibilityElement:(id)element
{
	return [accessible_items_ indexOfObject:element];
}

@end

/** Returns the maximum gallery width for the device.
 */
float gallery_width(void)
{
#if EXPERIMENT
	if (IS_IPAD)
		return 768;
	else
#endif
		return 320;
}
