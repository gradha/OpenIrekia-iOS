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
#import "net/FLRemote_connection.h"

#import "FLi18n.h"
#import "global/FlokiAppDelegate.h"

#import "ELHASO.h"
#import "NSString+ELHASO.h"


#define _WORDS_SUBSTRING			@"_WORDS_"
#define _PAGE_SUBSTRING				@"_PAGE_"
#define _LNG_SUBSTRING				@"_LNG_"


@implementation FLRemote_connection

@synthesize connection = connection_;
@synthesize working = working_;

/** Create a remote connection object.
 * Pass as the action a method that receives a generic response
 * object and a possible NSError object. To start the download you
 * will have to call the request method.
 */
- (id)init_with_action:(SEL)action target:(id)target;
{
	if (self = [super init]) {
		if (action && target) {
			LASSERT([target respondsToSelector:action], @"Invalid selector?");
			action_ = action;
			target_ = target;
		}
	}
	return self;
}

/** Request a different URL.
 * You can use this to reuse a FLRemote_connection object that has
 * not been deallocated, or use this to abort an active connection.
 */
- (void)request:(NSString*)url
{
	LASSERT(!self.working, @"When requesting you shouldn't be working!");
	[connection_ release];
	self.working = YES;

	//DLOG(@"Requesting '%@'", url);
	if (!data_)
		data_ = [[NSMutableData alloc] initWithCapacity:2048];
	else
		[data_ setLength:0];
	expected_bytes_ = 0;

	NSURLRequest *request = [NSURLRequest
		requestWithURL:[NSURL URLWithString:url]
		cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
	connection_ = [[NSURLConnection alloc] initWithRequest:request
		delegate:self];
}

- (void)dealloc
{
	target_ = nil;
	[self cancel];
	[connection_ release];
	[data_ release];
	[super dealloc];
}

/// Getter for the target_ ivar.
- (id)target
{
	return target_;
}

/** Sets the state of the connection.
 * Additionaly this updates the global connection count of the
 * application, with the purpose of showing/hiding the system network
 * activity.
 */
- (void)setWorking:(BOOL)doit
{
	if (working_ != doit) {
		FlokiAppDelegate* app =
			(FlokiAppDelegate*)[[UIApplication sharedApplication] delegate];
		if (doit)
			app.active_downloads++;
		else
			app.active_downloads--;
	}
	working_ = doit;
}

/** Call this to abort the connection but not release connection memory. */
- (void)cancel
{
	self.working = NO;
	[self.connection cancel];
}

/** Gets called before receiving data.
 * Allows us handling 404 errors and stuff like that.
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if (connection != self.connection) return;
	if (![response isKindOfClass:[NSHTTPURLResponse class]])
		return;

	NSHTTPURLResponse *http = (NSHTTPURLResponse*)response;
	const int status = [http statusCode];
	NSDictionary *headers = [http allHeaderFields];
	expected_bytes_ = [[headers valueForKey:@"Content-Length"] intValue];
	is_gzip_ = [[headers valueForKey:@"Content-Encoding"]
		isEqualToString:@"gzip"];

	if (status < 200 || status >= 300) {
		DLOG(@"Cancelling connection %@ with code %d", [http URL], status);
		[self cancel];
		if (target_ && action_)
			[target_ performSelector:action_ withObject:self
				withObject:[NSError errorWithDomain:NSURLErrorDomain
					code:status userInfo:nil]];
	}
}

/** Get's called by the framework when more data is available. */
- (void)connection:(NSURLConnection*)connection
	didReceiveData:(NSData*)incrementalData
{
	if (connection != self.connection) return;
	//DLOG(@"incremental: expected %d, was %d", expected_bytes_, data_.length);
	[data_ appendData:incrementalData];
	//DLOG(@"incremental: now added to %d bytes", data_.length);
}

/** Called when a severe error happens. */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (connection != self.connection) return;
	self.working = NO;

	if (target_ && action_)
		[target_ performSelector:action_ withObject:self withObject:error];
}

/** Everthing went OK, call the action passing the data. */
- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
	if (connection != self.connection) return;
	self.working = NO;

	if (target_ && action_)
		[target_ performSelector:action_ withObject:self withObject:nil];
}

/** Returns the collected data so far.
 * This allows to be overriden by subclasses, to process the data.
 */
- (id)data
{
	if (!is_gzip_ && expected_bytes_ && (expected_bytes_ != [data_ length])) {
		DLOG(@"Expecting %d bytes, got %d", expected_bytes_, [data_ length]);
		NSString *dump = [[NSString alloc]
			initWithData:data_ encoding:NSISOLatin1StringEncoding];
		DLOG(@"Dump %@", dump);
		[dump release];
		LASSERT(expected_bytes_ == [data_ length], @"Not enough bytes");
	}
	return data_;
}

/** Transforms a parametrized URL into something that can be used.
 * Returns the address query to be performed or nil if no mandatory parameters
 * were found. If the page is negative, the page substring won't be searched
 * nor replaced.
 */
+ (NSString*)replace_search_params:(NSString*)url
	words:(NSString*)words page:(int)page
{
	RASSERT(words.length > 0, @"No words?", return nil);
	RASSERT(url.length > 0, @"No url?", return nil);
	NSRange range = [url rangeOfString:_WORDS_SUBSTRING];
	if (NSNotFound == range.location) {
		DLOG(@"Didn't find %@ substring in params", _WORDS_SUBSTRING);
		return nil;
	}

	url = [url stringByReplacingOccurrencesOfString:_LNG_SUBSTRING
		withString:[[FLi18n get] current_langcode]];

	url = [url stringByReplacingOccurrencesOfString:_WORDS_SUBSTRING
		withString:[words split_and_encode]];

	if (page < 0)
		return url;

	range = [url rangeOfString:_PAGE_SUBSTRING];
	if (NSNotFound == range.location) {
		DLOG(@"Didn't find %@ substring in params", _PAGE_SUBSTRING);
		return nil;
	}

	url = [url stringByReplacingOccurrencesOfString:_PAGE_SUBSTRING
		withString:[NSString stringWithFormat:@"%d", page]];

	return url;
}

@end
