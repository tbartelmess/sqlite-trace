;  duplicate-query.clp
;  sqlite-trace
;
;  Created by Thomas Bartelmess on 2020-12-25.
;  

;;; Recorder that finds a two SQL queries with the same SQL query where the
;;; execution count is 1.
;;; When such an instance is found we assert a log narrative that it might be useful
;;; to use a prepared query.
(defrule RECORDER::record-duplicate-queries
    (sqlite-query-execution (query ?query1) (run-count ?rc1) (start ?t1))
    (sqlite-query-execution (query ?query2) (run-count ?rc2) (start ?t2))
    (table-attribute (table-id ?output) (has schema sqlite-narrative))
    =>
    (create-new-row ?output)
    (set-column time ?t2)
    (set-column-narrative description "Query %string% was executed more than and didn't reuse the same prepared query." ?query1)
)

