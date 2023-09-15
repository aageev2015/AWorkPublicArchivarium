
select '
if exists(select * from '+object_schema_name(o.id)+'.[' + o.name + '] where ['+c.name+'] like ''%ageev%'')
select ''' + o.name + ''', * from '+object_schema_name(o.id)+'.[' + o.name  + '] where ['+c.name+'] like ''%ageev%''
go
'
,   o.*, c.*
from sysobjects o
inner  join syscolumns c on c.id=o.id and c.type=39
where 
    --name='dm_exec_connections'
1=1
and o.xtype in ('V', 'S')
--and name='sysobjects'
and o.category=2

