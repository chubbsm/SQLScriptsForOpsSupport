
select 
	eqp.query_plan
,	o.name
,	DBName = DB_NAME(eps.database_id)
,	eps.TYPE_desc
,	cached_time
,	last_execution_time,	execution_count
,	total_worker_time,	last_worker_time,	min_worker_time,	max_worker_time
,	total_physical_reads,	last_physical_reads,	min_physical_reads,	max_physical_reads
,	total_logical_writes,	last_logical_writes,	min_logical_writes,	max_logical_writes
,	total_logical_reads,	last_logical_reads,	min_logical_reads,	max_logical_reads
,	total_elapsed_time,	last_elapsed_time,	min_elapsed_time,	max_elapsed_time
,	eps.plan_handle
from sys.objects o
left outer join sys.dm_exec_procedure_stats eps on eps.object_id = o.object_id
cross apply sys.dm_exec_query_plan (eps.plan_handle) eqp 
where 1=1
and last_execution_time > '2013-03-14 10:43:06.493'
and o.name = 'ApprovalsReport_Loans'
order by total_worker_time/execution_count desc

/*

DBCC FREEPROCCACHE  (0x05002F002165DB3FB840681C000000000000000000000000 )

*/