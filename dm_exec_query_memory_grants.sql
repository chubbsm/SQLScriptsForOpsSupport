
--memory grant waits in progress
select
	Requested_Memory_MB		=	sum(isnull(mg.requested_memory_kb,0))/1024.
from sys.dm_exec_query_memory_grants mg
where session_id > 50
go
--With the Resource Governor SQL will grant <25% memory to a single session
select * from sys.dm_exec_query_memory_grants mg
OUTER APPLY sys.dm_exec_query_plan (mg.plan_handle) qp
		OUTER APPLY sys.dm_exec_sql_text (mg.sql_handle) est
