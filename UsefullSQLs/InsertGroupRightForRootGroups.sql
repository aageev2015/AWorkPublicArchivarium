begin tran
declare tmp cursor for
select t2.name as GroupRightTable,t1.name as GroupTable from sysobjects t1
inner join sysobjects  t2 on (
	objectproperty(t2.id,'IsUserTable')=1
	and t2.name = replace(t1.name,'Right','')
)
where objectproperty(t1.id,'IsUserTable')=1
and t1.name like '%groupright'

declare @GroupName varchar(100)
declare @GroupRightName varchar(100)
declare @sql varchar(2000)
declare @GroupID uniqueidentifier

open tmp
while 1=1
begin
	FETCH NEXT FROM tmp 
	INTO @GroupName, @GroupRightName
	if @@FETCH_STATUS= -1 break
	if @@FETCH_STATUS= -2 continue
	set @sql='
	declare @GroupID uniqueidentifier
	set @GroupID=(select ID from '+@GroupName+' where ParentGroupId is null)
	if not @GroupId is null 
	begin
		if not exists(select 1 from '+@GroupRightName+' where RecordID=@GroupId and AdminUnitID=''{6CD52759-5503-4130-8ACC-4AD6B342C010}'')
			insert into '+@GroupRightName+' (Id,AdminUnitID,RecordID,CanRead)
			values(newid(),''{6CD52759-5503-4130-8ACC-4AD6B342C010}'',@GroupID,1)
	end
	else 
		print ''GroupID is null''
	'	
	print '---- '+@GroupName
	exec (@Sql)
	
end

CLOSE tmp
DEALLOCATE tmp

commit


begin tran
declare @sql varchar(3000)
set @sql='
insert into %table (id, CreatedOn,CreatedByID,Modifiedon,ModifiedById,ParentGroupID,Name,IsFiltered,FilterData,Description)
select id, CreatedOn,CreatedByID,Modifiedon,ModifiedById,ParentGroupID,Name,IsFiltered,FilterData,Description 
from mycrm320x15..%table
where ParentGroupID is null
'

declare @sql1 varchar(3000)
set @sql1=replace(@Sql,'%table','tbl_ContractGroup')
exec (@sql1) 
set @sql1=replace(@Sql,'%table','tbl_InvoiceGroup')
exec (@sql1) 
set @sql1=replace(@Sql,'%table','tbl_OfferingGroup')
exec (@sql1) 
set @sql1=replace(@Sql,'%table','tbl_OpportunityGroup')
exec (@sql1) 

rollback

select * from