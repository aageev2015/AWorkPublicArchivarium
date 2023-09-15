use master
declare @sql nvarchar(max) = ''	

SELECT 
    @sql=@sql+'
kill '  + cast(spid as nvarchar(50))
    
FROM   sys.sysprocesses
WHERE 
    DB_NAME(dbid)= 'AwesomeSystemV02015_techdeploy_2'
and isnull(hostname,'')<>''
exec (@sql)
 