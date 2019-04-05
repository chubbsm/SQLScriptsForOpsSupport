
--based on the ideas from
--http://sqlblog.com/blogs/aaron_bertrand/archive/2008/05/06/when-was-my-database-table-last-accessed.aspx

;WITH ServerStarted AS
(
SELECT 
  MIN(last_user_seek) AS first_seek,  
  MIN(last_user_scan) AS first_scan, 
  MIN(last_user_lookup) AS first_lookup 
FROM sys.dm_db_index_usage_stats
),
ServerFirst AS
(
SELECT 
  CASE 
    WHEN first_seek <   first_scan AND first_seek <   first_lookup
    THEN first_seek
    WHEN first_scan <   first_seek AND first_scan <   first_lookup
    THEN first_scan
    ELSE first_lookup
  END AS usage_start_date
FROM ServerStarted             
),
myCTE AS
(
SELECT
  DB_NAME(database_id) AS TheDatabase,
  last_user_seek,
  last_user_scan,
  last_user_lookup,
  last_user_update
FROM sys.dm_db_index_usage_stats
)
SELECT
  MIN(ServerFirst.usage_start_date) AS usage_start_date,
  x.TheDatabase,
  MAX(x.last_read) AS  last_read,
  MAX(x.last_write) AS last_write
FROM
(
SELECT TheDatabase,last_user_seek AS last_read, NULL AS last_write FROM myCTE
  UNION ALL
SELECT TheDatabase,last_user_scan, NULL FROM myCTE
  UNION ALL
SELECT TheDatabase,last_user_lookup, NULL FROM myCTE
  UNION ALL
SELECT TheDatabase,NULL, last_user_update FROM myCTE
) AS x
CROSS JOIN ServerFirst 
GROUP BY TheDatabase

