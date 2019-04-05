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
       DROP TABLE #top_waits;

    /* TRUNCATE tables that do not get re-created on every run */
    TRUNCATE TABLE #uptime;

    WITH cpu_count AS (
        SELECT cpu_count
        FROM sys.dm_os_sys_info
    ), 
    overall_waits AS (
        SELECT  CAST(100 * SUM(CAST(CONVERT(BIGINT, signal_wait_time_ms) AS DECIMAL(38,1)))
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

    CREATE TABLE #ignorable_waits (wait_type NVARCHAR(256) PRIMARY KEY);

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

    SELECT
            os.wait_type AS [Wait Stat], 
            SUM(CONVERT(BIGINT, os.wait_time_ms) / 1000.0 / 60 / 60) OVER (PARTITION BY os.wait_type) AS [Total Hours of Wait],
            100.0 * (SUM(CONVERT(BIGINT, os.wait_time_ms)) OVER (PARTITION BY os.wait_type) / NULLIF((@cpu_ms_since_startup), 0)) AS [Wait % of CPU Time] ,
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
            LEFT JOIN #ignorable_waits iw ON os.wait_type=iw.wait_type
    WHERE   iw.wait_type IS NULL AND os.wait_time_ms > 0
    ORDER BY SUM(CONVERT(BIGINT, os.wait_time_ms) / 1000.0 / 60 / 60) OVER (PARTITION BY os.wait_type) DESC;

    SELECT   *
    FROM     #top_waits
    ORDER BY [Total Hours of Wait] DESC;