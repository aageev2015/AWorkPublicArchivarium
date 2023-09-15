
declare cur cursor for
select name 
from sysobjects t1
where type='U'
and exists(select * from syscolumns t2 where t1.id=t2.id and t2.name='CreatedByID')
order by name

open cur
declare @name varchar(250)
declare @sql varchar(5000)
declare @SupervisorID varchar(38)
select @SupervisorID = cast( id as varchar(38)) from tbl_AdminUnit where name='Supervisor'

FETCH NEXT FROM cur
into @name


WHILE @@FETCH_STATUS = 0
BEGIN
	set @sql='update '+@name+' set CreatedByID=''{'+@SupervisorID+'}'' where CreatedByID<>''{'+@SupervisorID+'}''
update '+@name+' set ModifiedByID=''{'+@SupervisorID+'}'' where ModifiedByID<>''{'+@SupervisorID+'}'''
	print @name
	exec (@sql)
	FETCH NEXT FROM cur
	into @name	
END

close cur
deallocate cur



