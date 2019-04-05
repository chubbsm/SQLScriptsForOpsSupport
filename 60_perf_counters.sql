/* ----------------------------------- */
/* BEGIN SECTION: Performance counters */
/* ----------------------------------- */

--Set the collection_interval here
--Then run the whole script. 


/*Collect second sample.*/
INSERT  tempdb..sql_counters_data
        ( [batch_id] , [object_name] , [counter_name] , [instance_name] , [cntr_value] )
        SELECT  2 AS [batch_id] ,
                CAST(RTRIM(perf.[object_name]) AS VARCHAR(128)) ,
                CAST(RTRIM(perf.[counter_name]) AS VARCHAR(128)) ,
                CAST(RTRIM(perf.[instance_name]) AS VARCHAR(128)) ,
                perf.[cntr_value]
        FROM    sys.[dm_os_performance_counters] AS perf
                JOIN tempdb..sql_counters_list ctrs ON RTRIM(perf.[counter_name]) COLLATE SQL_Latin1_General_CP1_CI_AS = ctrs.[counter_name] COLLATE SQL_Latin1_General_CP1_CI_AS
                                                AND ( ctrs.[instance_name] IS NULL
                                                     OR ( RTRIM(perf.[instance_name]) COLLATE SQL_Latin1_General_CP1_CI_AS = ctrs.[instance_name] COLLATE SQL_Latin1_General_CP1_CI_AS)
												) AND perf.[cntr_type] = ctrs.[cntr_type]
        WHERE   CHARINDEX(ctrs.[object_name] COLLATE SQL_Latin1_General_CP1_CI_AS, perf.[object_name] COLLATE SQL_Latin1_General_CP1_CI_AS) > 0;
                                               
/*Return the difference*/
/*Group 1: frequently useful.*/
;WITH    [perf_sample]
          AS ( SELECT   [batch_id] ,
                        [collection_time] ,
                        [object_name] ,
                        [counter_name] ,
                        [instance_name] ,
                        [cntr_value]
               FROM     tempdb..sql_counters_data
             )
    SELECT  COALESCE(DATEDIFF(ss, [sample_1].[collection_time], [sample_2].[collection_time]),0) AS [Seconds] ,
            COALESCE([sample_1].[object_name],ctrs.[object_name]) AS [Perf Object] ,
            COALESCE([sample_1].[counter_name],ctrs.[counter_name]) AS [Perf Counter] ,
			CASE WHEN [ctrs].cntr_type = 272696576 /*per-sec counters, cumulative*/ THEN
				CASE WHEN [sample_2].[cntr_value] > [sample_1].[cntr_value]
					 THEN [sample_2].[cntr_value] - [sample_1].[cntr_value]
					 ELSE 0
				END 
			ELSE [sample_2].[cntr_value] /*if not a per-sec counter, just take the second sample's value*/
			END
				AS [Total Count] ,
			CASE WHEN [ctrs].cntr_type = 272696576 /*per-sec counters, cumulative*/ THEN
				CASE WHEN [sample_2].[cntr_value] > [sample_1].[cntr_value]
					 THEN CAST(( [sample_2].[cntr_value] - [sample_1].[cntr_value] ) / 
						( 1.0 * DATEDIFF(ss,[sample_1].[collection_time],[sample_2].[collection_time]) ) 
						AS NUMERIC(20,1))
					 ELSE 0
				END
			ELSE NULL /*Not a per-sec counter-- leave it blank*/
            END AS [Average Per Sec] ,
            ctrs.[brent_ozar_unlimited_note] AS [Brent Ozar Unlimited Note]
    FROM   tempdb..sql_counters_list ctrs
		LEFT OUTER JOIN [perf_sample] AS sample_1 ON [sample_1].[counter_name] = ctrs.[counter_name] AND
			[sample_1].[batch_id] = 1      
        LEFT OUTER JOIN [perf_sample] AS sample_2 ON [sample_2].[batch_id] = [sample_1].[batch_id] + 1
			AND [sample_2].[object_name] = [sample_1].[object_name]
            AND [sample_2].[counter_name] = [sample_1].[counter_name]
            AND [sample_2].[instance_name] = [sample_2].[instance_name]
	WHERE ctrs.display_group=1
		AND (ctrs.counter_name='' OR [sample_1].[counter_name] IS NOT NULL)
    ORDER BY ctrs.display_order;


/*Group 2: Detailed trending/ extra info.*/
;WITH    [perf_sample]
          AS ( SELECT   [batch_id] ,
                        [collection_time] ,
                        [object_name] ,
                        [counter_name] ,
                        [instance_name] ,
                        [cntr_value]
               FROM     tempdb..sql_counters_data
             )
    SELECT  COALESCE(DATEDIFF(ss, [sample_1].[collection_time], [sample_2].[collection_time]),0) AS [Seconds] ,
            COALESCE([sample_1].[object_name],ctrs.[object_name]) AS [Perf Object] ,
            COALESCE([sample_1].[counter_name],ctrs.[counter_name]) AS [Perf Counter] ,
			CASE WHEN [ctrs].cntr_type = 272696576 /*per-sec counters, cumulative*/ THEN
				CASE WHEN [sample_2].[cntr_value] > [sample_1].[cntr_value]
					 THEN [sample_2].[cntr_value] - [sample_1].[cntr_value]
					 ELSE 0
				END 
			ELSE [sample_2].[cntr_value] /*if not a per-sec counter, just take the second sample's value*/
			END
				AS [Total Count] ,
			CASE WHEN [ctrs].cntr_type = 272696576 /*per-sec counters, cumulative*/ THEN
				CASE WHEN [sample_2].[cntr_value] > [sample_1].[cntr_value]
					 THEN CAST(( [sample_2].[cntr_value] - [sample_1].[cntr_value] ) / 
						( 1.0 * DATEDIFF(ss,[sample_1].[collection_time],[sample_2].[collection_time]) ) 
						AS NUMERIC(20,1))
					 ELSE 0
				END
			ELSE NULL /*Not a per-sec counter-- leave it blank*/
            END AS [Average Per Sec] ,
            ctrs.[brent_ozar_unlimited_note] AS [Brent Ozar Unlimited Note]
    FROM   tempdb..sql_counters_list ctrs
		LEFT OUTER JOIN [perf_sample] AS sample_1 ON [sample_1].[counter_name] = ctrs.[counter_name] AND
			[sample_1].[batch_id] = 1      
        LEFT OUTER JOIN [perf_sample] AS sample_2 ON [sample_2].[batch_id] = [sample_1].[batch_id] + 1
			AND [sample_2].[object_name] = [sample_1].[object_name]
            AND [sample_2].[counter_name] = [sample_1].[counter_name]
            AND [sample_2].[instance_name] = [sample_2].[instance_name]
	WHERE ctrs.display_group=2
		AND (ctrs.counter_name='' OR [sample_1].[counter_name] IS NOT NULL)
    ORDER BY ctrs.display_order;


/* --------------------------------- */
/* END SECTION: Performance counters */
/* --------------------------------- */

    IF OBJECT_ID('tempdb..tempdb..sql_counters_list') IS NOT NULL
        DROP TABLE tempdb..sql_counters_list;
    IF OBJECT_ID('tempdb..tempdb..sql_counters_data') IS NOT NULL
        DROP TABLE tempdb..sql_counters_data;
