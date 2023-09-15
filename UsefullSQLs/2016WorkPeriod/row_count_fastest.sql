SELECT
   Total_Rows= SUM(st.row_count)
FROM
   sys.dm_db_partition_stats st
WHERE
    object_name(object_id) = 'ITEM' AND (index_id < 2)



-- all
SELECT o.name, 
 ddps.row_count 
FROM sys.indexes AS i 
 INNER JOIN sys.objects AS o ON i.OBJECT_ID = o.OBJECT_ID 
 INNER JOIN sys.dm_db_partition_stats AS ddps ON i.OBJECT_ID = ddps.OBJECT_ID 
 AND i.index_id = ddps.index_id 
WHERE i.index_id < 2 
 AND o.is_ms_shipped = 0 
ORDER BY o.NAME 



-- not checked when table rows is currently used in transactions
select /*+ parallel(a) */  count(1) from ITEM a with(nolock)



http://www.codeproject.com/Tips/811017/Fastest-way-to-find-row-count-of-all-tables-in-SQL
-- another one
SELECT T.name AS [TABLE NAME], 
       I.rows AS [ROWCOUNT] 
FROM   sys.tables AS T 
       INNER JOIN sys.sysindexes AS I 
               ON T.object_id = I.id 
                  AND I.indid < 2 
ORDER  BY I.rows DESC 


-- another one
SELECT T.name      AS [TABLE NAME], 
       I.row_count AS [ROWCOUNT] 
FROM   sys.tables AS T 
       INNER JOIN sys.dm_db_partition_stats AS I 
               ON T.object_id = I.object_id 
                  AND I.index_id < 2 
ORDER  BY I.row_count DESC

