
SELECT  'DROP INDEX [' + I.[NAME] + '] ON [' + sc.name + '].[' + o.name + ']',
		o.name,
         I.[NAME] AS [INDEX NAME],
         s.USER_SEEKS,
         s.USER_SCANS,
         s.USER_LOOKUPS,
         s.USER_UPDATES, 
		 ps.row_count,
		 SizeMb= (ps.in_row_reserved_page_count*8.)/1024.,
		 s.last_user_lookup,
		 s.last_user_scan,
		 s.last_user_seek,
		 s.last_user_update
		 --, *
FROM     SYS.DM_DB_INDEX_USAGE_STATS S
         INNER JOIN SYS.INDEXES I
           ON I.[OBJECT_ID] = S.[OBJECT_ID]
              AND I.INDEX_ID = S.INDEX_ID
		 inner join sys.objects o 
			on o.object_id = i.object_id
		inner join sys.schemas sc
			on sc.schema_id = o.schema_id
		inner join sys.partitions pr 
			on pr.object_id = i.object_id 
			and pr.index_id = i.index_id
		inner join sys.dm_db_partition_stats ps
			on ps.object_id = i.object_id
			and ps.partition_id = pr.partition_id
WHERE    o.is_ms_shipped = 0
--and o.type_desc = 'USER_TABLE'
and i.type_desc = 'NONCLUSTERED'
and user_updates / 10. > (user_seeks + user_scans + user_lookups )
--and o.name in ('ContactBase')
--and o.name not like '%cascade%'
--order by [OBJECT NAME]
and is_unique = 0
and is_primary_key = 0
and is_unique_constraint = 0
--and (ps.in_row_reserved_page_count) > 1280 --10mb
order by user_seeks + user_scans + user_lookups  asc,  s.user_updates desc

/*
--mscrm
DROP INDEX [ndx_Auditing] ON [dbo].[ContactBase]
DROP INDEX [ndx_SystemManaged] ON [dbo].[AsyncOperationBase]
DROP INDEX [ndx_StartedOn_AsyncOperation] ON [dbo].[AsyncOperationBase]
DROP INDEX [ndx_RequestId_AsyncOperation] ON [dbo].[AsyncOperationBase]
DROP INDEX [ndx_for_cascaderelationship_lead_accounts] ON [dbo].[AccountLeads]
DROP INDEX [IDX_NC_AsyncOperationBase_DeletionStateCode] ON [dbo].[AsyncOperationBase]
DROP INDEX [IDX_NC_AsyncOperationBase_OperationType_WorkflowActivationId] ON [dbo].[AsyncOperationBase]
DROP INDEX [ndx_RegardingObjectId_AsyncOperation] ON [dbo].[AsyncOperationBase]
*/