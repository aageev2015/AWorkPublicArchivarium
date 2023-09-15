/*
// create

create table tmp_stat (
	table_name nvarchar(100) not null primary key,
	count1 int default(0),
	count2 int default(0),
	count3 int default(0),
	count4 int default(0),
	count5 int default(0)
)

// init data
insert into tmp_stat (table_name) select table_schema + '.' +table_name from INFORMATION_SCHEMA.tables
where table_type='BASE TABLE'

// select all
select * from tmp_stat
order by table_name

// select changes
select * from tmp_stat
where count1<>count2
order by table_name

// drop 
drop table tmp_stat

*/




declare @sql nvarchar(max) = ''
select 
@sql = @sql + 'update tmp_stat set count1 = (select count(*) from ' + t.TABLE_SCHEMA + '.[' + t.TABLE_NAME + '] with(nolock)) where table_name = ''' + s.table_name + '''
'
from INFORMATION_SCHEMA.tables t
inner join tmp_stat s on s.table_name = t.TABLE_SCHEMA + '.' + t.TABLE_NAME

exec (@sql)

