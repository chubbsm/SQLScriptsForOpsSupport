--sql2005 and above
select 
	database_Name
	, backuptype 
	, d.recovery_model_desc
	, BackupDate = MAX(BackupDate)
	, d.state_desc
 from sys.databases d
 inner join 
 (
select distinct 
	database_name
	, backuptype = case type	WHEN 'D' then 'Database'
							WHEN 'I' then 'Differential database'
							WHEN 'L' then 'Transaction Log'
							WHEN 'F' then 'File or filegroup'
							WHEN 'G' then 'Differential file'
							WHEN 'P' then 'Partial'
							WHEN 'Q' then 'Differential partial' END
	, BackupDate	=	MAX(backup_start_date)  	
	from msdb.dbo.backupset bs							
 group by Database_name, type
 UNION 
 select distinct
	db_name(d.database_id)
	, backuptype = 'Database'
	, null
	FROM master.sys.databases d
 UNION
 select distinct
	db_name(d.database_id)
	, backuptype = 'Transaction Log'
	, null
  FROM master.sys.databases d
  where d.recovery_model_desc in ('FULL', 'BULK_LOGGED')
  
 ) a
 on db_name(d.database_id) = a.database_name
 group by database_name, backuptype, d.recovery_model_desc, d.state_desc
order by backuptype, recovery_model_desc, database_name asc
 
 go
 
 /*

 --sql 2000 and above
select distinct 
	database_name	= d.name 
	, a.backuptype	
	, RecoveryModel	=	databasepropertyex(d.name, 'Recovery')  
	, BackupDate	=	Max(a.backup_start_date)  
	from master.dbo.sysdatabases d
	left outer join 
	(		select distinct 
			database_name
			, backuptype = case type	WHEN 'D' then 'Database'
									WHEN 'I' then 'Differential database'
									WHEN 'L' then 'Transaction Log'
									WHEN 'F' then 'File or filegroup'
									WHEN 'G' then 'Differential file'
									WHEN 'P' then 'Partial'
									WHEN 'Q' then 'Differential partial' END
			, backup_start_date	=	MAX(backup_start_date)  	
			from msdb.dbo.backupset bs							
		 group by Database_name, type
		 UNION 
		 select distinct
			  d.name
			, backuptype = 'Database'
			, null
			FROM master.dbo.sysdatabases d
		 UNION
		 select distinct
			  d.name
			, backuptype = 'Transaction Log'
			, null
		  FROM master.dbo.sysdatabases d
		  where databasepropertyex(d.name, 'Recovery') in ('FULL', 'BULK_LOGGED')
  
 ) a
	on d.name = a.database_name
 group by d.name , backuptype ,	databasepropertyex(d.name, 'Recovery')
order by backuptype, RecoveryModel, BackupDate asc
 

--granual backup history
select distinct 
	database_name
	, type
	, backuptype = case type	WHEN 'D' then 'Database'
							WHEN 'I' then 'Differential database'
							WHEN 'L' then 'Transaction Log'
							WHEN 'F' then 'File or filegroup'
							WHEN 'G' then 'Differential file'
							WHEN 'P' then 'Partial'
							WHEN 'Q' then 'Differential partial' END
	, BackupDate	=	backup_start_date
	, database_backup_lsn
	, bf.physical_device_name
	--, begins_log_chain
	from msdb.dbo.backupset bs	
	left outer join msdb.dbo.[backupmediafamily] bf
	on bs.[media_set_id] = bf.[media_set_id]
	--where database_name = 'WSS_Content_Spot_Projects'
	--and type in ('d', 'i')
 
  order by database_name asc, backupdate desc
  

*/
