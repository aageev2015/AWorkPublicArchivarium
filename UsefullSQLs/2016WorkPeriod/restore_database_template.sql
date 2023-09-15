use master
declare @databaseName nvarchar(max) = 'AwesomeSystemV02015_2'
declare @backupFile nvarchar(max) = 'd:\temp\2nd-AwesomeSystemV0-backup.bak'
declare @sql nvarchar(max) = ''	

SELECT 
    @sql=@sql+'
kill '  + cast(spid as nvarchar(50))
    
FROM   sys.sysprocesses
WHERE 
    DB_NAME(dbid)= @databaseName
and isnull(hostname,'')<>''
print @sql
exec (@sql)

set @sql = 'RESTORE DATABASE '+@databaseName+' FROM DISK = '''+@backupFile+''''

exec(@sql)
 

 