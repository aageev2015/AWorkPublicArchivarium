declare @searching nvarchar(50) = 'Bill'

select 'select null as [column], null as cnt from (select 1 t) k where 1=0'
union select 
    'union select '''+[Table_Name]+'.'+COLUMN_NAME+''' as [column], count(*) as cnt from ['+table_name+'] where ['+column_name+'] = '''+@searching+''''
from INFORMATION_SCHEMA.COLUMNS
where Data_type='nvarchar'