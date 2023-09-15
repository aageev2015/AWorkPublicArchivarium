--update tables from one db by values from another one. Records joined by id
--schema of both database must be equal
begin tran
declare @ParentDataBaseName varchar(100) 
declare @TableNamesSelect varchar(4000)


set @ParentDataBaseName='Tourism304PreviousVersion'
set @TableNamesSelect='select code from tbl_Service where servicetypecode=''table'' and ( not code like ''vw_%'')'


if not exists (select * from master..sysdatabases where name=@ParentDataBaseName)
begin
	print 'Database '+@ParentDataBaseName+' is not exists'
	return
end
declare @sql varchar(4000)

set @sql='
declare @TableName varchar(100)
declare @sql varchar(4000)
declare @UdatedFieldsList varchar(4000)
declare @IsUserTablePropert int
declare @columnName varchar(100)
declare @countupdated int
set @countupdated =0

Declare curs cursor for '+@TableNamesSelect+'
open curs

while 1=1
begin	
	FETCH NEXT FROM curs into @TableName
	if @@FETCH_STATUS = -1 break;
	if @@FETCH_STATUS = -2 continue;	
	Declare cursColumns cursor for 
		select t1.name from syscolumns t1, sysobjects t2, '+@ParentDataBaseName+'..sysobjects t3, '+@ParentDataBaseName+'..syscolumns t4
		where t1.id=t2.id and t2.name=@TableName
			and t3.name=@TableName and t3.id=t4.id
			and t1.name=t4.name
		order by t1.name
	set @UdatedFieldsList=''''
	open cursColumns
	while 1=1
	begin	
		FETCH NEXT FROM cursColumns into @columnName
		if @@FETCH_STATUS = -1 break;
		if @@FETCH_STATUS = -2 continue;		
		if len(@UdatedFieldsList)<>0 
		set @UdatedFieldsList=@UdatedFieldsList+'', 
		    ''
		set @UdatedFieldsList= @UdatedFieldsList+@columnName+''=t2.''+@columnName
		
	end
	close cursColumns
	deallocate cursColumns


	set @sql=
		''update ''+@TableName+''
		set ''+@UdatedFieldsList +  ''
		from ''+@TableName+'' t1, '+@ParentDataBaseName+'..''+@TableName+'' t2 
		where t1.id=t2.id''
	print @sql
	exec(@sql)
	set @countupdated=@countupdated+1
end
close curs
deallocate curs
print ''tablesupdated''+cast(@countupdated as varchar(30))'
print @sql

exec (@sql)



rollback