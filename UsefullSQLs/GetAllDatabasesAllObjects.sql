declare @sql nvarchar(max) = 'select null,null, null where 1=0 '
SELECT @sql=@sql+' union select ''' + Name + ''' collate Cyrillic_General_CI_AS as DBName, name collate Cyrillic_General_CI_AS as TName, Xtype collate Cyrillic_General_CI_AS as xtype from [' + name + '].dbo.sysobjects'
--set @sql = 'select * from (' + @sql + ') as t where t.Name = '''+
FROM sys.databases

declare @tmp table (
	DBName nvarchar(250)
,	Name nvarchar(250)
,	Xtype nvarchar(15)
)
print @sql
insert into @tmp
exec (@sql);
select * from @tmp