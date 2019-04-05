

select top 15 

*
, convert(decimal(19,2), tot_cpu_ms)/convert(decimal(19,2),usecounts)
, convert(decimal(19,2),tot_duration_ms)/convert(decimal(19,2),usecounts)
 from 
(
SELECT 
PlanStats.CpuRank, PlanStats.PhysicalReadsRank, PlanStats.DurationRank, 
--  CONVERT (varchar, getdate(), 126) AS runtime, 
  LEFT (p.cacheobjtype + ' (' + p.objtype + ')', 35) AS cacheobjtype,
  p.usecounts, p.size_in_bytes / 1024 AS size_in_kb, 
  PlanStats.total_worker_time/1000 AS tot_cpu_ms, PlanStats.total_elapsed_time/1000 AS tot_duration_ms, 
  PlanStats.total_physical_reads, PlanStats.total_logical_writes, PlanStats.total_logical_reads,
  planstats.last_execution_time,
 dbname = db_name( convert(int, pa.value) ),
    sql.objectid, 
  CONVERT (nvarchar(75), CASE 
    WHEN sql.objectid IS NULL THEN NULL 
    ELSE REPLACE (REPLACE (sql.[text],CHAR(13), ' '), CHAR(10), ' ')
  END) AS procname, 
  REPLACE (REPLACE (SUBSTRING (sql.[text], PlanStats.statement_start_offset/2 + 1, 
      CASE WHEN PlanStats.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), sql.[text])) 
        ELSE PlanStats.statement_end_offset/2 - PlanStats.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' ') AS stmt_text 
	, QueryPlan		=	qp.query_plan	
FROM 
(
  SELECT 
    stat.plan_handle, statement_start_offset, statement_end_offset, 
    stat.total_worker_time, stat.total_elapsed_time, stat.total_physical_reads, 
    stat.total_logical_writes, stat.total_logical_reads, stat.last_execution_time, 
    ROW_NUMBER() OVER (ORDER BY stat.total_worker_time DESC) AS CpuRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_physical_reads DESC) AS PhysicalReadsRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_elapsed_time DESC) AS DurationRank 
  FROM sys.dm_exec_query_stats stat 
  where creation_time > '1/16/2014 7:00'
  
) AS PlanStats 
INNER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = PlanStats.plan_handle 
OUTER APPLY sys.dm_exec_plan_attributes (p.plan_handle) pa 
OUTER APPLY sys.dm_exec_sql_text (p.plan_handle) AS sql
inner join sys.databases d on d.database_id = pa.value
OUTER APPLY sys.dm_exec_query_plan (p.plan_handle) qp

WHERE 1=1

 --and (PlanStats.CpuRank < 10 OR PlanStats.PhysicalReadsRank < 10 OR PlanStats.DurationRank < 10)
  AND pa.attribute = 'dbid' 
  and usecounts > 1
--      and sql.text like '%salescycles%'

) x
--where dbname = N'ram_tax'
ORDER BY CpuRank asc --+ PhysicalReadsRank + DurationRank asc




/*----------------
SQL 2000 only
SELECT 
UseCounts, RefCounts,CacheObjtype, ObjType, DB_NAME(dbid) as DatabaseName, SQL
FROM sys.syscacheobjects
where sql like '%mtblFeeEndorsement%'
ORDER BY dbid,usecounts DESC,objtype
GO
-----------------*/