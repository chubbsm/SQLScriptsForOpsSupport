
select top 10

	wait_type
,	wait_time_s =  wait_time_ms / 1000.  
,	Pct			=	100. * wait_time_ms/sum(wait_time_ms) OVER()
from sys.dm_os_wait_stats wt
where wt.wait_type NOT LIKE '%SLEEP%' 
and wt.wait_type <> 'REQUEST_FOR_DEADLOCK_SEARCH'
and wt.wait_type not in ('CLR_AUTO_EVENT','CLR_MANUAL_EVENT','DIRTY_PAGE_POLL')
and wt.wait_type not in ('HADR_FILESTREAM_IOMGR_IOCOMPLETION')
and wt.wait_type <> 'SQLTRACE_BUFFER_FLUSH' -- system trace, not a cause for concern
and wt.wait_type not in ('ONDEMAND_TASK_QUEUE','BROKER_TRANSMITTER','BROKER_EVENTHANDLER','LOGMGR_QUEUE','CHECKPOINT_QUEUE','BROKER_TO_FLUSH','DISPATCHER_QUEUE_SEMAPHORE') -- background task that handles requests, not a cause for concern
and wt.wait_type not in ('KSOURCE_WAKEUP','XE_DISPATCHER_WAIT','FT_IFTS_SCHEDULER_IDLE_WAIT','FT_IFTSHC_MUTEX','XE_TIMER_EVENT') -- other waits that can be safely ignored
order by Pct desc

/*
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);

select * 
into dbaadmin.dbo.sys_dm_os_wait_stats_201402041431
from sys.dm_os_wait_stats

*/