-- RESTORE

use master;
declare @database nvarchar(100) = 'APV0_GENERATED';

declare @sql nvarchar(max) =replace(
'
Declare @spid int
Declare @dbname sysname = ''#DATABASE#''
Select @spid = min(spid) from master.dbo.sysprocesses
where dbid = db_id(@dbname)
While @spid Is Not Null
Begin
        Execute (''Kill '' + @spid)
        Select @spid = min(spid) from master.dbo.sysprocesses
        where dbid = db_id(@dbname) and spid > @spid
End

RESTORE DATABASE [#DATABASE#] FROM DISK = ''c:\temp\#DATABASE#.bak'' WITH REPLACE
'
,'#DATABASE#', @database)
print @sql;

exec (@sql)
