select (size*8.)/1024., * from sys.master_files mf
inner join sys.databases d
on mf.database_id = d.database_id
order by size desc

select sizemb = SUM(sizemb), tablename from (
select SizeMb= (p.in_row_reserved_page_count*8.)/1024., 
tablename = o.name, indexname = i.name
from sys.dm_db_partition_stats p
inner join sys.objects o on p.object_id = o.object_id 
inner join sys.indexes i on i.object_id = o.object_id and i.index_id = p.index_id
where o.is_ms_shipped = 0
) x
group by tablename
order by sizemb desc


select SizeMb= (p.in_row_reserved_page_count*8.)/1024.
,	indexname = i.name
,	tablename = '[' + s.name + '].[' + o.name + ']'
,	pr.data_compression_desc
,  rebuildcompress = 'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + o.name + '] REBUILD
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF
, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
, DATA_COMPRESSION = PAGE) ' + CHAR(10) + CHAR(13)
from sys.dm_db_partition_stats p
inner join sys.partitions pr on p.partition_id = pr.partition_id
inner join sys.objects o on p.object_id = o.object_id 
inner join sys.schemas s on s.schema_id = o.schema_id
left outer join sys.indexes i on i.object_id = o.object_id and i.index_id = p.index_id
WHERE o.is_ms_shipped = 0
order by SizeMb desc

