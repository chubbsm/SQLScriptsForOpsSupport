DECLARE @StringToExecute NVARCHAR(4000)

/* Last startup */
SELECT
    CAST(create_date AS VARCHAR(100)) as Last_Startup,
    CAST(DATEDIFF(hh,create_date,getdate())/24. as numeric (23,2)) AS days_uptime
FROM    sys.databases
WHERE   database_id = 2;


IF EXISTS (SELECT * FROM sys.dm_os_performance_counters)
	SELECT
		TOP 1 COALESCE(CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(100)),LEFT(object_name, (CHARINDEX(':', object_name) - 1))) as MachineName,
		ISNULL(CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(100)),'(default instance)') as InstanceName,
		CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(100)) as ProductVersion,
		CAST(SERVERPROPERTY('ProductLevel') AS NVARCHAR(100)) as PatchLevel,
		CAST(SERVERPROPERTY('Edition') AS VARCHAR(100)) as Edition,
		CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(100)) as IsClustered,
		CAST(COALESCE(SERVERPROPERTY('IsHadrEnabled'),0) AS VARCHAR(100)) as AlwaysOnEnabled,
		'' AS Warning
	FROM sys.dm_os_performance_counters;
ELSE
	SELECT
		TOP 1 (CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(100))) as MachineName,
		ISNULL(CAST(SERVERPROPERTY('InstanceName') AS NVARCHAR(100)),'(default instance)') as InstanceName,
		CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(100)) as ProductVersion,
		CAST(SERVERPROPERTY('ProductLevel') AS NVARCHAR(100)) as PatchLevel,
		CAST(SERVERPROPERTY('Edition') AS VARCHAR(100)) as Edition,
		CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(100)) as IsClustered,
		CAST(COALESCE(SERVERPROPERTY('IsHadrEnabled'),0) AS VARCHAR(100)) as AlwaysOnEnabled,
		'WARNING - No records found in sys.dm_os_performance_counters' AS Warning


/* Sys info, SQL 2012 and higher */
IF EXISTS ( SELECT  *
			FROM    sys.all_objects o
					INNER JOIN sys.all_columns c ON o.object_id = c.object_id
			WHERE   o.name = 'dm_os_sys_info'
					AND c.name = 'physical_memory_kb' )
	BEGIN
		SET @StringToExecute = '
        SELECT
            cpu_count,
            CAST(ROUND((physical_memory_kb / 1024.0 / 1024), 1) AS INT) as physical_memory_GB
        FROM sys.dm_os_sys_info';
		EXECUTE(@StringToExecute);
	END


/* Sys info, SQL 2008R2 and prior */
ELSE IF EXISTS ( SELECT  *
			FROM    sys.all_objects o
					INNER JOIN sys.all_columns c ON o.object_id = c.object_id
			WHERE   o.name = 'dm_os_sys_info'
					AND c.name = 'physical_memory_in_bytes' )
BEGIN
		SET @StringToExecute = '
        SELECT
            cpu_count,
            CAST(ROUND((physical_memory_in_bytes / 1024.0 / 1024.0 / 1024.0 ), 1) AS INT) as physical_memory_GB
        FROM sys.dm_os_sys_info';
			EXECUTE(@StringToExecute);
END

