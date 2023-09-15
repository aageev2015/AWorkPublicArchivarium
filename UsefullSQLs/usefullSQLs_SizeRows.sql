--all user tables with columns, types, length
select obj.name as TableName,col.name as ColumnName, type.name as typeName,col.length 
from syscolumns col, sysobjects obj, systypes type
where col.id=obj.id
and col.xusertype=type.xusertype
and obj.xtype='U'
order by obj.name,col.name

-- size of each table


Declare @TotalSummBytes float
select obj.name as TableName,sum(col.length) RecordSize,
0 as RecordsCount
into #tmp
from syscolumns col, sysobjects obj, systypes type
where col.id=obj.id
and col.xusertype=type.xusertype
and obj.xtype='U'
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
		'set RecordsCount = (select count(*) from '+@TableName+')'+
		'where TableName='''+@TableName+'''')
end


set @TotalSummBytes = (select sum(RecordSize*RecordsCount/1024) from #tmp)

select *,RecordSize*RecordsCount/1024 as KBSize, RecordSize*RecordsCount/1024/1024 MBSize from #tmp
union
select 'TotalSumm' as TableName, 0 as recordSize, 0 as RecordsCount, @TotalSummBytes as KBSize, @TotalSummBytes/1024 as MBSize


close cur
deallocate cur
drop table #tmp