;  sql-timing.clp
;  sqlite-trace
;
;  Created by Thomas Bartelmess on 2020-12-22.
;  


(deftemplate MODELER::sql-query
    (slot statement-pointer (type EXTERNAL-ADDRESS))
    (slot database-pointer (type EXTERNAL-ADDRESS))
    (slot database-path (type STRING))
    (slot start (type INTEGER))
    (slot end (type INTEGER))
    (slot instance (type INTEGER))
    (slot sql (type STRING))
    (slot duration_ns (type INTEGER))
    (slot fullscan (type INTEGER))
    (slot sort (type INTEGER))
    (slot autoindex (type INTEGER))
    (slot vm_step (type INTEGER))
    (slot run_count (type INTEGER))
    (slot thread (type EXTERNAL-ADDRESS SYMBOL))
    (slot backtrace (type EXTERNAL-ADDRESS SYMBOL) (allowed-symbols sentinel) (default sentinel))
)

;;; There is not much we know about the query when the query starts,
;;; however an initial version tried to only use the end result and calculate the total time
;;; which for longer running queries often exceeded the event horizon of the modeler
;(defrule MODELER::capture-query-start
;    (os-signpost
;        (time ?t&~0)
;    )
;)


(defrule MODELER::emit-query-metrics
    (os-signpost
        (time ?t&~0)
        (name "PROFILE")
        (event-type "Event")
        (identifier ?instance)
        (thread ?thread)
        (message$ "SQL: " ?sql " duration: " ?duration_ns&~0 " fullscan: " ?fullscan " sort: " ?sort " autoindex: " ?autoindex " vm_step: " ?vm_step " run: " ?run_count)
    )
    =>
    (bind ?calculated-start (- ?t ?duration_ns))
    (log-narrative "Asserted a query")
    (assert (sql-query
                (start ?calculated-start)
                (end ?t)
                (instance ?instance)
                (sql ?sql)
                (duration_ns ?duration_ns)
                (fullscan ?fullscan)
                (sort ?sort)
                (autoindex ?autoindex)
                (vm_step ?vm_step)
                (run_count ?run_count)
                (thread ?thread)
                (backtrace sentinel)
    ))
)
;
(defrule MODELER::fuse-sqlite-exec-with-backtrace
    ?query <- (sql-query (thread ?thread) (backtrace sentinel))
    (time-profile (thread ?thread) (stack ?stack))
    =>
    (modify ?query (backtrace ?stack))
    (log-narrative "Got a backtrace for a query")
)

(defrule RECORDER::record-execution
    (table (table-id ?output) (side append))
    (table-attribute (table-id ?output) (has schema sqlite-query-execution))
    ?query <- (sql-query (start ?start)
               (sql ?sql)
               (duration_ns ?duration_ns)
               (fullscan ?fullscan)
               (sort ?sort)
               (autoindex ?autoindex)
               (vm_step ?vm_step)
               (run_count ?run_count)
               (backtrace ?backtrace)
    )
    (not (sql-query (instance ?instance) (backtrace sentinel)))
    =>
    (bind ?exec-time-impact (if (< ?duration_ns 10000000) then "Low" else (if (> ?duration_ns 20000000) then "High" else "Moderate")))

    (create-new-row ?output)
    (set-column start ?start)
    (set-column duration ?duration_ns)
    (set-column query ?sql)
    (set-column fullscan ?fullscan)
    (set-column sort ?sort)
    (set-column autoindex ?autoindex)
    (set-column vm-step ?vm_step)
    (set-column run-count ?run_count)
    (set-column exec-time-impact ?exec-time-impact)
    (set-column backtrace ?backtrace)
)




