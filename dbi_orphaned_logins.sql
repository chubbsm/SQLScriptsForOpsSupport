/**************************************************
*	dbi-services SA, Switzerland				  *
*	http://www.dbi-services.com					  *
***************************************************
	Group/Privileges.: DBA
	Script Name......: dbi_orphaned_logins.sql
	Author...........: Stéphane Haby (STH)
	Date.............: November 2014
	Version..........: SQL Server 2008/2012/2014
	Description......: Search all logins without link in the instance
	Input parameters.:
	Output parameters: list of logins name and id
	Called by........:
***************************************************
	Historical
	Date        Version   Who        Whats
	----------  -------   --------   --------------
	26.11.2014      1.0   STH        Creation
***************************************************/

CREATE TABLE #temp_login_1 (id varbinary(85))
CREATE TABLE #temp_login_2 (id varbinary(85))

EXEC sp_MSforeachdb 'INSERT INTO #temp_login_1
SELECT sid from [?].[sys].[sysusers] WHERE islogin=1 AND name NOT LIKE ''##MS_%'' AND name NOT IN (''sys'',''guest'')'

INSERT INTO #temp_login_2
SELECT sid FROM sys.syslogins WHERE name NOT LIKE 'NT %' AND name NOT LIKE '##MS_%' AND name <> 'sa'
AND sysadmin = 0 AND securityadmin = 0 AND bulkadmin = 0 AND dbcreator = 0 AND diskadmin = 0 AND processadmin = 0 
AND serveradmin= 0 AND setupadmin=0
EXCEPT
SELECT id FROM #temp_login_1

DELETE FROM #temp_login_1

INSERT INTO #temp_login_1
SELECT id FROM #temp_login_2
EXCEPT
SELECT srvprin.sid FROM  [sys].[server_principals] srvprin
INNER JOIN [sys].[server_permissions] srvperm ON [srvperm].[grantee_principal_id] = [srvprin].[principal_id] 
WHERE [srvprin].[type] IN ('S', 'U', 'G')AND  [srvperm].permission_name<>'CONNECT SQL' 
AND [srvprin].[name] NOT LIKE  '%##%' AND [srvprin].[name] NOT LIKE 'NT AUTHORITY\SYSTEM'

SELECT [logins].name,[logins].sid FROM [sys].[syslogins] logins INNER JOIN #temp_login_1 exception ON [logins].sid=exception.id

DROP TABLE #temp_login_2
DROP TABLE #temp_login_1

 