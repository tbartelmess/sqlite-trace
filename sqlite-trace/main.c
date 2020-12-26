//
//  main.c
//  sqlite-trace
//
//  Created by Thomas Bartelmess on 2020-12-21.
//

#include <stdio.h>
#include "sqlite3.h"
#include <os/log.h>
#include <os/signpost.h>
#include "Cleanup.h"

os_log_t logger;
os_signpost_id_t sqlite_signpost;

void setup_logger() {
    logger = os_log_create("sqlite", "tracing");
    sqlite_signpost = os_signpost_enabled(logger);
    os_log_info(logger, "Hello Logger");
}

int sqlite_trace_profile(sqlite3_stmt* stmt, uint64_t* nanoseconds) {
    os_log_debug(logger, "Statement %{public}s took %llu nanoseconds", sqlite3_expanded_sql(stmt), *nanoseconds);
    return 0;
}
int sqlite_trace_callback(unsigned int type, void* context, void* p, void* x) {
    switch (type) {
        case SQLITE_TRACE_STMT:
            os_signpost_event_emit(logger, sqlite_signpost, "STMT", "Statement: %{public}p SQL: %{public}s",
                                   p, sqlite3_sql(p));

            os_log_debug(logger, "Trace: STMT");
            break;
        case SQLITE_TRACE_PROFILE:
        {

            int32_t fullscan = sqlite3_stmt_status(p, SQLITE_STMTSTATUS_FULLSCAN_STEP, false);
            int32_t sort = sqlite3_stmt_status(p, SQLITE_STMTSTATUS_SORT, false);
            int32_t autoindex = sqlite3_stmt_status(p, SQLITE_STMTSTATUS_AUTOINDEX, false);
            int32_t vm_step = sqlite3_stmt_status(p, SQLITE_STMTSTATUS_VM_STEP, false);
            int32_t run_count = sqlite3_stmt_status(p, SQLITE_STMTSTATUS_RUN, false);
            uint64_t* duration = x;
            os_signpost_event_emit(logger,
                                   sqlite_signpost,
                                   "PROFILE",
                                   "SQL: %{public}s duration: %llu "
                                   "fullscan: %{public}d "
                                   "sort: %{public}d "
                                   "autoindex: %{public}d "
                                   "vm_step: %{public}d "
                                   "run: %{public}d",
                                   sqlite3_expanded_sql(p),
                                   *duration,
                                   fullscan,
                                   sort,
                                   autoindex,
                                   vm_step,
                                   run_count);
        }
            break;
        case SQLITE_TRACE_ROW:
            os_log_debug(logger, "Trace: ROW");
            break;
        case SQLITE_TRACE_CLOSE:
            os_log_debug(logger, "Trace: CLOSE");
            break;
        default:
            os_log_error(logger, "Unknown trace type: %d", type);
    }
    return SQLITE_OK;
}

int configure_tracer(sqlite3* db) {
    os_log_info(logger, "Configuring SQLite tracer for %p", db);
    sqlite3_trace_v2(db, SQLITE_TRACE_STMT|SQLITE_TRACE_PROFILE|SQLITE_TRACE_ROW|SQLITE_TRACE_CLOSE, sqlite_trace_callback, NULL);
    return SQLITE_OK;
}


int main(int argc, const char * argv[]) {
    cleanup();
    setup_logger();

    os_log_info(logger, "Creating in-memory sqlite database");
    sqlite3* database;
    int result = sqlite3_open_v2("/tmp/testdb.sqlite", &database, SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_CREATE| SQLITE_OPEN_READWRITE, NULL);
    if (result != SQLITE_OK) {
        os_log_error(logger, "Failed to open SQLite database");
    }
    os_log_info(logger, "Opened SQLite database");

    configure_tracer(database);
    sqlite3_stmt* create_table_statement;
    result = sqlite3_prepare_v2(database, "CREATE TABLE foo (pk INTEGER PRIMARY KEY);", -1, &create_table_statement, NULL);
    if (result != SQLITE_OK) {
        os_log_error(logger, "Failed to prepare statement %{public}s", sqlite3_errmsg(database));
    }

    os_log_debug(logger, "Created Statement %{public}s", sqlite3_sql(create_table_statement));
    result = sqlite3_step(create_table_statement);
    if (result != SQLITE_DONE) {
        os_log_error(logger, "Failed to stp statement %{public}s", sqlite3_errmsg(database));

    }

    return 0;
}
