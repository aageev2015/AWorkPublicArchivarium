select 
replace(
'print ''%1''
ALTER INDEX ALL ON [%1] REBUILD
GO
'
, '%1', t.table_name) [rebuild_index_sql],
	replace(
'print ''%1''
select ''%1'' TableName, count(*) cnt from [%1] with(nolock)
go
', '%1', t.table_name) [counts_separate_sql],
	replace(
'union select ''%1'' TableName, count(*) cnt from [%1] with(nolock)
', '%1', t.table_name) [counts_union_sql],
	replace(replace(
'
select isnull(cr.id, t14.id) [%1.id], ''fresh->'' [fresh->], cr.*, ''before-fresh->'' [before-fresh->], t14.* from [%1] cr
full join server333.AwesomeSystemV0_202001110342.dbo.[%1] t14 on cr.id=t14.id
where cr.id is null or t14.id is null or cr.[%2] <> t14.[%2]
', '%1', t.table_name)
, '%2', c.COLUMN_NAME) [data_delta]
from INFORMATION_SCHEMA.tables t
inner join INFORMATION_SCHEMA.COLUMNS c on c.TABLE_NAME = t.TABLE_NAME and c.DATA_TYPE =  'timestamp'
where table_type = 'BASE TABLE'
--and t.table_name not in ('stock', 'history')