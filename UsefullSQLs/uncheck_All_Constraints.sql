declare @tablename varchar(100)

declare cur cursor for
select code from tbl_Service
where servicetypecode='Table'
order by code
open cur
declare @num int
declare @skippNum int
set @num = 0
set @SkippNum = 0

declare @sql varchar(4000)
while (1 = 1)
begin
	fetch next from cur into @tablename

	if @@fetch_status = -1 break
	if @@fetch_status = -2 continue
	set @Num=@Num+1
	if (@SkippNum>@Num) continue
	set @sql='alter table '+ @tablename +' NOCHECK CONSTRAINT ALL'
	print cast(@Num as Varchar(5)) + ' ' + @sql
	exec (@sql)
end

close cur
deallocate cur

