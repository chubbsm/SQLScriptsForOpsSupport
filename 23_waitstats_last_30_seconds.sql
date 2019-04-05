        INSERT tempdb..wait_batches(sample_time)
        SELECT CURRENT_TIMESTAMP;

        INSERT  tempdb..wait_data (batch_id, wait_type, wait_time_ms, waiting_tasks)
        SELECT  2,
                os.wait_type, 
                SUM(CONVERT(BIGINT, os.wait_time_ms)) OVER (PARTITION BY os.wait_type) AS sum_wait_time_ms, 
                SUM(CONVERT(BIGINT, os.waiting_tasks_count)) OVER (PARTITION BY os.wait_type) AS sum_waiting_tasks
        FROM    sys.dm_os_wait_stats os
                LEFT JOIN tempdb..ignorable_waits iw on  os.wait_type=iw.wait_type
        WHERE   iw.wait_type IS NULL
        ORDER BY sum_wait_time_ms DESC;


    /* 
    What were we waiting on?
    This query compares the most recent two samples.
    */
    WITH max_batch AS (
        SELECT TOP 1 batch_id, sample_time
        FROM tempdb..wait_batches
        ORDER BY batch_id DESC
    )
    SELECT 
        b.sample_time AS [Second Sample Time],
        DATEDIFF(ss,wb1.sample_time, b.sample_time) AS [Sample Duration in Seconds],
        wd1.wait_type AS [Wait Stat],
        CAST((wd2.wait_time_ms-wd1.wait_time_ms) /1000. AS DECIMAL(38,1)) AS [Wait Time (Seconds)],
        (wd2.waiting_tasks-wd1.waiting_tasks) AS [Number of Waits],
        CASE WHEN (wd2.waiting_tasks-wd1.waiting_tasks) > 0 
        THEN
            CAST((wd2.wait_time_ms-wd1.wait_time_ms)/
                (1.0*(wd2.waiting_tasks-wd1.waiting_tasks)) AS DECIMAL(38,1))
        ELSE 0 END AS [Avg ms Per Wait]
    FROM  max_batch b
    JOIN tempdb..wait_data wd2 ON
        wd2.batch_id=b.batch_id
    JOIN tempdb..wait_data wd1 ON
        wd1.wait_type=wd2.wait_type AND
        wd2.batch_id - 1 = wd1.batch_id
    JOIN tempdb..wait_batches wb1 ON
        wd1.batch_id=wb1.batch_id
    WHERE (wd2.waiting_tasks-wd1.waiting_tasks) > 0
    ORDER BY [Wait Time (Seconds)] DESC;

    IF OBJECT_ID('tempdb..ignorable_waits') IS NOT NULL
        DROP TABLE tempdb..ignorable_waits;
    IF OBJECT_ID('tempdb..wait_data') IS NOT NULL
        DROP TABLE tempdb..wait_data;
    IF OBJECT_ID('tempdb..wait_batches') IS NOT NULL
        DROP TABLE tempdb..wait_batches;
