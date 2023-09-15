-- size of each table

select obj.name as TableName,
0 as RecordsCount
into #tmp
from sysobjects obj
where 
obj.xtype='U'
and exists(select * from syscolumns col where obj.id=col.id and col.name='CreatedOn')
and obj.name like 'tbl_%'
group by obj.name
order by obj.name desc

declare Cur cursor for 
select Tablename from #tmp

declare @TableName varchar(50)

Open Cur
while (1=1) begin
	FETCH NEXT FROM Cur INTO @TableName
	if @@FETCH_STATUS=-1 break
	if @@FETCH_STATUS=-1 continue
	exec(	'update #tmp '+
		'set RecordsCount = (select count(*) from '+@TableName+' where CreatedOn>''04.20.2005'')'+
		'where TableName='''+@TableName+'''')
end


select * from #tmp
order by RecordsCount desc


close cur
deallocate cur
drop table #tmp