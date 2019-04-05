SELECT 
	mid.statement
,	create_index_statement	=	'CREATE NONCLUSTERED INDEX IDX_NC_' + replace(t.name, ' ' ,'')
	+ replace(replace(replace(ISNULL(replace(mid.equality_columns, ' ' ,''),'') , '],[' ,'_'),'[','_'),']','') 
	+ replace(replace(replace(ISNULL(replace(mid.inequality_columns, ' ' ,''),''), '],[' ,'_'),'[','_'),']','') 
	+ ' ON ' + statement 
	+ ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END 
    + ISNULL (mid.inequality_columns, '')
	+ ')' 
	+ ISNULL (' INCLUDE (' + mid.included_columns + ')', '')  COLLATE SQL_Latin1_General_CP1_CI_AS
,	unique_compiles, migs.user_seeks, migs.user_scans, last_user_seek, migs.avg_total_user_cost
, avg_user_impact, mid.equality_columns,  mid.inequality_columns, mid.included_columns
, quartile
--select *
FROM sys.dm_db_missing_index_groups mig
INNER JOIN --get only the top 20% of suggestions based on cost.
(select *, quartile = NTILE(5) OVER (ORDER BY avg_total_user_cost asc) from sys.dm_db_missing_index_group_stats) migs 
ON migs.group_handle = mig.index_group_handle
--and migs.quartile = 1
INNER JOIN sys.dm_db_missing_index_details mid 
ON mig.index_handle = mid.index_handle
inner join sys.tables t 
on t.object_id = mid.object_id
inner join sys.schemas s
on s.schema_id = t.schema_id
WHERE 1=1
and mid.database_id = db_id()
--and		(datediff(week, last_user_seek, getdate())) < 6
--AND		migs.unique_compiles > 10
--and		migs.quartile >= 3
--and		migs.user_seeks > 10
--and		migs.avg_user_impact > 75
--and		t.name like '%pt_time_salesorder_ids%'
--order by avg_user_impact * avg_total_user_cost desc 

order by create_index_statement

/*

CREATE NONCLUSTERED INDEX IDX_NC_tblBilling_Batch_ActionId ON [Sparkhound_Powertrak].[dbo].[tblBilling_Batch] ([ActionId])

*/