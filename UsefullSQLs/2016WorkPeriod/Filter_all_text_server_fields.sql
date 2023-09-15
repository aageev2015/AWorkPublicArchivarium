declare @search nvarchar(200)
set @search = ''

declare @sql varchar(max)
set @sql = ''

create table #columns(
	column_fullname varchar(200)
)

select @sql=@sql+'
union select ''[''+table_catalog+''].[''+table_name+''].[''+column_nam+'']'' e as column_full_name from '+name+'.information_schema.columns
where data_type in (''varchar'',''nvarchar'')'
from [master]..sysdatabases
where name not in  ('master','tempdb','','model','msdb')

set @sql = 'insert into #columns select * from (
' + substring(@sql, 9, len(@sql)) + '
) t'

print @sql

exec (@sql)

select * from #columns


set @sql=''

select '
union select ' from #columns

drop table #columns



