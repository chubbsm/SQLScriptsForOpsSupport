SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SELECT TOP 1000 r.modification_time, d.name AS database_name, r.file_id, r.page_id, r.error_type, r.page_status
  FROM sys.dm_db_mirroring_auto_page_repair r
  INNER JOIN sys.databases d ON r.database_id = d.database_id
  ORDER BY r.modification_time DESC;
