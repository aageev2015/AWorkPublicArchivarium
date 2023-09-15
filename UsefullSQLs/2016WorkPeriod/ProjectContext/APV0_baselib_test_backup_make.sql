-- BAKCUP

declare @database nvarchar(100) = 'APV0_TEST';

declare @sql nvarchar(max) =replace(
'
BACKUP DATABASE #DATABASE# TO DISK = ''c:\temp\#DATABASE#.bak'' WITH INIT
'
,'#DATABASE#', @database)
print @sql;

exec (@sql)
