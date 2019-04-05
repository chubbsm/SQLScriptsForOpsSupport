    /********************************* 
    Clear out past runs.
    *********************************/
    IF OBJECT_ID('tempdb..deep_dive') IS NOT NULL 
        DROP TABLE tempdb..deep_dive;

    /********************************* 
    Let's build a list of waits we can safely ignore.
    *********************************/
    IF OBJECT_ID('tempdb..ignorable_waits') IS NOT NULL 
        DROP TABLE tempdb..ignorable_waits;

    CREATE TABLE tempdb..ignorable_waits (wait_type nvarchar(256) PRIMARY KEY);

    SET NOCOUNT ON;
	INSERT INTO tempdb..ignorable_waits(wait_type) 
	VALUES('BROKER_EVENTHANDLER')
	                , ('BROKER_RECEIVE_WAITFOR')
	                , ('BROKER_TASK_STOP')
	                , ('BROKER_TO_FLUSH')
	                , ('BROKER_TRANSMITTER')
	                , ('CHECKPOINT_QUEUE')
	                , ('DBMIRROR_DBM_EVENT')
	                , ('DBMIRROR_DBM_MUTEX')
	                , ('DBMIRROR_EVENTS_QUEUE')
	                , ('DBMIRROR_WORKER_QUEUE')
	                , ('DBMIRRORING_CMD')
	                , ('DIRTY_PAGE_POLL')
	                , ('DISPATCHER_QUEUE_SEMAPHORE')
	                , ('FT_IFTS_SCHEDULER_IDLE_WAIT')
	                , ('FT_IFTSHC_MUTEX')
	                , ('HADR_CLUSAPI_CALL')
	                , ('HADR_FILESTREAM_IOMGR_IOCOMPLETION')
	                , ('HADR_LOGCAPTURE_WAIT')
	                , ('HADR_NOTIFICATION_DEQUEUE')
	                , ('HADR_TIMER_TASK')
	                , ('HADR_WORK_QUEUE')
	                , ('LAZYWRITER_SLEEP')
	                , ('LOGMGR_QUEUE')
	                , ('ONDEMAND_TASK_QUEUE')
	                , ('PREEMPTIVE_HADR_LEASE_MECHANISM')
	                , ('PREEMPTIVE_SP_SERVER_DIAGNOSTICS')
	                , ('QDS_ASYNC_QUEUE')
	                , ('QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP')
	                , ('QDS_PERSIST_TASK_MAIN_LOOP_SLEEP')
	                , ('QDS_SHUTDOWN_QUEUE')
	                , ('REDO_THREAD_PENDING_WORK')
	                , ('REQUEST_FOR_DEADLOCK_SEARCH')
	                , ('SLEEP_SYSTEMTASK')
	                , ('SLEEP_TASK')
	                , ('SP_SERVER_DIAGNOSTICS_SLEEP')
	                , ('SQLTRACE_BUFFER_FLUSH')
	                , ('SQLTRACE_INCREMENTAL_FLUSH_SLEEP')
	                , ('UCS_SESSION_REGISTRATION')
	                , ('WAIT_XTP_OFFLINE_CKPT_NEW_LOG')
	                , ('WAITFOR')
	                , ('XE_DISPATCHER_WAIT')
	                , ('XE_LIVE_TARGET_TVF')
	                , ('XE_TIMER_EVENT')

    /* Want to manually exclude an event and recalculate?*/
    /* insert tempdb..ignorable_waits (wait_type) VALUES (''); */


    /********************************* 
    What are the highest waits *right now*? 
    *********************************/    

    /* Note: this is dependent on the tempdb..ignorable_waits table created earlier. */
    IF OBJECT_ID('tempdb..wait_batches') IS NOT NULL
        DROP TABLE tempdb..wait_batches;
    IF OBJECT_ID('tempdb..wait_data') IS NOT NULL
        DROP TABLE tempdb..wait_data;

    CREATE TABLE tempdb..wait_batches (
        batch_id INT IDENTITY (1,1) PRIMARY KEY,
        sample_time datetime NOT NULL
    );

    CREATE TABLE tempdb..wait_data ( 
        batch_id INT NOT NULL ,
        wait_type NVARCHAR(256) NOT NULL ,
        wait_time_ms BIGINT NOT NULL ,
        waiting_tasks BIGINT NOT NULL
    );

    CREATE CLUSTERED INDEX cx_wait_data ON tempdb..wait_data(batch_id);

        INSERT tempdb..wait_batches(sample_time)
        SELECT CURRENT_TIMESTAMP;


        INSERT  tempdb..wait_data (batch_id, wait_type, wait_time_ms, waiting_tasks)
        SELECT  1,
                os.wait_type, 
                SUM(os.wait_time_ms) OVER (PARTITION BY os.wait_type) AS sum_wait_time_ms, 
                SUM(os.waiting_tasks_count) OVER (PARTITION BY os.wait_type) AS sum_waiting_tasks
        FROM    sys.dm_os_wait_stats os
                LEFT JOIN tempdb..ignorable_waits iw on  os.wait_type=iw.wait_type
        WHERE   iw.wait_type IS NULL
        ORDER BY sum_wait_time_ms DESC;




        IF OBJECT_ID('tempdb..sql_counters_list') IS NOT NULL 
        DROP TABLE tempdb..sql_counters_list;

				/* Types in the DMV are NCHAR. We're going variable length here.*/
		        CREATE TABLE tempdb..sql_counters_list
		            (
		              [counter_id] SMALLINT IDENTITY NOT NULL ,
		              [object_name] VARCHAR(128) NOT NULL ,
		              [counter_name] VARCHAR(128) NOT NULL ,
		              [instance_name] VARCHAR(128) NULL ,
					  [cntr_type] INT NOT NULL,
		              [brent_ozar_unlimited_note] VARCHAR(2000) NULL ,
					  [display_group] TINYINT,
		              [display_order] SMALLINT
		            );

			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group], [display_order])
			SELECT '', '', NULL, 0, 'Frequently used perf counters from Brent Ozar Unlimited.', 1, -100
			UNION SELECT '', '', NULL, 0, 'Occasionally used perf counters from Brent Ozar Unlimited.', 2, -99

			--Memory Manager Counters
			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group], [display_order])
			SELECT 'Memory Manager', 'Memory Grants Pending', NULL, 65792, 'Requests waiting on obtaining a query workspace memory grant. Repeat non-zero values indicate a problem.', 1, -8
			UNION SELECT 'Memory Manager', 'Memory Grants Outstanding', NULL, 65792,'Executing requests that have a query workspace memory grant. These are not a problem.', 1, -9
			UNION SELECT 'Memory Manager', 'Target Server Memory (KB)', NULL, 65792,'The amount of physical memory SQL Server would like to grow to use.', 1, -10
			UNION SELECT 'Memory Manager', 'Total Server Memory (KB)', NULL, 65792,'Committed physical memory in KB in use by the buffer pool.', 1, -11
			;

			--SQL Statistics Counters
			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group], [display_order])
			SELECT 'SQL Statistics', 'Batch Requests/sec', NULL, 272696576, 'Num requests: indication of throughput. Higher is better. Dependent on load.', 1, 1
			UNION SELECT 'SQL Statistics', 'SQL Compilations/sec', NULL, 272696576,'Rate of execution plan creation. Includes statement-level recompiles. A recompile may be counted as two compiles (so this can be higher than Batch Requests/sec at times).', 1, 2
			UNION SELECT 'SQL Statistics', 'SQL Re-Compilations/sec', NULL, 272696576,'Rate of re-creation of execution plans (for statements which already had them).', 1, 3
			UNION SELECT 'SQL Statistics', 'Forced Parameterizations/sec', NULL, 272696576,'Statements with literals forced to parameterize. Caused by database setting OR a certain type of plan guide.', 1, 4
			UNION SELECT 'SQL Statistics', 'Auto-Param Attempts/sec', NULL, 272696576,'Failed + Safe + Unsafe auto-parameterized statements (but not forced)', 2, 5
			UNION SELECT 'SQL Statistics', 'Safe Auto-Params/sec', NULL, 272696576,'Simple parameterization attempts (deemed safe for re-use).', 2, 6
			UNION SELECT 'SQL Statistics', 'Unsafe Auto-Params/sec', NULL, 272696576,'Simple parameterization attempts-- but plans NOT judged safe for re-use', 2, 7
			UNION SELECT 'SQL Statistics', 'Failed Auto-Params/sec', NULL, 272696576,'Failed simple paramaterization attempts.', 2,  8
			UNION SELECT 'SQL Statistics', 'Guided Plan Executions/sec', NULL, 272696576,'Executions where plan dictated by a plan guide (does not include plan guides that force or parameterization or force literals).', 2, 9
			UNION SELECT 'SQL Statistics', 'Misguided Plan Executions/sec', NULL, 272696576,'Attempted to use a plan guide, but could not. Disregarded the plan guide.', 2, 10
			UNION SELECT 'SQL Statistics', 'SQL Attention rate', NULL, 272696576,'Attention requests (cancellation requests) from the client.', 2,  11
			;

			--General Statistics
			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group],  [display_order])
			SELECT 'General Statistics', 'Logins/sec', NULL, 272696576, 'Incoming logins-- execept for logins started from the connection pool.', 1, 15
			UNION SELECT 'General Statistics', 'Logouts/sec', NULL, 272696576,'Goodbye!', 1, 16
			UNION SELECT 'General Statistics', 'Connection Resets/sec', NULL, 272696576,'Logins started from the connection pool.', 1, 17
			UNION SELECT 'General Statistics', 'User Connections', NULL, 65792,'Number of users connected (total).', 1, 14
			;
			--Access Methods
			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group],  [display_order])
			SELECT 'Access Methods', 'Full Scans/sec', NULL, 272696576, 'Clustered index or table scans-- but they don''t necessarily read all the rows in the index/table!', 2, 21
			UNION SELECT 'Access Methods', 'Range Scans/sec', NULL, 272696576,'Scans a range of rows in an index. Could be a few rows, could be a lot. May look like a seek in a query plan.', 2,  22
			UNION SELECT 'Access Methods', 'Probe Scans/sec', NULL, 272696576,'These pull just a single, qualified row in a table or index.', 2, 23
			UNION SELECT 'Access Methods', 'Forwarded Records/sec', NULL, 272696576,'How many times SQL Server had to follow a forwarding address pointer. (Heaps only.)', 1, 24
			UNION SELECT 'Access Methods', 'Skipped Ghosted Records/sec', NULL, 272696576,'How many "ghost" records skipped during scans. Ghosts are marked as deleted but not yet cleaned up.', 2, 25
			UNION SELECT 'Access Methods', 'Extents Allocated/sec', NULL, 272696576,'Number of sets of 8 pages allocated (whole instance).', 2, 26
			UNION SELECT 'Access Methods', 'Extent Deallocations/sec', NULL, 272696576,'Number of sets of 8 pages deallocated (whole instance).', 2, 27
			;

			--Buffer Manager
			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group],  [display_order])
			SELECT 'Buffer Manager', 'Free list stalls/sec', NULL, 272696576, 'Requests that had to wait due to lack of free list space in memory. The free list is maintained by the lazywriter.', 2, 31
			UNION SELECT 'Buffer Manager', 'Lazy writes/sec', NULL, 272696576,'Pages written to disk from memory by the lazy writer.', 2, 32
			UNION SELECT 'Buffer Manager', 'Checkpoint pages/sec', NULL, 272696576,'Pages flushed to disk by a checkpoint.', 2, 33
			UNION SELECT 'Buffer Manager', 'Page lookups/sec', NULL, 272696576,'Count of all pages fetched from the buffer pool.', 2, 30
			UNION SELECT 'Buffer Manager', 'Page reads/sec', NULL, 272696576,'Physical pages read from disk (couldn''t be read from memory, all DBs).', 1, -4
			UNION SELECT 'Buffer Manager', 'Readahead pages/sec', NULL, 272696576,'Pages read into memory from disk using asyncrhonous pre-fetching.', 2, 36
			UNION SELECT 'Buffer Manager', 'Page life expectancy', NULL, 65792,'Estimated seconds SQL believes a data page is likely to stay in the buffer pool.', 1, -5
			;
			--Lock Manager 
			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group],  [display_order])
			SELECT 'Locks', 'Number of Deadlocks/sec', '_Total', 272696576, 'Number of lock requests that ended in a deadlock.', 1, 41
			UNION SELECT 'Locks', 'Lock Requests/sec', '_Total', 272696576,'Number of requests for a lock (they may not have to wait for it).',2, 42
			UNION SELECT 'Locks', 'Lock Waits/sec', '_Total', 272696576,'Number of lock requests had to wait (blocking, etc).', 2, 42
			;

			--Databases
			INSERT tempdb..[sql_counters_list] ( [object_name], [counter_name], [instance_name], [cntr_type], [brent_ozar_unlimited_note], [display_group],  [display_order])
			SELECT 'Databases', 'Log Flushes/sec', '_Total', 272696576, 'Number of individually committed transactions.', 2, 51
			UNION SELECT 'Databases', 'Log Flush Waits/sec', '_Total', 272696576,'Number of committed transactions waiting.', 2, 52
			UNION SELECT 'Databases', 'Log Bytes Flushed/sec', '_Total', 272696576,'Bytes flushed to the transaction log in this period.', 2, 53
			UNION SELECT 'Databases', 'Log Flush Wait Time', '_Total', 65792,'Milliseconds waiting on flushing the log.', 2, 54
			UNION SELECT 'Databases', 'Data File(s) Size(KB)', '_Total', 272696576,'Diff between total size of data files: if 0 then no growth in the sample period.', 1, 55
			;


        IF OBJECT_ID('tempdb..sql_counters_data') IS NOT NULL 
        DROP TABLE tempdb..sql_counters_data;

		        CREATE TABLE tempdb..sql_counters_data
		            (
		              [batch_id] TINYINT NOT NULL ,
		              [collection_time] DATETIME NOT NULL
		                                         DEFAULT GETDATE() ,
		              [object_name] VARCHAR(128) NOT NULL ,
		              [counter_name] VARCHAR(128) NOT NULL ,
		              [instance_name] VARCHAR(128) NULL ,
		              [cntr_value] BIGINT NOT NULL,
				    )

		/*Collect first sample.*/
		INSERT  tempdb..[sql_counters_data]
		        ( [batch_id] , [object_name] , [counter_name] , [instance_name] , [cntr_value] )
		        SELECT  1 AS [batch_id] ,
		                CAST(RTRIM(perf.[object_name]) AS VARCHAR(128)) ,
		                CAST(RTRIM(perf.[counter_name]) AS VARCHAR(128)) ,
		                CAST(RTRIM(perf.[instance_name]) AS VARCHAR(128)) ,
		                perf.[cntr_value]
		        FROM    sys.[dm_os_performance_counters] AS perf
		                JOIN tempdb..sql_counters_list ctrs ON RTRIM(perf.[counter_name]) COLLATE SQL_Latin1_General_CP1_CI_AS = ctrs.[counter_name] COLLATE SQL_Latin1_General_CP1_CI_AS
		                                                AND ( ctrs.[instance_name] IS NULL
		                                                     OR ( RTRIM(perf.[instance_name]) COLLATE SQL_Latin1_General_CP1_CI_AS = ctrs.[instance_name] COLLATE SQL_Latin1_General_CP1_CI_AS)
														) AND perf.[cntr_type] = ctrs.[cntr_type]
		        WHERE   CHARINDEX(ctrs.[object_name] COLLATE SQL_Latin1_General_CP1_CI_AS, perf.[object_name] COLLATE SQL_Latin1_General_CP1_CI_AS) > 0;

