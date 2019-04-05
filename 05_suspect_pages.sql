SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SELECT TOP 1000 sp.last_update_date, d.name AS database_name, sp.database_id, sp.file_id, sp.page_id, sp.event_type, sp.error_count
  FROM msdb.dbo.suspect_pages sp
  INNER JOIN sys.databases d ON sp.database_id = d.database_id
  ORDER BY sp.last_update_date DESC;
