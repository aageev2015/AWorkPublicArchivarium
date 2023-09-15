declare Cur cursor for
select t1.name from sysobjects t1
inner join syscolumns t2 on (
	t1.id=t2.id
	and t2.name='CreatedByID'
)
inner join syscolumns t3 on (
	t1.id=t3.id
	and t3.name='ModifiedByID'
)
where t1.type ='U'
order by t1.name

declare @TableName varchar(250)

create Table #tmp(
	TableName varchar(250),
	DemoCount int,
	BaseCount int,
	TotalCount int
)

open cur
FETCH NEXT FROM cur
INTO @TableName
declare @sql varchar(3000)
while  @@FETCH_STATUS = 0
begin
	
	set @sql='
		declare @DemoCount int
		declare @BaseCount int
		declare @TotalCount int
		set @DemoCount=(select count(*) from '+@TableName+' where CreatedByID=''{CCACD52F-B640-477A-8A86-A17032120446}'')
		set @BaseCount=(select count(*) from '+@TableName+' where CreatedByID=''{7DE33897-86A9-421B-851D-2E39BA91648A}'')
		set @TotalCount=(select count(*) from '+@TableName+')
		insert into #tmp
		values ('''+@TableName+''',@DemoCount,@BaseCount,@TotalCount)'
	print @sql
	exec (@sql)	
	FETCH NEXT FROM cur
	INTO @TableName
end

select *, TotalCount-DemoCount-Basecount As NoBasecount from #tmp
order by TableName

close cur
deallocate Cur
drop table #tmp


