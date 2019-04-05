

select distinct 
vs.volume_Mount_point,
file_system_type,
   drive_size_GB = convert(decimal(19,2), vs.total_bytes/1024./1024./1024. ) , 
   drive_free_space_GB = convert(decimal(19,2), vs.available_bytes/1024./1024./1024. ), 
   drive_percent_free = CONVERT(DECIMAL(5,2), vs.available_bytes * 100.0 / vs.total_bytes)
FROM
   sys.master_files AS f
CROSS APPLY
   sys.dm_os_volume_stats(f.database_id, f.file_id) vs --only return volumes where there is database file (data or log)
 go
 
select distinct 
	DatabaseName			=	DB_NAME(f.database_id), 
	FileLocation			=	f.physical_name,
	Volume					=	vs.volume_Mount_point,
	FileSystemType			=	vs.file_system_type,
	FileMaxSize				=	convert(decimal(19,2), f.max_size/1024./1024. ) , 
	drive_size_GB			=	convert(decimal(19,2), vs.total_bytes/1024./1024./1024. ) , 
	drive_free_space_GB		=	convert(decimal(19,2), vs.available_bytes/1024./1024./1024. ), 
	drive_percent_free		=	convert(decimal(5,2), vs.available_bytes * 100.0 / vs.total_bytes)
FROM
   sys.master_files AS f
CROSS APPLY
   sys.dm_os_volume_stats(f.database_id, f.file_id) vs --only return volumes where there is database file (data or log)
where f.database_id < 32767 --ignore mssqlsystemresource
