/* -------------------------------------------------- */
/* BEGIN SECTION: Storage throughput by database file */
/* -------------------------------------------------- */

/********************************* 
What are the storage throughput *right now*? 
*********************************/
IF OBJECT_ID('tempdb..#file_wait_batches') IS NOT NULL 
    DROP TABLE #file_wait_batches;
IF OBJECT_ID('tempdb..#file_wait_data') IS NOT NULL 
    DROP TABLE #file_wait_data;
GO

CREATE TABLE #file_wait_batches
    (
      batch_id INT IDENTITY PRIMARY KEY ,
      sample_time DATETIME NOT NULL
    );
CREATE TABLE #file_wait_data
    (
      batch_id INT NOT NULL ,
      [db_name] NVARCHAR(256) ,
      file_logical_name NVARCHAR(256) ,
      size_on_disk_mb BIGINT ,
      io_stall_read_ms BIGINT ,
      num_of_reads BIGINT ,
    bytes_read BIGINT ,
      io_stall_write_ms BIGINT ,
      num_of_writes BIGINT ,
    bytes_written BIGINT, 
      physical_name NVARCHAR(520)
    )
GO
CREATE CLUSTERED INDEX CX_filewaitdata_batch_id ON #file_wait_data(batch_id);
GO

/* 
This temporary procedure records file throughput data to a temp table.
*/
IF OBJECT_ID('tempdb..#get_file_wait_data') IS NOT NULL 
    DROP PROCEDURE #get_file_wait_data;
GO
CREATE PROCEDURE #get_file_wait_data
    @intervals TINYINT = 2 ,
    @delay CHAR(12) = '00:00:30.000' /* 30 seconds*/
AS 
    DECLARE @batch_id INT ,
        @current_interval TINYINT ,
        @msg NVARCHAR(MAX);

    SET NOCOUNT ON;
    SET @current_interval = 1;

    WHILE @current_interval <= @intervals 
        BEGIN
            INSERT  #file_wait_batches
                    ( sample_time )
                    SELECT  CURRENT_TIMESTAMP;

            SELECT  @batch_id = SCOPE_IDENTITY();

            INSERT  #file_wait_data
                    ( batch_id ,
                      db_name ,
                      file_logical_name ,
                      size_on_disk_mb ,
                      io_stall_read_ms ,
                      num_of_reads ,
            [bytes_read] ,
                      io_stall_write_ms ,
                      num_of_writes ,
            [bytes_written] ,
                      physical_name
                    )
                    SELECT  @batch_id ,
                            DB_NAME(a.database_id) AS [db_name] ,
                            b.name + N' [' + b.type_desc COLLATE SQL_Latin1_General_CP1_CI_AS + N']' AS file_logical_name ,
                            CAST(( ( a.size_on_disk_bytes / 1024.0 ) / 1024.0 ) AS INT) AS size_on_disk_mb ,
                            a.io_stall_read_ms ,
                            a.num_of_reads ,
              a.[num_of_bytes_read],
                            a.io_stall_write_ms ,
                            a.num_of_writes ,
              a.[num_of_bytes_written],
                            b.physical_name
                    FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS a
                            INNER JOIN sys.master_files AS b ON a.file_id = b.file_id
                                                                AND a.database_id = b.database_id
                    WHERE   a.num_of_reads > 0
                            AND a.num_of_writes > 0;

            SET @msg = CONVERT(CHAR(23), CURRENT_TIMESTAMP, 121) + N': Completed sample ' + CAST(@current_interval AS NVARCHAR(4)) + N' of '
                + CAST(@intervals AS NVARCHAR(4)) + '.'
            RAISERROR (@msg,0,1) WITH NOWAIT;
  
            SET @current_interval = @current_interval + 1;

            IF @current_interval <= @intervals 
                WAITFOR DELAY @delay;
        END
GO


/* 
Let's take two samples 30 seconds apart
*/
EXEC #get_file_wait_data @intervals = 2, @delay = '00:00:30.000';
GO


/* 
What was the storage throughput during the sample?
*/
with max_batch as (
  select top 1 batch_id, sample_time
  from #file_wait_batches
  order by batch_id desc
)
SELECT  mb.sample_time as final_sample_time, 
    datediff(ss,wb1.sample_time, mb.sample_time) as sample_duration_seconds,
    wd1.db_name ,
        wd1.file_logical_name ,
        UPPER(SUBSTRING(wd1.physical_name, 1, 2)) AS disk_location ,
        wd1.size_on_disk_mb ,
        ( wd2.io_stall_read_ms - wd1.io_stall_read_ms ) AS diff_io_stall_read_ms ,
        ( wd2.num_of_reads - wd1.num_of_reads ) AS diff_num_reads ,
        CASE WHEN wd2.num_of_reads - wd1.num_of_reads > 0
      THEN CAST(( wd2.bytes_read - wd1.bytes_read)/1024./1024. AS NUMERIC(21,1)) 
      ELSE 0 
    END AS diff_MB_read ,
        CASE WHEN wd2.num_of_reads - wd1.num_of_reads > 0
             THEN CAST(( wd2.io_stall_read_ms - wd1.io_stall_read_ms ) / ( 1.0 * ( wd2.num_of_reads - wd1.num_of_reads ) ) AS INT)
             ELSE 0
        END AS avg_read_stall_ms ,
        ( wd2.io_stall_write_ms - wd1.io_stall_write_ms ) AS diff_io_stall_write_ms ,
        ( wd2.num_of_writes - wd1.num_of_writes ) AS diff_num_writes ,
        CASE WHEN wd2.num_of_writes - wd1.num_of_writes > 0
      THEN CAST(( wd2.bytes_written - wd1.bytes_written)/1024./1024. AS NUMERIC(21,1)) 
      ELSE 0 
    END AS diff_MB_written ,
        CASE WHEN wd2.num_of_writes - wd1.num_of_writes > 0
             THEN CAST(( wd2.io_stall_write_ms - wd1.io_stall_write_ms ) / ( 1.0 * ( wd2.num_of_writes - wd1.num_of_writes ) ) AS INT)
             ELSE 0
        END AS avg_write_stall_ms ,
        wd1.physical_name
FROM    max_batch mb
        JOIN #file_wait_data wd2 ON mb.batch_id=wd2.batch_id
    JOIN #file_wait_data wd1 ON wd2.batch_id-1= wd1.batch_id
      AND wd1.physical_name = wd2.physical_name
    JOIN #file_wait_batches wb1 on wd1.batch_id=wb1.batch_id
ORDER BY avg_read_stall_ms DESC;
GO

/* ------------------------------------------------ */
/* END SECTION: Storage throughput by database file */
/* ------------------------------------------------ */
