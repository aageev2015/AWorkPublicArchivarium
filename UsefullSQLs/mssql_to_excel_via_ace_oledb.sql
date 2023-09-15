
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0; HDR=NO; IMEX=1; Database=c:\Temp\RO_TOOL_retest.xls', 'SELECT * FROM [Sheet1$]')


/*
sql user must have at least read access to excel file
*/

/*
enable all

EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
EXEC sp_configure 'ad hoc distributed queries', 1
RECONFIGURE
GO
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
RECONFIGURE
GO
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
RECONFIGURE
GO
exec sp_configure 'xp_cmdshell', '1' 
RECONFIGURE
GO


*/

/*
disable all

EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
EXEC sp_configure 'ad hoc distributed queries', 0
RECONFIGURE
GO
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 0
RECONFIGURE
GO
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 0
RECONFIGURE
GO
exec sp_configure 'xp_cmdshell', '0' 
RECONFIGURE	
GO
EXEC sp_configure 'show advanced options', 0
RECONFIGURE
GO

*/

/*

exec sp_configure 'show advanced options', '1'
RECONFIGURE
exec sp_configure 'xp_cmdshell', '1' 
RECONFIGURE


exec master..xp_cmdshell 'dir c:\Temp\RO_TOOL_retest.xls'


exec sp_configure 'show advanced options', '1'
RECONFIGURE
exec sp_configure 'xp_cmdshell', '0' 
RECONFIGURE
)
*/