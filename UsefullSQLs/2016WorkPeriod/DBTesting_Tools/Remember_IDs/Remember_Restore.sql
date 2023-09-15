
--declare @action int  = 1 -- remember
declare @action int  = 2 -- restore
--declare @action int  = 3 -- clear

declare @restoringDate datetime = null

declare @table_Name nvarchar(250)
declare @sql nvarchar(max)

if (@action = 1) 
begin
	set @restoringDate = getdate()
	print 'date key = '
	print @restoringDate
	
	declare cur cursor for
	select c.table_name from information_schema.columns c
	inner join INFORMATION_SCHEMA.TABLES t on c.table_name=t.table_name
	where ordinal_position=1
	and t.table_type = 'Base Table'
	and c.Column_name='ID'
	order by c.table_name

	open cur
	while(1=1)
	begin
		fetch cur into @table_name
		if @@FETCH_STATUS in (-1,-2) break
		set @sql = 'insert into tbl_diag_Remembered_Ids (record_id, Table_Name, Remember_date)
select id,table_name, ''' + convert(varchar(100), @restoringDate) + ''' from (select max(id) as id , '''+ @table_name + ''' as table_Name from [' + @table_name + ']) t where id is not null'
		print @sql
		exec (@sql)
	end
	close cur
	deallocate cur

	

end else
if @action=2
begin
	return
end else
if @action=3
begin
	truncate table tbl_diag_Remembered_Ids
end
/*
declare @sql varchar(max) = ''
select @sql = @sql+m.txt 
from (
	select 'select 0 as id, '''' as table_name where 1=0 
' as txt
	union all
	select 'union all select max(id), ''' + c.table_name + ''' as table_Name from [' + c.table_name+ ']
' as txt
	from information_schema.columns c
	inner join INFORMATION_SCHEMA.TABLES t on c.table_name=t.table_name
	where ordinal_position=1
	and t.table_type = 'Base Table'
	and c.Column_name='ID'
) m

print @sql
*/