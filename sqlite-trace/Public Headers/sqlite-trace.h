//
//  sqlite-trace.h
//  sqlite-trace
//
//  Created by Thomas Bartelmess on 2020-12-24.
//

#ifndef sqlite_trace_h
#define sqlite_trace_h

#include <stdio.h>
#include "sqlite3.h"
void sqlite_trace_configure(sqlite3* db, const char* name);

#endif
