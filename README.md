# SQLite Performance Instrument

The SQLite Performance Instrument is a starting point to investigate SQLite behaviour in your app.

### Instrument
Download the instrument from GitHub and double click it, and click “install” when Instruments.app asks you.

![Install in Instruments dialog][image-1]

## Setup

To enable SQLite profiling you'll need to call `sqlite_trace_configure` as soon as possible after opening the SQLite connection. You'll need to call this for every database connection.
Currently, the profiler assumes that all connections are for the same database. Calling `sqlite_trace_configure()` on databases that use different SQLite file under the hood might give you inconsistent results.

The profiling hook is only enabled when attached to instruments.

	#import <sqlite3.h>
	#import <sqlite-trace.h>
	
	@interface MyDatabaseWrapper : NSObject
	@property (nonatomic, readwrite) sqlite3* db;
	@end
	
	
	....
	- (void)setupDatabaseConnection {
	    
	    if (sqlite3_open_v2(....) == SQLITE_OK) { 
	    sqlite_trace_configure(self.db);
	    }
	}
	....
	

## SQLite Best Practices

- Think twice before using SQLite. SQLite is a very powerful tool if you have complex database needs. If you are mostly persisting objects do disk CoreData might be a better fit for you. Core Data uses SQLite under the hood but already does many things correctly for you.

## Identifying SQLite issues

## Query Performance

The best starting point is the “SQLite Query Timing” instrument. It shows all queries including their time in Instruments.

Queries are colour coded by their duration.

Queries are considered “good”/“fast” when they take less than 10ms to execute and appear green.
![Example of the query performance instrument][image-2]


### Indexes

#### Query `SELECT ...` performed a full table scan.

In this case, your query was not covered an index and SQLite needed to read trough a table row by row to filter your results. In some cases (e.g. when the you need to read the entire table) this is fine. When the table is very large you can look for adding indexes.

#### Query `SELECT ...` performed an in memory sort.

[image-1]:	docs/install-in-instruments.png
[image-2]:	query-performance.png