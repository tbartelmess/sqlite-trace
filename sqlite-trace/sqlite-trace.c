//
//  sqlite-trace.c
//  sqlite-trace
//
//  Created by Thomas Bartelmess on 2020-12-24.
//

#include "sqlite-trace.h"
#include "sqlite3.h"
#include <os/log.h>
#include <os/signpost.h>

static os_log_t logger;
typedef struct {
    os_signpost_id_t signpost_id;
    dispatch_queue_t polling_queue;
    dispatch_source_t polling_timer;
    char* name;
    int last_txn_state;
} sqlite_trace_context_t;

static void configure_logger() {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        logger = os_log_create("io.bartelmess.sqlite-trace", "SQLite Trace");
    });
}

static int sqlite_trace_callback(unsigned int type, void* ctx, void* p, void* x) {
    sqlite_trace_context_t* context = ctx;
    context->signpost_id = os_signpost_id_generate(logger);
    switch (type) {
        case SQLITE_TRACE_STMT:
            os_signpost_event_emit(logger, context->signpost_id,
                                   "STMT",
                                   "statement %{public}p "
                                   "SQL %{public}s",
                                   p, sqlite3_normalized_sql(p));

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
                                   context->signpost_id,
                                   "PROFILE",
                                   "SQL: %{public}s duration: %llu "
                                    "fullscan: %{public}d "
                                   "sort: %{public}d "
                                   "autoindex: %{public}d "
                                   "vm_step: %{public}d "
                                   "run: %{public}d",
                                   sqlite3_normalized_sql(p),
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



void sqlite_trace_configure(sqlite3* db, const char* name) {
    configure_logger();
    if (os_signpost_enabled(logger)) {

        sqlite_trace_context_t* context = malloc(sizeof(sqlite_trace_context_t));
        context->last_txn_state = sqlite3_txn_state(db, NULL);
        context->polling_queue = dispatch_queue_create("io.bartelmess.sqltrace.polling", DISPATCH_QUEUE_SERIAL);
        context->polling_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, context->polling_queue);
        dispatch_source_set_timer(context->polling_timer, DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC, 0.05 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(context->polling_timer, ^{
            int db_state = sqlite3_txn_state(db, NULL);
            if (db_state != context->last_txn_state) {
                context->signpost_id = os_signpost_id_generate(logger);
                os_signpost_event_emit(logger, context->signpost_id,
                                       "TXN STATE",
                                       "database-state %{public}d",
                                       db_state);
                context->last_txn_state = db_state;
            }

        });
        dispatch_resume(context->polling_timer);
        sqlite3_trace_v2(db, (SQLITE_TRACE_STMT| SQLITE_TRACE_PROFILE|SQLITE_TRACE_CLOSE), sqlite_trace_callback, context);
    } else {

    }
}


