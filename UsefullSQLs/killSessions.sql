declare @sql nvarchar(max) = '';
SELECT @sql = @sql + 'kill ' + convert(nvarchar(50), SPId) + '
' FROM MASTER..SysProcesses WHERE db_name(DBId) in ('CENTRAL_DEMO_SYNC', 'REGIONAL_DEMO_SYNC')
exec(@sql)
