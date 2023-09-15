-- size of each table
Declare @TotalSummBytes float
select obj.name as TableName,sum(col.length) RecordSize,
0 as RecordsCount
into #tmp
from syscolumns col, sysobjects obj, systypes type
where col.id=obj.id
and col.xusertype=type.xusertype
and obj.xtype='U'
and exists(select * from syscolumns col2 where col2.id=obj.id and col2.name = 'CreatedByID')
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
		'set RecordsCount = (select count(*) from '+@TableName+'
where CreatedByID in (
--''{7DE33897-86A9-421B-851D-2E39BA91648A}'',
			''{CCACD52F-B640-477A-8A86-A17032120446}''))'+
		'where TableName='''+@TableName+'''')
end


set @TotalSummBytes = (select sum(RecordSize*RecordsCount/1024) from #tmp)

select *,RecordSize*RecordsCount/1024 as KBSize, RecordSize*RecordsCount/1024/1024 MBSize from #tmp
union
select 'TotalSumm' as TableName, 0 as recordSize, 0 as RecordsCount, @TotalSummBytes as KBSize, @TotalSummBytes/1024 as MBSize
order by RecordsCount desc


close cur
deallocate cur
drop table #tmp