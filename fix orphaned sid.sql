/** REPORT **/

Select 	*
	from sys.database_principals dp
	inner join sys.server_principals sp
	on dp.name = sp.name 
	where 
		dp.is_fixed_role = 0
	and dp.type_desc = 'SQL_USER'
	and (dp.sid is not null and dp.sid <> 0x0)	
	and sp.sid <> dp.sid 
	and dp.principal_id > 1
	order by dp.name

--Only works for SQL 2005 SP2 or later!

/** FIX ORPHANS **/
go
DECLARE @SQL varchar(100)
DECLARE curSQL CURSOR FOR

	Select 	'ALTER USER [' + dp.name + '] WITH LOGIN = [' + dp.name + ']'
	from sys.database_principals dp
	inner join sys.server_principals sp
	on dp.name = sp.name 
	where 
		dp.is_fixed_role = 0
	and dp.type_desc = 'SQL_USER'
	and (dp.sid is not null and dp.sid <> 0x0)	
	and sp.sid <> dp.sid 
	and dp.principal_id > 1
	order by dp.name

OPEN curSQL
FETCH curSQL into @SQL
WHILE @@FETCH_STATUS = 0
BEGIN
	print @SQL
	EXEC (@SQL)
	FETCH curSQL into @SQL
END
CLOSE curSQL
DEALLOCATE curSQL
go
/** REPORT **/

Select 	*
	from sys.database_principals dp
	inner join sys.server_principals sp
	on dp.name = sp.name 
	where 
		dp.is_fixed_role = 0
	and dp.type_desc = 'SQL_USER'
	and (dp.sid is not null and dp.sid <> 0x0)	
	and sp.sid <> dp.sid 
	and dp.principal_id > 1
	order by dp.name

/***** OLD ********/
/*
select * from sysusers
where issqluser = 1 and (sid is not null and sid <> 0x0) and suser_sname(sid) is null
order by name

--Only works for SQL 2005 SP2 or later!
GO
DECLARE @SQL varchar(100)
DECLARE curSQL CURSOR FOR
	Select 	'ALTER USER [' + name + '] WITH LOGIN = [' + name + ']'
	from sysusers
	where issqluser = 1 	and (sid is not null and sid <> 0x0)	and suser_sname(sid) is null
	order by name
OPEN curSQL
FETCH curSQL into @SQL
WHILE @@FETCH_STATUS = 0
BEGIN
	print @SQL
	EXEC (@SQL)
	FETCH curSQL into @SQL
END
CLOSE curSQL
DEALLOCATE curSQL

GO
*/