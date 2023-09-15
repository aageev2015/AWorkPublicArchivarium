declare @TargetType varchar(250)
set @TargetType = 'Demo'
--set @TargetType = 'Base'



declare @DemoContentManagerID uniqueidentifier;
declare @BaseContentManagerID uniqueidentifier;
declare @SupervisorID uniqueidentifier;
set @BaseContentManagerID = (select top 1 id from tbl_Contact where Name = 'Base Content Manager')
--'{7DE33897-86A9-421B-851D-2E39BA91648A}';
set @DemoContentManagerID = (select top 1 id from tbl_Contact where Name = 'Demo Content Manager')
--'{CCACD52F-B640-477A-8A86-A17032120446}';
set @SupervisorID = (select top 1 id from tbl_Contact where Name = 'Supervisor')
-- '{F8595201-B96A-42AF-9407-FDCDB0757A80}'


declare @ContentIDs varchar(1000);
declare @ContentIDss varchar(1000);
if (@TargetType='Demo')
begin
	set @ContentIDs = '''{' + cast(@BaseContentManagerID as varchar(38)) + '}'', ''{'+
--			cast(@SupervisorID as varchar(38)) + '}'', ''{' +
			cast(@DemoContentManagerID as varchar(38)) + '}''';
	set @ContentIDss = '''''{' + cast(@BaseContentManagerID as varchar(38)) + '}'''', ''''{'+
--			cast(@SupervisorID as varchar(38)) + '}'''', ''''{' +
			cast(@DemoContentManagerID as varchar(38)) + '}''''';
end else begin
	set @ContentIDs = '''{' + cast(@BaseContentManagerID as varchar(38)) + '}''';
	set @ContentIDss = '''''{' + cast(@BaseContentManagerID as varchar(38)) + '}''''';
end
print @ContentIDs



create table #tmp2(
TableName varchar(255),
FieldName varchar(255),
ForeignTableName varchar(255),
FakeCount int,
CheckSQL varchar(2024)
)


insert into #tmp2
select t1.Code,t4.name,t6.name,0,'' 
from tbl_Service t1, sysobjects  t2, syscolumns t4, sysforeignkeys t5, sysobjects t6, sysobjects cid
where t1.ServiceTypeCode = 'Table'
and exists (select * from syscolumns t3 where t2.id=t3.id and t3.Name = 'CreatedByID')
and t1.Code=t2.name
and t2.id=t4.id
and t5.fkeyid=t2.id and t5.fkey=t4.colid
and t5.rkeyid=t6.id
and t5.constid=cid.id
and t1.code not in ('tbl_Service')
and not exists(select * from tbl_ServiceProperty t7 where  t7.ServiceID=t1.ID and t7.Name = 'CascadeDelete' and t7.Value like '%'+cid.Name+'%')
and t4.name not in ('CreatedByID','ModifiedByID')
order by t1.Code, t4.Name

declare Cur cursor for 
select TableName, FieldName, ForeignTableName from #tmp2

declare @TableName varchar(255)
declare @FieldName varchar(255)
declare @ForeignTableName varchar(255)
declare @sql varchar(4000)
declare @fakeRecordsCount int
Open Cur
while (1=1) begin
	FETCH NEXT FROM Cur INTO @TableName, @FieldName, @ForeignTableName
	if @@FETCH_STATUS=-1 break
	if @@FETCH_STATUS=-2 continue

	exec (	
'update #tmp2 
set FakeCount = (
	select count(*) from '+@TableName+' t1, '+@ForeignTableName+' t2
	where 
	t1.'+@FieldName+' = t2.ID and
	t1.CreatedByID in (' + @ContentIDs + ') and
	(t2.CreatedByID not in (' + @ContentIDs + 
		', ''{' + @SupervisorID + '}'''+
') or (t2.CreatedByID is null))
	and t1.'+@FieldName+' not in (' + @ContentIDs + ')
),
CheckSQL=''
select 	
	t1.ID as ['+@TableName+'.ID],
	t1.'+@FieldName+' as ['+@TableName+'.'+@FieldName+'],
	t3.name as ['+@TableName+'.CreatedByName],
	t4.name as ['+@ForeignTableName+'.CreatedByName],
	t1.CreatedByID as ['+@TableName+'.CreatedByID],
	t2.createdbyid as ['+@ForeignTableName+'.CreatedByID]
from '+@TableName+' t1
inner join '+@ForeignTableName+' t2
	on t1.'+@FieldName+'=t2.id
left join tbl_contact t3
	on t3.id=t1.createdbyid
left join tbl_contact t4
	on t4.id=t2.createdbyid
where t1.CreatedByID in (' + @ContentIDss + ')
and ((t2.CreatedbyID not in (' + @ContentIDss + 
		', ''''{' + @SupervisorID + '}'''''+
')) or (t2.CreatedbyID is null))''
where TableName='''+@TableName+''' and FieldName='''+@FieldName+'''')
	select @fakeRecordsCount = FakeCount, @SQL= CheckSQL from #tmp2 where TableNAme = @TableName and FieldName = @FieldName
	if (@fakeRecordsCount>0)
	begin
		print @sql
		exec (@sql)
	end
end
close cur
deallocate cur

delete from #tmp2
where FakeCount=0

select * from #tmp2
order by FakeCount desc

/*declare @ErrorList varchar(5000)
set @ErrorList = ''
select @ErrorList=(@ErrorList+TableName+'.'+FieldName+';  ') from #tmp2
order by FakeCount desc
set @ErrorList = 'ERROR. Content wrong by keys: ' + @ErrorList;
RAISERROR (@ErrorList, 16, 1)*/

drop table #tmp2