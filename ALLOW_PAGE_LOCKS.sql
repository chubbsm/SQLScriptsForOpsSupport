select 'alter INDEX [' + i.name + '] ON [' + s.name + '].[' + o.name + '] SET (ALLOW_PAGE_LOCKS = ON) --this is default'
, * from sys.indexes i
inner join sys.objects o on i.object_id  = o.object_id
inner join sys.schemas s on s.schema_id = o.schema_id
where allow_page_locks = 0
and o.is_ms_shipped = 0

--alter INDEX [Lamar_models_IDX1] ON [dbo].[Lamar_Models_save] SET (ALLOW_PAGE_LOCKS = ON) --this is default
