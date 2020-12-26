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
        (message$ "SQL: " ?sql " duration: " ?duration_ns " fullscan: " ?fullscan " sort: " ?sort " autoindex: " ?autoindex " vm_step: " ?vm_step " run: " ?run_count)
    )
    =>
    (bind ?calculated-start (- ?t ?duration_ns))
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
    ))
)


(defrule RECORDER::record-execution
    (table-attribute (table-id ?output) (has schema sqlite-query-execution))
    (sql-query (start ?start)
               (sql ?sql)
               (duration_ns ?duration_ns)
               (fullscan ?fullscan)
               (sort ?sort)
               (autoindex ?autoindex)
               (vm_step ?vm_step)
               (run_count ?run_count)
    )
    =>
    (create-new-row ?output)
    (set-column start ?start)
    (set-column duration ?duration_ns)
    (set-column query ?sql)
    (set-column fullscan ?fullscan)
    (set-column sort ?sort)
    (set-column autoindex ?autoindex)
    (set-column vm-step ?vm_step)
    (set-column run-count ?run_count)
)
