
declare cur cursor for
select name 
from sysobjects t1
where type='U'
and Name like 'tbl_%right'
and name<>'tbl_TableDefaultRight'
and name<>'tbl_TableFieldRight'
and name<>'tbl_TaskGroupRight'
order by name

open cur
declare @name varchar(250)
declare @sql varchar(5000)
declare @SupervisorID varchar(38)
select @SupervisorID = cast( id as varchar(38)) from tbl_AdminUnit where name='Supervisor'
declare @RootAdminUnitID varchar(38)
select @RootAdminUnitID = cast( id as varchar(38)) from tbl_AdminUnit where GroupParentID is null and ISGroup=1


FETCH NEXT FROM cur
into @name


WHILE @@FETCH_STATUS = 0
BEGIN
--	set @sql='select * from '+@name+' where AdminUnitID=''{'+@RootAdminUnitID+'}'' or AdminUnitID=''{'+@SupervisorID+'}'''
--		set @sql='select ''insert into '+@name+'(Id,recordid,AdminUnitid,CanRead,CanWrite,CanDelete,CanChangeAccess) 
--	values(''''{''+cast(t1.id as varchar(38))+''}'''',''''{''+cast(t1.recordid as varchar(38))+''}'''',''''{''+cast(t1.adminunitid as varchar(38))+''}'''',''+cast(t1.canread as varchar(1))+'',''+cast(t1.canWrite as varchar(1))+'',''+cast(t1.canDelete as varchar(1))+'',''+cast(t1.canchangeAccess as varchar(1))+'')'' from '+@name+' as t1 where AdminUnitID=''{'+@RootAdminUnitID+'}'' or AdminUnitID=''{'+@SupervisorID+'}'''

	print @name
	exec (@sql)
	FETCH NEXT FROM cur
	into @name	
END

close cur
deallocate cur



