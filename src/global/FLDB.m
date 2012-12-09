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
#import "global/FLDB.h"

#import "global/FlokiAppDelegate.h"

#import "ELHASO.h"
#import "SBJson.h"

#import <time.h>

#ifdef DEBUG
#define LOG_ERROR(RES,QUERY,DO_ASSERT) do {									\
	if (RES.errorCode) {													\
		if (QUERY)															\
			DLOG(@"DB error running %@.\n%@", QUERY, RES.errorMessage);		\
		else																\
			DLOG(@"DB error code %d.\n%@", RES.errorCode, RES.errorMessage);\
		LASSERT(!(DO_ASSERT), @"Database query error");					\
	}																		\
} while(0)
#else
#define LOG_ERROR(RES,QUERY,DO_ASSERT) {}
#endif

@interface FLDB ()
@end

@implementation FLDB

/** Returns the path to the database filename.
 */
+ (NSString*)path
{
	return get_path(@"appdb", DIR_CACHE);
}

/** Called once per application, initialises the global application database.
 * This function will generate the database tables if they weren't present.
 * Returns the FLDB pointer with a retain count of one or nil if there were
 * problems and the application should abort.
 */
+ (FLDB*)open_database
{
	NSString *path = [FLDB path];
	FLDB *db = [FLDB databaseWithPath:path];
	if (![db open]) {
		LOG(@"Couldn't open db %@", path);
		return nil;
	}

	NSArray *tables = [NSArray arrayWithObjects:
		@"CREATE TABLE IF NOT EXISTS Owners ("
			@"id INTEGER PRIMARY KEY,"
			@"name VARCHAR(255),"
			@"last_updated INTEGER,"
			@"CONSTRAINT Owners_unique UNIQUE (id, name))",
		@"CREATE TABLE IF NOT EXISTS News_items ("
			@"id INTEGER NOT NULL,"
			@"owner INTEGER NOT NULL,"
			@"size INTEGER,"
			@"data TEXT,"
			@"CONSTRAINT News_items_unique UNIQUE (id, owner))",
		@"CREATE TABLE IF NOT EXISTS News_thumbs ("
			@"id INTEGER NOT NULL,"
			@"owner INTEGER NOT NULL,"
			@"url TEXT NOT NULL,"
			@"size INTEGER,"
			@"data BLOB,"
			@"CONSTRAINT News_thumbs_unique UNIQUE (id, owner))",
		@"CREATE TABLE IF NOT EXISTS Item_contents ("
			@"id INTEGER NOT NULL,"
			@"owner INTEGER NOT NULL,"
			@"url TEXT NOT NULL,"
			@"size INTEGER,"
			@"data BLOB,"
			@"CONSTRAINT Item_contents_unique UNIQUE (id, owner))",
		@"CREATE TABLE IF NOT EXISTS Gallery_items ("
			@"id INTEGER NOT NULL,"
			@"owner INTEGER NOT NULL,"
			@"size INTEGER,"
			@"data TEXT,"
			@"CONSTRAINT Gallery_items_unique UNIQUE (id, owner))",
		@"CREATE TABLE IF NOT EXISTS Gallery_thumbs ("
			@"id INTEGER NOT NULL,"
			@"owner INTEGER NOT NULL,"
			@"url TEXT NOT NULL,"
			@"size INTEGER,"
			@"data BLOB,"
			@"CONSTRAINT Gallery_thumbs_unique UNIQUE (id, owner))",
		@"CREATE TABLE IF NOT EXISTS Gallery_images ("
			@"id INTEGER NOT NULL,"
			@"owner INTEGER NOT NULL,"
			@"url TEXT NOT NULL,"
			@"size INTEGER,"
			@"data BLOB,"
			@"CONSTRAINT Gallery_images_unique UNIQUE (id, owner))",
		@"CREATE TABLE IF NOT EXISTS Sections ("
			@"id INTEGER NOT NULL,"
			@"owner INTEGER NOT NULL,"
			@"size INTEGER,"
			@"data BLOB,"
			@"CONSTRAINT Sections_unique UNIQUE (id, owner))",
		nil];

	EGODatabaseResult *result;
	for (NSString *query in tables) {
		result = [db executeQuery:query];
		if (result.errorCode) {
			LOG(@"Couldn't %@: %@", query, result.errorMessage);
			return nil;
		}
	}

	DLOG(@"Disk db open at %@", path);
	return db;
}

/** Returns the application's pointer to the open database.
 * Nil if where were problems.
 */
+ (FLDB*)get_db
{
	FlokiAppDelegate *floki = (id)[[UIApplication sharedApplication] delegate];
	return [floki db];
}

#pragma mark Table Owner

/** Used by the tabs when called by register_tables to register the table.
 * Stores the name and key in the Owners table or updates the name.
 * Returns NO if there was a problem, you should abort execution then.
 */
- (BOOL)register_tab:(NSString*)name unique_id:(int)unique_id
{
	LASSERT(name, @"Need a name");
	LASSERT(unique_id > 0, @"Bad unique_id");

	NSNumber *unique_num = [NSNumber numberWithInt:unique_id];
	EGODatabaseResult *result = [self executeQueryWithParameters:@"SELECT "
		@"name FROM Owners WHERE id = ?", unique_num, nil];
	if (result.count < 1) {
		result = [self executeQueryWithParameters:@"INSERT INTO Owners (id, "
			@"name, last_updated) VALUES (?, ?, 0)", unique_num, name, nil];
		if (result.errorCode) {
			LOG(@"Couldn't register table %@: %@", name, result.errorMessage);
			return NO;
		}
	} else {
		EGODatabaseRow *row = [result rowAtIndex:0];
		NSString *old_name = [row stringForColumnIndex:0];
		if (![old_name isEqualToString:name]) {
			result = [self executeQueryWithParameters:@"UPDATE Owners "
				@"SET name = ? WHERE id = ?", name, unique_num, nil];
			if (result.errorCode) {
				LOG(@"Couldn't update %@: %@", name, result.errorMessage);
				return NO;
			}
		}
	}
	return YES;
}

/** Returns the last modification date of the specified tab.
 * If not available, will return the reference date of 1970.
 */
- (NSDate*)get_tab_timestamp:(int)tab
{
	int value = 0;
	NSNumber *id_num = [NSNumber numberWithInt:tab];
	EGODatabaseResult *result = [self executeQueryWithParameters:@"SELECT "
		"last_updated FROM Owners WHERE id = ?", id_num, nil];
	if (result.errorCode) {
		LOG(@"Couldn't retrieve timestamp for %@", id_num);
		LASSERT(0, @"Couldn't retrieve timestamp.");
	} else {
		EGODatabaseRow *row = [result rowAtIndex:0];
		value = [row intForColumnIndex:0];
	}
	return [NSDate dateWithTimeIntervalSince1970:value];
}

/** Updates the tab timestamp to the current time.
 */
- (void)touch_tab_timestamp:(int)tab
{
	NSNumber *id_num = [NSNumber numberWithInt:tab];
	NSNumber *timestamp = [NSNumber numberWithInt:time(0)];

	EGODatabaseResult *result = [self executeQueryWithParameters:@"UPDATE "
		@"Owners SET last_updated = ? WHERE id = ?", timestamp, id_num, nil];
	LOG_ERROR(result, nil, YES);
}

/** Removes from Owners the tables specified in the identifier list.
 * The function will remove associated data in related tables.
 */
- (void)remove_tabs:(NSArray*)id_list
{
	for (NSNumber *id_num in id_list) {
		EGODatabaseResult *result = [self executeQueryWithParameters:@"DELETE "
			@"FROM Owners WHERE id = ?", id_num, nil];
		LOG_ERROR(result, nil, NO);

		/* TODO: Bad code, see #526. */
static NSString *_TABLES2[] = { @"News_thumbs", @"Item_contents", nil };
static NSString *_TABLES1[] = { @"Gallery_thumbs", @"Gallery_images", nil };
		[self purge_stale_meta_items:@"News_items" data_tables:_TABLES2
			lowest_id:-1 owner:[id_num intValue]];
		[self purge_stale_meta_items:@"Gallery_items" data_tables:_TABLES1
			lowest_id:-1 owner:[id_num intValue]];
	}

	if ([id_list count]) {
		DLOG(@"Vacuuming database, vroom vroom...");
		[self executeQuery:@"VACUUM;"];
	}
}

#pragma mark Meta functions

/** Saves into the database the specified meta item with owner.
 * If the item already exists in the database, its data is updated.
 */
- (void)save_meta_item:(NSString*)table data:(NSString*)data the_id:(int)the_id
	owner:(int)owner
{
	LASSERT(table, @"Null pointer");
	NSNumber *len = [NSNumber numberWithUnsignedInt:
		[data lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	LASSERT([len intValue] > 0, @"Uh, bad string");
	NSNumber *id_num = [NSNumber numberWithInt:the_id];
	NSNumber *owner_num = [NSNumber numberWithInt:owner];

	NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR "
		@"REPLACE INTO %@ (id, owner, size, data) VALUES (?, ?, ?, ?)", table];
	EGODatabaseResult *result = [self executeQueryWithParameters:query,
		id_num, owner_num, len, data, nil];
	LOG_ERROR(result, query, NO);
	[query release];
}

/** Purges sections from the cache.
 * Pass the owner for the sections and the list of items you want to keep.
 */
- (void)purge_unused_sections:(int)owner to_preserve:(NSArray*)to_preserve
{
	NSNumber *owner_num = [NSNumber numberWithInt:owner];
	NSString *query = nil;

	if (to_preserve.count > 0)
		query = [NSString stringWithFormat:@"DELETE FROM Sections "
			@"WHERE owner = ? AND id NOT IN (%@)",
			[to_preserve componentsJoinedByString:@","]];
	else
		query = @"DELETE FROM Sections WHERE owner = ?";

	EGODatabaseResult *result = [self executeQueryWithParameters:query,
		owner_num, nil];
	LOG_ERROR(result, query, NO);
}

/** Purges entries from the meta table.
 * The function will purge all meta elements lesser than lowest_id.
 * If lowest_id is zero or negative, however, all items for the owner will
 * be discarded. This function also purges cache for the data tables.
 * Pass as data_tables an NSString* nil terminated array.
 */
- (void)purge_stale_meta_items:(NSString*)parent_table
	data_tables:(NSString**)data_tables lowest_id:(int)lowest_id
	owner:(int)owner
{
	LASSERT(parent_table, @"Invalid parent_table");
	LASSERT(data_tables, @"Invalid data_tables");
	EGODatabaseResult *result;
	NSNumber *owner_num = [NSNumber numberWithInt:owner];
	if (lowest_id < 1) {
		NSString *query = [NSString stringWithFormat:@"DELETE FROM "
			@"%@ WHERE owner = ?", parent_table];
		result = [self executeQueryWithParameters:query, owner_num, nil];
		LOG_ERROR(result, query, NO);

		for (int f = 0; data_tables[f]; f++) {
			query = [NSString stringWithFormat:@"DELETE FROM "
				@"%@ WHERE owner = ?", data_tables[f]];
			result = [self executeQueryWithParameters:query, owner_num, nil];
			LOG_ERROR(result, query, NO);
		}
	} else {
		NSNumber *id_num = [NSNumber numberWithInt:lowest_id];
		NSString *query = [NSString stringWithFormat:@"DELETE FROM "
			@"%@ WHERE owner = ? and id < ?", parent_table];
		result = [self executeQueryWithParameters:query,
			owner_num, id_num, nil];
		LOG_ERROR(result, query, NO);

		for (int f = 0; data_tables[f]; f++) {
			NSString *query = [NSString stringWithFormat:@"DELETE FROM "
				@"%@ WHERE owner = ? and id < ?", data_tables[f]];
			result = [self executeQueryWithParameters:query,
				owner_num, id_num, nil];
			LOG_ERROR(result, query, NO);
		}
	}
}

/** Removes all the meta items of the array children of the specified owner.
 * Pass a nil terminated array of child tables that have to be purged as well.
 * Note that this function won't do anything if the array is empty.
 */
- (void)purge_meta_items:(NSString*)parent_table
	data_tables:(NSString**)data_tables to_delete:(NSArray*)to_delete
	owner:(int)owner
{
	LASSERT(parent_table, @"Invalid parent_table");
	LASSERT(data_tables, @"Invalid data_tables");
	if ([to_delete count] < 1)
		return;

	NSMutableArray *identifiers =
		[NSMutableArray arrayWithCapacity:[to_delete count]];
	for (NSNumber *num in to_delete)
		[identifiers addObject:[NSString stringWithFormat:@"%@", num]];
	NSString *set = [identifiers componentsJoinedByString:@", "];
	NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ "
		@"WHERE owner = ? AND id IN (%@)", parent_table, set];
	NSNumber *owner_num = [NSNumber numberWithInt:owner];

	EGODatabaseResult *result = [self executeQueryWithParameters:query,
		owner_num, nil];
	LOG_ERROR(result, query, NO);

	for (int f = 0; data_tables[f]; f++) {
		NSString *table = data_tables[f];
		query = [NSString stringWithFormat:@"DELETE FROM %@ "
			@"WHERE owner = ? AND id IN (%@)", table, set];

		result = [self executeQueryWithParameters:query, owner_num, nil];
		LOG_ERROR(result, query, NO);
	}
}

/** Reads all the owner related sections.
 * Returns an array of NSDictionary objects generated from parsing
 * the JSON stored in the individual tables. These NSDictionary should
 * be ripe to convert into meta objects.
 */
- (NSArray*)read_sections:(int)owner
{
	return [self read_meta_items:@"Sections" owner:owner];
}

/** Reads all the owner related elements from the parent table.
 * Returns an array of NSDictionary objects generated from parsing
 * the JSON stored in the individual tables. These NSDictionary should
 * be ripe to convert into meta objects.
 */
- (NSArray*)read_meta_items:(NSString*)parent_table owner:(int)owner
{
	LASSERT(parent_table, @"Invalid parent_table");
	NSNumber *owner_num = [NSNumber numberWithInt:owner];
	NSString *query = [NSString stringWithFormat:@"SELECT "
		@"id, data FROM %@ WHERE owner = ? ORDER BY id DESC", parent_table];
	EGODatabaseResult *result = [self executeQueryWithParameters:query,
		owner_num, nil];
	DLOG(@"%d cached %@ for owner %d", result.count, parent_table, owner);
	if (result.count < 1)
		return [NSArray array];

	NSMutableArray *data = [NSMutableArray arrayWithCapacity:result.count];
	for (EGODatabaseRow* row in result) {
#ifndef NS_BLOCK_ASSERTIONS
		const int row_id = [row intForColumnIndex:0];
#endif
		NSDictionary *dict = [[row stringForColumnIndex:1] JSONValue];
		LASSERT([[dict objectForKey:@"id"] intValue] == row_id, @"Bad data");
		[data addObject:dict];
	}
	return [NSArray arrayWithArray:data];
}

#pragma mark Table News_items related data

/** Saves a News item related data into a table.
 */
- (void)save_meta_data:(NSString*)table the_id:(int)the_id owner:(int)owner
	url:(NSString*)url data:(NSMutableData*)data
{
	NSNumber *len = [NSNumber numberWithUnsignedInt:[data length]];
	LASSERT([len intValue] > 0, @"Uh, bad thumb");
	NSNumber *id_num = [NSNumber numberWithInt:the_id];
	NSNumber *owner_num = [NSNumber numberWithInt:owner];

	NSString *query = [[NSString alloc] initWithFormat:@"INSERT OR "
	   @"REPLACE INTO %@ (id, owner, url, size, data) "
	   @"VALUES (?, ?, ?, ?, ?)", table];
	EGODatabaseResult *result = [self executeQueryWithParameters:query,
		id_num, owner_num, url, len, data, nil];
	LOG_ERROR(result, query, NO);
	[query release];
}

/** Retrieves from the database some metadata.
 * Pass the url to verify that the remote URL on the server has not
 * changed, wich would invalidate the local cache.
 **/
- (NSData*)load_meta_data:(NSString*)table the_id:(int)the_id
	owner:(int)owner url:(NSString*)url
{
	LASSERT([table length] > 0, @"Pass a table");
	NSNumber *id_num = [NSNumber numberWithInt:the_id];
	NSNumber *owner_num = [NSNumber numberWithInt:owner];

	NSString *query = [[NSString alloc] initWithFormat:@"SELECT "
		@"url, data FROM %@ WHERE id = ? AND owner = ?", table];
	EGODatabaseResult *result = [self executeQueryWithParameters:query, 
		id_num, owner_num, nil];
	[query release];
	if (result.count < 1) {
		//DLOG(@"%@ miss for %d at %d", table, the_id, owner);
		return nil;
	}
	LASSERT(1 == result.count, @"Too many results?");

	EGODatabaseRow *row = [result rowAtIndex:0];
	NSString *cached_url = [row stringForColumnIndex:0];
	if (![cached_url isEqualToString:url]) {
		DLOG(@"%@ miss, invalidated %@ != %@", table, cached_url, url);
		return nil;
	}

	return [NSData dataWithData:[row dataForColumnIndex:1]];
}

@end
