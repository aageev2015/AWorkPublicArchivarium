declare Cur cursor for
select Name,dbid from master.dbo.sysdatabases
order by Name

declare @DataBaseName varchar(250)
declare @dbid varchar(250)
declare @sql varchar(2000)
if exists(select * from sysobjects where name='#tmp') begin
	drop table #tmp
end;


create table #tmp (
	Name varchar(250),
	dbid varchar(250),
	IsTerrasoft int
)

open cur
while (1=1) begin
	FETCH NEXT FROM Cur INTO @DataBaseName,@dbid
	if @@FETCH_STATUS=-1 break
	if @@FETCH_STATUS=-2 continue
	set @sql='	
	declare @IsTerr int
	set @IsTerr=(case when exists((select 1 from ['+@DataBaseName+']..sysobjects where Name =''tbl_DatabaseInfo'')) then
			 1
			else
			  0
		end)
	insert into #tmp(Name, dbid, IsTerrasoft)
	values	(
		'''+@DataBaseName+''',
		'''+@dbid+''',
		@IsTerr
	)'
print @sql
	exec (@sql)
end

close cur
deallocate cur

select * From #tmp

drop table #tmp
