
SELECT 
--DB_NAME(CAST(pa.value AS int)) dbname,
st.text,
SUBSTRING(st.text, qs.statement_start_offset / 2 + 1, ( CASE qs.statement_end_offset
                                                                   WHEN-1
                                                                   THEN DATALENGTH(st.text)
                                                                   ELSE qs.statement_end_offset
                                                               END - qs.statement_start_offset ) / 2 + 1) AS statement_text
,
	   qs.execution_count,
       qs.total_worker_time,
       qs.total_worker_time / qs.execution_count AS 'Avg CPU Time',
       qs.total_physical_reads,
       qs.total_physical_reads / qs.execution_count AS 'Avg Physical Reads',
       qs.total_logical_reads,
       qs.total_logical_reads / qs.execution_count AS 'Avg Logical Reads',
       qs.total_logical_writes,
       qs.total_logical_writes / qs.execution_count AS 'Avg Logical Writes'
FROM sys.dm_exec_query_stats AS qs
     CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS st
	--OUTER APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa 
ORDER BY qs.total_worker_time DESC;


