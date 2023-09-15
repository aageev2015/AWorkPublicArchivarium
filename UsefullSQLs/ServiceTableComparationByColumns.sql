declare @TableName varchar(250)
declare @DatabaseLeft varchar(250)
declare @DatabaseRight varchar(250)
set @TableName='''tbl_Report'''
set @DatabaseLeft='tourism304'
set @DatabaseRight='mycrm311x15'

declare @sql varchar(4000)
set @sql=N'

select t2.name as TableName, c2.name LeftColumnName, c2.colid as LeftColID, c2.xtype LeftColumnType,
c3.name RightColumnName, c3.xtype RightColumnType, c3.colid as RightColID
into #tmpTable
from '+@DatabaseLeft+'..sysobjects t2
inner join '+@DatabaseLeft+'..syscolumns c2 on (
	t2.id=c2.id
)
left join '+@DatabaseRight+'..sysobjects t3 on (
	t2.name=t3.name
)
left join '+@DatabaseRight+'..syscolumns c3 on (
	t3.id=c3.id
	and c3.name=c2.name
)
where t2.name in ('+@TableName+')
union
select t2.name as TableName, c3.name LeftColumnName, c3.xtype LeftColumnType, c3.colid as LeftColID,
c2.name RightColumnName, c2.xtype RightColumnType, c2.colid as RightColID
from '+@DatabaseRight+'..sysobjects t2
inner join '+@DatabaseRight+'..syscolumns c2 on (
	t2.id=c2.id
)
left join '+@DatabaseLeft+'..sysobjects t3 on (
	t2.name=t3.name
)
left join '+@DatabaseLeft+'..syscolumns c3 on (
	t3.id=c3.id
	and c3.name=c2.name
)
where t2.name in ('+@TableName+')
and c3.id is null

select * from #tmpTable
order by tableName, (RightcolumnName+LeftColumnName),LeftColumnName desc

drop table #tmpTable'

exec(@sql)


