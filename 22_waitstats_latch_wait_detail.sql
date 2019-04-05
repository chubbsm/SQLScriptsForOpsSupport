    IF OBJECT_ID('tempdb..#uptime') IS NULL
        CREATE TABLE #uptime
        (
            percent_signal_waits DECIMAL(38, 0) NOT NULL ,
            hours_since_startup INT NOT NULL ,
            days_since_startup DECIMAL (38, 1) NOT NULL ,
            cpu_hours BIGINT NOT NULL ,
            ms_since_startup DECIMAL(38,0) NOT NULL ,
            cpu_ms_since_startup DECIMAL(38,0) NOT NULL
        );

    IF OBJECT_ID('tempdb..#top_waits') IS NOT NULL
       DROP TABLE #top_waits ;

    IF OBJECT_ID('tempdb..#latch_descriptions') IS NULL
       CREATE TABLE #latch_descriptions
       (
           latch_class NVARCHAR(120) NOT NULL,
           description VARCHAR(MAX) NOT NULL
       );

    /* TRUNCATE tables that do not get re-created on every run */
    TRUNCATE TABLE #uptime ;
    TRUNCATE TABLE #latch_descriptions ;

    WITH cpu_count AS (
        SELECT cpu_count
        FROM sys.dm_os_sys_info
    ), 
    overall_waits AS (
        SELECT  cast(100* SUM(CAST(CONVERT(BIGINT, signal_wait_time_ms) AS DECIMAL(38,1)))
                 / SUM(CONVERT(BIGINT, wait_time_ms)) AS DECIMAL(38,0)) AS percent_signal_waits
        FROM    sys.dm_os_wait_stats os),
    uptime AS (
        SELECT  DATEDIFF(HH, create_date, CURRENT_TIMESTAMP) AS hours_since_startup
        FROM    sys.databases
        WHERE   name='tempdb'
    )
    INSERT INTO #uptime
    SELECT  percent_signal_waits,
            hours_since_startup,
            CAST(hours_since_startup / 24. AS DECIMAL(38,1)) AS days_since_startup, 
            hours_since_startup * cpu_count AS cpu_hours, 
            CAST(hours_since_startup AS DECIMAL(38,0)) * 3600000 AS ms_since_startup,
            CAST(hours_since_startup AS DECIMAL(38,0)) * 3600000 * cpu_count AS cpu_ms_since_startup
    FROM    overall_waits, uptime, cpu_count;

    /********************************* 
    Let's build a list of waits we can safely ignore.
    *********************************/
    IF OBJECT_ID('tempdb..#ignorable_waits') IS NOT NULL 
        DROP TABLE #ignorable_waits;

    CREATE TABLE #ignorable_waits (wait_type nvarchar(256) PRIMARY KEY);

    /* We aren't usign row constructors to be SQL 2005 compatible */
    SET NOCOUNT ON;
    INSERT #ignorable_waits (wait_type) VALUES ('REQUEST_FOR_DEADLOCK_SEARCH');
    INSERT #ignorable_waits (wait_type) VALUES ('SQLTRACE_INCREMENTAL_FLUSH_SLEEP');
    INSERT #ignorable_waits (wait_type) VALUES ('SQLTRACE_BUFFER_FLUSH');
    INSERT #ignorable_waits (wait_type) VALUES ('LAZYWRITER_SLEEP');
    INSERT #ignorable_waits (wait_type) VALUES ('XE_TIMER_EVENT');
    INSERT #ignorable_waits (wait_type) VALUES ('XE_DISPATCHER_WAIT');
    INSERT #ignorable_waits (wait_type) VALUES ('FT_IFTS_SCHEDULER_IDLE_WAIT');
    INSERT #ignorable_waits (wait_type) VALUES ('LOGMGR_QUEUE');
    INSERT #ignorable_waits (wait_type) VALUES ('CHECKPOINT_QUEUE');
    INSERT #ignorable_waits (wait_type) VALUES ('BROKER_TO_FLUSH');
    INSERT #ignorable_waits (wait_type) VALUES ('BROKER_TASK_STOP');
    INSERT #ignorable_waits (wait_type) VALUES ('BROKER_EVENTHANDLER');
    INSERT #ignorable_waits (wait_type) VALUES ('BROKER_TRANSMITTER');
    INSERT #ignorable_waits (wait_type) VALUES ('SLEEP_TASK');
    INSERT #ignorable_waits (wait_type) VALUES ('SLEEP_SYSTEMTASK');
    INSERT #ignorable_waits (wait_type) VALUES ('WAITFOR');
    INSERT #ignorable_waits (wait_type) VALUES ('DBMIRROR_DBM_MUTEX')
    INSERT #ignorable_waits (wait_type) VALUES ('DBMIRROR_EVENTS_QUEUE')
    INSERT #ignorable_waits (wait_type) VALUES ('DBMIRRORING_CMD');
    INSERT #ignorable_waits (wait_type) VALUES ('DISPATCHER_QUEUE_SEMAPHORE');
    INSERT #ignorable_waits (wait_type) VALUES ('BROKER_RECEIVE_WAITFOR');
    INSERT #ignorable_waits (wait_type) VALUES ('CLR_AUTO_EVENT');
    INSERT #ignorable_waits (wait_type) VALUES ('DIRTY_PAGE_POLL');
    INSERT #ignorable_waits (wait_type) VALUES ('HADR_FILESTREAM_IOMGR_IOCOMPLETION');
    INSERT #ignorable_waits (wait_type) VALUES ('ONDEMAND_TASK_QUEUE');
    INSERT #ignorable_waits (wait_type) VALUES ('FT_IFTSHC_MUTEX');
    INSERT #ignorable_waits (wait_type) VALUES ('CLR_MANUAL_EVENT');
    INSERT #ignorable_waits (wait_type) VALUES ('SP_SERVER_DIAGNOSTICS_SLEEP');
    INSERT #ignorable_waits (wait_type) VALUES ('CLR_SEMAPHORE');
    INSERT #ignorable_waits (wait_type) VALUES ('DBMIRROR_WORKER_QUEUE');
    INSERT #ignorable_waits (wait_type) VALUES ('DBMIRROR_DBM_EVENT');
    INSERT #ignorable_waits (wait_type) VALUES ('HADR_CLUSAPI_CALL');
    INSERT #ignorable_waits (wait_type) VALUES ('HADR_LOGCAPTURE_WAIT');
    INSERT #ignorable_waits (wait_type) VALUES ('HADR_NOTIFICATION_DEQUEUE');
    INSERT #ignorable_waits (wait_type) VALUES ('HADR_TIMER_TASK');
    INSERT #ignorable_waits (wait_type) VALUES ('HADR_WORK_QUEUE');
    INSERT #ignorable_waits (wait_type) VALUES ('QDS_PERSIST_TASK_MAIN_LOOP_SLEEP');
    INSERT #ignorable_waits (wait_type) VALUES ('QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP');
    INSERT #ignorable_waits (wait_type) VALUES ('QDS_SHUTDOWN_QUEUE');
    
    /* Want to manually exclude an event and recalculate?*/
    /* insert #ignorable_waits (wait_type) VALUES (''); */

    /********************************* 
    What are the highest overall waits since startup? 
    What is the sum_wait_time_ms compared to the cpu_ms_since_startup? 
    *********************************/
    DECLARE @cpu_ms_since_startup DECIMAL (38, 0);
    SELECT  @cpu_ms_since_startup = cpu_ms_since_startup
    FROM    #uptime ;

    SELECT  TOP 25
            os.wait_type AS [Wait Stat], 
            SUM(CONVERT(BIGINT, os.wait_time_ms) / 1000.0 / 60 / 60) OVER (PARTITION BY os.wait_type) as [Total Hours of Wait],
            100.0 * (SUM(CONVERT(BIGINT, os.wait_time_ms)) OVER (PARTITION BY os.wait_type) / NULLIF(@cpu_ms_since_startup, 0)) AS [Wait % of CPU Time] ,
            CAST(
                100.* SUM(CONVERT(BIGINT, os.wait_time_ms)) OVER (PARTITION BY os.wait_type) 
                / NULLIF((1. * SUM(CONVERT(BIGINT, os.wait_time_ms)) OVER () ), 0)
                AS DECIMAL(38,1)) AS [% of Total Waits],
            CAST(
                100. * SUM(CONVERT(BIGINT, os.signal_wait_time_ms)) OVER (PARTITION BY os.wait_type) 
                / NULLIF((1. * SUM(CONVERT(BIGINT, os.wait_time_ms)) OVER ()), 0)
                AS DECIMAL(38,1)) AS [% Signal Wait],
            SUM(CONVERT(BIGINT, os.waiting_tasks_count)) OVER (PARTITION BY os.wait_type) AS [Waiting Tasks Count],
            CASE WHEN  SUM(CONVERT(BIGINT, os.waiting_tasks_count)) OVER (PARTITION BY os.wait_type) > 0
            THEN
                CAST(
                    SUM(CONVERT(BIGINT, os.wait_time_ms)) OVER (PARTITION BY os.wait_type)
                        / NULLIF((1. * SUM(CONVERT(BIGINT, os.waiting_tasks_count)) OVER (PARTITION BY os.wait_type)), 0)
                    AS DECIMAL(38,1))
            ELSE 0 END AS [Avg ms Per Wait],
            CURRENT_TIMESTAMP AS [Sample Time]
    INTO    #top_waits
    FROM    sys.dm_os_wait_stats os
            LEFT JOIN #ignorable_waits iw on os.wait_type=iw.wait_type
    WHERE   iw.wait_type IS NULL
    ORDER BY SUM(os.wait_time_ms / 1000.0 / 60 / 60) OVER (PARTITION BY os.wait_type) DESC;


        INSERT INTO #latch_descriptions

        SELECT 'ALLOC_CREATE_RINGBUF', 'Used internally by SQL Server to initialize the synchronization of the creation of an allocation ring buffer.'
        UNION ALL 
        SELECT 'ALLOC_CREATE_FREESPACE_CACHE', 'Used to initialize the synchronization of internal freespace caches for heaps.'
        UNION ALL 
        SELECT 'ALLOC_CACHE_MANAGER', 'Used to synchronize internal coherency tests.'
        UNION ALL 
        SELECT 'ALLOC_FREESPACE_CACHE', 'Used to synchronize the access to a cache of pages with available space for heaps and binary large objects (BLOBs). Contention on latches of this class can occur when multiple connections try to insert rows into a heap or BLOB at the same time. You can reduce this contention by partitioning the object. Each partition has its own latch. Partitioning will distribute the inserts across multiple latches. '
        UNION ALL 
        SELECT 'ALLOC_EXTENT_CACHE', 'Used to synchronize the access to a cache of extents that contains pages that are not allocated. Contention on latches of this class can occur when multiple connections try to allocate data pages in the same allocation unit at the same time. This contention can be reduced by partitioning the object of which this allocation unit is a part.  '
        UNION ALL 
        SELECT 'ACCESS_METHODS_DATASET_PARENT', 'Used to synchronize child dataset access to the parent dataset during parallel operations.'
        UNION ALL 
        SELECT 'ACCESS_METHODS_HOBT_FACTORY', 'Used to synchronize access to an internal hash table.'
        UNION ALL 
        SELECT 'ACCESS_METHODS_HOBT', 'Used to synchronize access to the in-memory representation of a HoBt.'
        UNION ALL 
        SELECT 'ACCESS_METHODS_HOBT_COUNT', 'Used to synchronize access to a HoBt page and row counters.'
        UNION ALL 
        SELECT 'ACCESS_METHODS_HOBT_VIRTUAL_ROOT', 'Used to synchronize access to the root page abstraction of an internal B-tree. '
        UNION ALL 
        SELECT 'ACCESS_METHODS_CACHE_ONLY_HOBT_ALLOC', 'Used to synchronize worktable access.'
        UNION ALL 
        SELECT 'ACCESS_METHODS_BULK_ALLOC', 'Used to synchronize access within bulk allocators.'
        UNION ALL 
        SELECT 'ACCESS_METHODS_SCAN_RANGE_GENERATOR', 'Used to synchronize access to a range generator during parallel scans.'
        UNION ALL 
        SELECT 'ACCESS_METHODS_KEY_RANGE_GENERATOR', 'Used to synchronize access to read-ahead operations during key range parallel scans.'
        UNION ALL 
        SELECT 'APPEND_ONLY_STORAGE_INSERT_POINT', 'Used to synchronize inserts in fast append-only storage units.'
        UNION ALL 
        SELECT 'APPEND_ONLY_STORAGE_FIRST_ALLOC', 'Used to synchronize the first allocation for an append-only storage unit. '
        UNION ALL 
        SELECT 'APPEND_ONLY_STORAGE_UNIT_MANAGER', 'Used for internal data structure access synchronization within the fast append-only storage unit manager.'
        UNION ALL 
        SELECT 'APPEND_ONLY_STORAGE_MANAGER', 'Used to synchronize shrink operations in the fast append-only storage unit manager.'
        UNION ALL 
        SELECT 'BACKUP_RESULT_SET', 'Used to synchronize parallel backup result sets.'
        UNION ALL 
        SELECT 'BACKUP_TAPE_POOL', 'Used to synchronize backup tape pools.'
        UNION ALL 
        SELECT 'BACKUP_LOG_REDO', 'Used to synchronize backup log redo operations.'
        UNION ALL 
        SELECT 'BACKUP_INSTANCE_ID', 'Used to synchronize the generation of instance IDs for backup performance monitor counters.'
        UNION ALL 
        SELECT 'BACKUP_MANAGER', 'Used to synchronize the internal backup manager.'
        UNION ALL 
        SELECT 'BACKUP_MANAGER_DIFFERENTIAL', 'Used to synchronize differential backup operations with DBCC.'
        UNION ALL 
        SELECT 'BACKUP_OPERATION', 'Used for internal data structure synchronization within a backup operation, such as database, log, or file backup.'
        UNION ALL 
        SELECT 'BACKUP_FILE_HANDLE', 'Used to synchronize file open operations during a restore operation.'
        UNION ALL 
        SELECT 'BUFFER', 'Used to synchronize short term access to database pages. A buffer latch is required before reading or modifying any database page. Buffer latch contention can indicate several issues, including hot pages and slow I/Os.   This latch class covers all possible uses of page latches. sys.dm_os_wait_stats makes a difference between page latch waits that are caused by I/O operations and read and write operations on the page. '
        UNION ALL 
        SELECT 'BUFFER_POOL_GROW', 'Used for internal buffer manager synchronization during buffer pool grow operations.'
        UNION ALL 
        SELECT 'DATABASE_CHECKPOINT', 'Used to serialize checkpoints within a database.'
        UNION ALL 
        SELECT 'CLR_PROCEDURE_HASHTABLE', 'Internal use only.'
        UNION ALL 
        SELECT 'CLR_UDX_STORE', 'Internal use only.'
        UNION ALL 
        SELECT 'CLR_DATAT_ACCESS', 'Internal use only.'
        UNION ALL 
        SELECT 'CLR_XVAR_PROXY_LIST', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_CHECK_AGGREGATE', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_CHECK_RESULTSET', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_CHECK_TABLE', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_CHECK_TABLE_INIT', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_CHECK_TRACE_LIST', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_FILE_CHECK_OBJECT', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_PERF', 'Used to synchronize internal performance monitor counters.'
        UNION ALL 
        SELECT 'DBCC_PFS_STATUS', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_OBJECT_METADATA', 'Internal use only.'
        UNION ALL 
        SELECT 'DBCC_HASH_DLL', 'Internal use only.'
        UNION ALL 
        SELECT 'EVENTING_CACHE', 'Internal use only.'
        UNION ALL 
        SELECT 'FCB', 'Used to synchronize access to the file control block.'
        UNION ALL 
        SELECT 'FCB_REPLICA', 'Internal use only.'
        UNION ALL 
        SELECT 'FGCB_ALLOC', 'Use to synchronize access to round robin allocation information within a filegroup.'
        UNION ALL 
        SELECT 'FGCB_ADD_REMOVE', 'Use to synchronize access to filegroups for ADD and DROP file operations.'
        UNION ALL 
        SELECT 'FILEGROUP_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'FILE_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'FILESTREAM_FCB', 'Internal use only.'
        UNION ALL 
        SELECT 'FILESTREAM_FILE_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'FILESTREAM_GHOST_FILES', 'Internal use only.'
        UNION ALL 
        SELECT 'FILESTREAM_DFS_ROOT', 'Internal use only.'
        UNION ALL 
        SELECT 'LOG_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_DOCUMENT_ID', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_DOCUMENT_ID_TRANSACTION', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_DOCUMENT_ID_NOTIFY', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_LOGS', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_CRAWL_LOG', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_ADMIN', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_AMDIN_COMMAND_CACHE', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_LANGUAGE_TABLE', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_CRAWL_DM_LIST', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_CRAWL_CATALOG', 'Internal use only.'
        UNION ALL 
        SELECT 'FULLTEXT_FILE_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'DATABASE_MIRRORING_REDO', 'Internal use only.'
        UNION ALL 
        SELECT 'DATABASE_MIRRORING_SERVER', 'Internal use only.'
        UNION ALL 
        SELECT 'DATABASE_MIRRORING_CONNECTION', 'Internal use only.'
        UNION ALL 
        SELECT 'DATABASE_MIRRORING_STREAM', 'Internal use only.'
        UNION ALL 
        SELECT 'QUERY_OPTIMIZER_VD_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'QUERY_OPTIMIZER_ID_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'QUERY_OPTIMIZER_VIEW_REP', 'Internal use only.'
        UNION ALL 
        SELECT 'RECOVERY_BAD_PAGE_TABLE', 'Internal use only.'
        UNION ALL 
        SELECT 'RECOVERY_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'SECURITY_OPERATION_RULE_TABLE', 'Internal use only.'
        UNION ALL 
        SELECT 'SECURITY_OBJPERM_CACHE', 'Internal use only.'
        UNION ALL 
        SELECT 'SECURITY_CRYPTO', 'Internal use only.'
        UNION ALL 
        SELECT 'SECURITY_KEY_RING', 'Internal use only.'
        UNION ALL 
        SELECT 'SECURITY_KEY_LIST', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_CONNECTION_RECEIVE', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_TRANSMISSION', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_TRANSMISSION_UPDATE', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_TRANSMISSION_STATE', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_TRANSMISSION_ERRORS', 'Internal use only.'
        UNION ALL 
        SELECT 'SSBXmitWork', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_MESSAGE_TRANSMISSION', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_MAP_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_HOST_NAME', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_READ_CACHE', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_WAITFOR_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_WAITFOR_TRANSACTION_DATA', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_TRANSMISSION_TRANSACTION_DATA', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_TRANSPORT', 'Internal use only.'
        UNION ALL 
        SELECT 'SERVICE_BROKER_MIRROR_ROUTE', 'Internal use only.'
        UNION ALL 
        SELECT 'TRACE_ID', 'Internal use only.'
        UNION ALL 
        SELECT 'TRACE_AUDIT_ID', 'Internal use only.'
        UNION ALL 
        SELECT 'TRACE', 'Internal use only.'
        UNION ALL 
        SELECT 'TRACE_CONTROLLER', 'Internal use only.'
        UNION ALL 
        SELECT 'TRACE_EVENT_QUEUE', 'Internal use only.'
        UNION ALL 
        SELECT 'TRANSACTION_DISTRIBUTED_MARK', 'Internal use only.'
        UNION ALL 
        SELECT 'TRANSACTION_OUTCOME', 'Internal use only.'
        UNION ALL 
        SELECT 'NESTING_TRANSACTION_READONLY', 'Internal use only.'
        UNION ALL 
        SELECT 'NESTING_TRANSACTION_FULL', 'Internal use only.'
        UNION ALL 
        SELECT 'MSQL_TRANSACTION_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'DATABASE_AUTONAME_MANAGER', 'Internal use only.'
        UNION ALL 
        SELECT 'UTILITY_DYNAMIC_VECTOR', 'Internal use only.'
        UNION ALL 
        SELECT 'UTILITY_SPARSE_BITMAP', 'Internal use only.'
        UNION ALL 
        SELECT 'UTILITY_DATABASE_DROP', 'Internal use only.'
        UNION ALL 
        SELECT 'UTILITY_DYNAMIC_MANAGER_VIEW', 'Internal use only.'
        UNION ALL 
        SELECT 'UTILITY_DEBUG_FILESTREAM', 'Internal use only.'
        UNION ALL 
        SELECT 'UTILITY_LOCK_INFORMATION', 'Internal use only.'
        UNION ALL 
        SELECT 'VERSIONING_TRANSACTION', 'Internal use only.'
        UNION ALL 
        SELECT 'VERSIONING_TRANSACTION_LIST', 'Internal use only.'
        UNION ALL 
        SELECT 'VERSIONING_TRANSACTION_CHAIN', 'Internal use only.'
        UNION ALL 
        SELECT 'VERSIONING_STATE', 'Internal use only.'
        UNION ALL 
        SELECT 'VERSIONING_STATE_CHANGE', 'Internal use only.'
        UNION ALL 
        SELECT 'KTM_VIRTUAL_CLOCK', 'Internal use only.' ;
   
        SELECT  dols.latch_class AS [Latch Class] ,
                dols.wait_time_ms AS [Wait Time (ms)],
                dols.waiting_requests_count AS [Waiting Requests Count],
                CASE WHEN dols.waiting_requests_count = 0 THEN 0
                     WHEN dols.wait_time_ms = 0 THEN 0
                     ELSE dols.wait_time_ms / dols.waiting_requests_count
                END AS [Avg Latch Wait (ms)],
                dols.max_wait_time_ms AS [Max Wait Time (ms)] ,
                CURRENT_TIMESTAMP AS  [Sample Time],
                ld.description AS [Description]
        FROM    sys.dm_os_latch_stats dols
                JOIN #latch_descriptions ld ON dols.latch_class = ld.latch_class
                CROSS APPLY (SELECT COUNT(*) tw_count FROM #top_waits WHERE [Wait Stat] = 'LATCH_EX') AS tw
        WHERE   dols.wait_time_ms > 0
        AND     tw.tw_count > 0
        ORDER BY dols.wait_time_ms DESC;

