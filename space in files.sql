
exec sp_MSforeachdb  'use [?]; 
SELECT 
  ''DatabaseName_____________'' = d.name
, Recovery = d.recovery_model_desc
, ''DatabaseFileName_______'' = df.name
, ''Location_______________________________________________________________________'' = df.physical_name
, df.File_ID
, FileSizeMB = CAST(size/128.0 as Decimal(9,2))
, SpaceUsedMB = CAST(CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, AvailableMB =  CAST(size/128.0 - CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0 as Decimal(9,2))
, ''Free%'' = CAST((((size/128.0) - (CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS int)/128.0)) / (size/128.0) ) * 100. as Decimal(9,2))
 FROM sys.database_files df
 cross apply sys.databases d
 where d.database_id = DB_ID() 
 and size > 0
'
/*
use RAM_LIVE;
DBCC SHRINKFILE (N'RAMI_LIVE' , 51000)
DBCC SHRINKFILE (N'RAMI_LIVE_log' , 100)
*/

/*
SELECT 
  'DatabaseName_____________' = d.name
, Recovery = d.recovery_model_desc
, 'DatabaseFileName_______' = df.name
, 'Location_______________________________________________________________________' = df.physical_name
, df.File_ID
, FileSizeMB = CAST(size/128.0 as Decimal(9,2))
, SpaceUsedMB = CAST(CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS int)/128. as Decimal(9,2))
, AvailableMB =  CAST(size/128.0 - CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS int)/128.0 as Decimal(9,2))
, 'Free%' = CAST((((size/128.0) - (CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS int)/128.0)) / (size/128.0) ) * 100. as Decimal(9,2))
 FROM sys.database_files df
 cross apply sys.databases d
 where d.database_id = DB_ID() 

GO

select * from sys.database_files df


DBCC PAGE ( 2 , 1 , 103 , 3 )


SELECT DB_NAME(database_id) as database_name, physical_name, SizeMB = (size*8./1024.) , *
FROM sys.master_files mf
WHERE DB_NAME(database_id) = 'tempdb'


tempdb	SIMPLE	tempdev	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb.mdf	350.00	2.81	347.19	99.20
tempdb	SIMPLE	templog	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\templog.ldf	9.94	1.81	8.13	81.76
tempdb	SIMPLE	tempdev2	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb2.ndf	350.00	0.06	349.94	99.98

tempdb	SIMPLE	tempdev	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb.mdf	350.00	3.63	346.38	98.96
tempdb	SIMPLE	templog	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\templog.ldf	9.94	1.95	7.98	80.35
tempdb	SIMPLE	tempdev2	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb2.ndf	350.00	0.19	349.81	99.95

tempdb	SIMPLE	tempdev	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb.mdf	350.00	3.19	346.81	99.09
tempdb	SIMPLE	templog	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\templog.ldf	9.94	2.29	7.65	76.97
tempdb	SIMPLE	tempdev2	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb2.ndf	350.00	0.13	349.88	99.96

tempdb	SIMPLE	tempdev	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb.mdf	1329.56	1093.25	236.31	17.77
tempdb	SIMPLE	templog	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\templog.ldf	10.94	10.45	0.49	4.50
tempdb	SIMPLE	tempdev2	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb2.ndf	1329.56	958.63	370.94	27.90

tempdb	SIMPLE	tempdev	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb.mdf	1329.56	3.38	1326.19	99.75
tempdb	SIMPLE	templog	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\templog.ldf	10.94	1.45	9.48	86.71
tempdb	SIMPLE	tempdev2	S:\MSSQL\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\tempdb2.ndf	1329.56	0.25	1329.31	99.98


create table #tempfiller
(text1 char(8000)
)
go
insert into #tempfiller values ('a')
insert into #tempfiller
select TEXT1 from #tempfiller
go 100
drop table #tempfiller
*/