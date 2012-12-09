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
#import "net/FLMeta_data_connection.h"

#import "global/FLDB.h"
#import "global/settings.h"

#import "ELHASO.h"


NSString *Meta_data_error_domain = @"Meta_data_error_domain";

@interface FLMeta_data_connection ()
- (UIImage*)data_to_image:(id)data;
@end


@implementation FLMeta_data_connection

@synthesize news_str = news_str_;
@synthesize target_size = target_size_;
@synthesize proportional_scaling = proportional_scaling_;
@synthesize from_disk = from_disk_;

- (void)dealloc
{
	[news_str_ release];
	[super dealloc];
}

/** Request an URL.
 * Pass also the identifier of the news item, so it can be cached on disk.
 * If force is set to yes, the class will fetch data from the network
 * even if there is local content.
 */
- (void)request:(NSString*)url news_id:(int)news_id
	cache_token:(int)cache_token cache_type:(CACHE_TYPE)cache_type
	cache_tables:(NSString**)tables force:(BOOL)force
{
	LASSERT(tables, @"Invalid tables parameter");
	LASSERT(tables[0], @"Empty tables parameter");

	self.from_disk = NO;
	force_ = force;
	tables_ = tables;
	type_ = cache_type;
	news_id_ = news_id;
	[news_str_ release];
	if (CACHE_THUMB == cache_type)
		news_str_ = [[NSString stringWithFormat:@"%@_thumb_%d",
			tables[0], news_id] retain];
	else
		news_str_ = [[NSString stringWithFormat:@"%@_content_%d",
			tables[0], news_id] retain];

	[super request:url cache_token:cache_token];
}

/** Returns the data from the cache if possible.
 */
- (id)data
{
	if (self.dont_cache)
		return data_;

	id data = [self get_memory_cache:news_str_ token:cache_token_];
	if (data)
		return data;
	else
		return [super data];
}

/** Returns the object for the url and token.
 * Override the method to return a disk object if no memory object exists.
 */
- (id)get_memory_cache:(NSString*)url token:(int)token
{
	LASSERT(news_id_ > 0, @"Bad initialisation");
	if (force_)
		return nil;

	id data = [super get_memory_cache:news_str_ token:token];
	if (data) {
		if (CACHE_THUMB == type_)
			LASSERT([data isKindOfClass:[UIImage class]], @"Invalid data?");
		else
			LASSERT([(NSMutableData*)data length] > 0, @"Uh, invalid data?");
	}

	if (!data && !self.dont_cache) {
		LASSERT(tables_, @"Internal inconsistency");
		/* See if it is on disk. */
		NSData *disk_data;
		disk_data = [[FLDB get_db] load_meta_data:tables_[type_] the_id:news_id_
			owner:token url:url];
		if (disk_data) {
			LASSERT([disk_data length] > 0, @"Uh, invalid data?");
			if (CACHE_THUMB == type_)
				data = [self data_to_image:disk_data];
			else
				data = disk_data;

			if (data) {
				self.from_disk = YES;
				[super set_memory_cache:news_str_ token:token data:data];
			}
		}
	}

	return data;
}

/** See comment of connectionDidFinishLoading.
 */
- (void)set_memory_cache:(NSString*)url token:(int)token data:(id)data
{
	LASSERT(0, @"This code should never run");
}

/** Everthing went OK, store a copy of the data in the memory cache.
 * We want to override this method from FLCached_connection level
 * because while the data is set into the disk cache, we want to
 * call the target with an UIImage version of the data and store
 * this version too in memory.
 **/
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection
{
	self.working = NO;
	LASSERT(data_, @"Oops");

	if (!self.dont_cache) {
		LASSERT(tables_, @"Internal inconsistency");
		if (CACHE_THUMB == type_) {
			UIImage *image = [self data_to_image:data_];
			if (image) {
				[super set_memory_cache:news_str_ token:cache_token_
					data:image];
				[[FLDB get_db] save_meta_data:tables_[type_] the_id:news_id_
					owner:cache_token_ url:self.url data:data_];

			} else {
				DLOG(@"Error converting image, weird.");
				NSDictionary *info = [NSDictionary dictionaryWithObject:data_
					forKey:@"data"];
				NSError *error = [NSError
					errorWithDomain:Meta_data_error_domain code:1
					userInfo:info];

				LASSERT([self respondsToSelector:
					@selector(connection:didFailWithError:)], @"Broken API");
				id<NSURLConnectionDelegate> target = (id)self;
				[target connection:theConnection didFailWithError:error];
			}
		} else {
			[super set_memory_cache:news_str_ token:cache_token_ data:data_];
			[[FLDB get_db] save_meta_data:tables_[type_] the_id:news_id_
				owner:cache_token_ url:self.url data:data_];
		}
		LASSERT(data_, @"Oops");
	}

	id target = self.target;
	if (target && action_) {
		LASSERT(data_, @"Oops");
		[target performSelector:action_ withObject:self withObject:nil];
	}
}

- (UIImage*)data_to_image:(id)data
{
	return [FLMeta_data_connection data_to_image:data size:self.target_size
		proportional:self.proportional_scaling];
}

/** Helper to convert data into an UIImage.
 * The returned data will be of the specified size. If the received
 * image is not of the requested size, it will be rescaled. This helps
 * the performance, since later during screen drawing no scaling has
 * to happen.
 *
 * You must retain the returned image if you really need it.
 */
+ (UIImage*)data_to_image:(id)data size:(CGSize)size
	proportional:(BOOL)proportional_scaling
{
	return [self scale_image:[UIImage imageWithData:data] size:size
		proportional:proportional_scaling];
}

/** The real workhorse to scale an image.
 * Used by data_to_image and others.
 */
+ (UIImage*)scale_image:(UIImage*)image size:(CGSize)size
	proportional:(BOOL)proportional_scaling
{
	if (!image) {
		LASSERT(image, @"Null pointer");
		return nil;
	}

	BOOL slash = NO;
	CGRect rect = { 0, 0, 0, 0 };
	if (size.width && size.height) {
		if (image.size.width != size.width ||
				(image.size.height != size.height)) {
			//DLOG(@"Performance warning, scaling image %dx%d to %dx%d",
			//	(int)image.size.width, (int)image.size.height,
			//	(int)size.width, (int)size.height);
			slash = YES;
		}
		rect.size = size;
	} else {
		rect.size = image.size;
	}

	LASSERT(rect.size.width > 0, @"Scaling image to width less than 1");
	LASSERT(rect.size.width < 1024, @"Scaling image to width too big");
	LASSERT(rect.size.height > 0, @"Scaling image to height less than 1");
	LASSERT(rect.size.height < 1024, @"Scaling image to height too big");

	UIGraphicsBeginImageContext(size);
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextClearRect(c, rect);
	if (proportional_scaling) {
		const CGFloat max_w = rect.size.width;
		const CGFloat max_h = rect.size.height;
		CGFloat w = image.size.width;
		CGFloat h = image.size.height;
		CGFloat factor = max_w / w;
		w *= factor;
		h *= factor;

		if (h > max_h) {
			factor = max_h / h;
			w *= factor;
			h *= factor;
		}

		rect.origin.x = (max_w - w) / 2.0f;
		rect.origin.y = (max_h - h) / 2.0f;
		rect.size.width = w;
		rect.size.height = h;
		[image drawInRect:rect];
	} else {
		[image drawInRect:rect];
	}

	// Do we have to slash scaled images?
	if (gSlash_scaled_images && slash) {
		CGContextSetLineWidth(c, 3);
		[[UIColor whiteColor] set];
		CGContextMoveToPoint(c, 0, 0);
		CGContextAddLineToPoint(c, rect.size.width - 1, rect.size.height - 1);
		CGContextStrokePath(c);
		CGContextSetLineWidth(c, 2);
		[[UIColor redColor] set];
		CGContextMoveToPoint(c, 0, 0);
		CGContextAddLineToPoint(c, rect.size.width - 1, rect.size.height - 1);
		CGContextStrokePath(c);
	}

	UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
	LASSERT(scaled, @"Coudln't scale image?");
	UIGraphicsEndImageContext();
	if (scaled) {
		LASSERT(scaled.size.width == size.width, @"Bad code");
		LASSERT(scaled.size.height == size.height, @"Bad code");
	}

	return scaled;
}

@end
