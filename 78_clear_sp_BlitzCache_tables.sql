IF OBJECT_ID('tempdb.dbo.##bou_BlitzCacheProcs', 'U') IS NOT NULL
    EXEC ('DROP TABLE ##bou_BlitzCacheProcs;')

IF OBJECT_ID('tempdb.dbo.##bou_BlitzCacheResults', 'U') IS NOT NULL
    EXEC ('DROP TABLE ##bou_BlitzCacheResults;')
