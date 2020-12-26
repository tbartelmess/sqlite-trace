;  query-sort.clp
;  sqlite-trace
;
;  Created by Thomas Bartelmess on 2020-12-25.
;  
;(defrule RECORDER::record-in-memory-sort
;    (sqlite-query-execution (query ?query) (sort ?sort) (start ?t))
;    (table-attribute (table-id ?output) (has schema sqlite-narrative))
;    (test (> ?sort 0))
;    =>
;    (create-new-row ?output)
;    (set-column time ?t)
;    (set-column issue-type "In Memory Sort")
;    (set-column-narrative description "Query '%string%'. An index with a correct ORDER BY clause may improve the performance of the query" ?query)
;)
