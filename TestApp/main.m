//
//  main.m
//  TestApp
//
//  Created by Thomas Bartelmess on 2020-12-25.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import "sqlite-trace.h"

BOOL createTable(sqlite3* database) {
    static const char* sql = "CREATE TABLE test1 (id INTEGER PRIMARY KEY AUTOINCREMENT, firstname TEXT, lastname TEXT);";
    sqlite3_stmt* statement;
    if (sqlite3_prepare_v3(database, sql, -1, 0, &statement, NULL) != SQLITE_OK) {
        return false;
    }

    if (sqlite3_step(statement) != SQLITE_DONE) {
        return false;
    }
    sqlite3_finalize(statement);

    return true;
}

BOOL insertTest(sqlite3* database, uint32_t count) {
    static const char* sql = "INSERT INTO test1 (firstname, lastname) VALUES ($1, $2)";
    sqlite3_stmt* statement;
    for (uint32_t i=0; i < count; i++) {
        if (sqlite3_prepare_v3(database, sql, -1, 0, &statement, NULL) != SQLITE_OK) {
            return false;
        }
        sqlite3_bind_text(statement, 1, "Thomas", -1, SQLITE_STATIC);
        sqlite3_bind_text(statement, 2, "Bartelmess", -1, SQLITE_STATIC);
        if (sqlite3_step(statement) != SQLITE_DONE) {
            return false;
        }
        sqlite3_finalize(statement);
    }
    return true;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Open the database
        NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testdb.sqlite"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"Test database already exists, deleting.");
            NSError* deleteError = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:path error:&deleteError]) {
                NSLog(@"Failed to delete test database at %@", path);
                return EXIT_FAILURE;
            }
        }
        sqlite3* database;
        int status = sqlite3_open_v2(path.UTF8String, &database,
                        SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_READWRITE, NULL);
        if (status != SQLITE_OK) {
            NSLog(@"Failed to open test database. %s", sqlite3_errstr(status));
            return EXIT_FAILURE;
        }

        sqlite_trace_configure(database, "Test DB");

        if (!createTable(database)) {
            NSLog(@"Failed to create table");
            return EXIT_FAILURE;
        }

        if (!insertTest(database, 3)) {
            NSLog(@"Failed to insert data into test table");
            return EXIT_FAILURE;
        }
    }
    return 0;
}
