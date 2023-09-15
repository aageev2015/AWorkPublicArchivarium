/*
look current settings
EXEC sp_configure 'show advanced options'
EXEC sp_configure 'xp_cmdshell'
*/
/*
enable xp_cmdshell
*/
/*
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
EXEC sp_configure 'xp_cmdshell', 1
GO
RECONFIGURE
GO
*/
/*
use xp_cmdshell
*/

exec xp_cmdshell 'dir c:\SQLLogs\*'
GO

/*
disable xp_cmdshell
*/
/*
EXEC sp_configure 'xp_cmdshell', 0
GO
RECONFIGURE
GO
EXEC sp_configure 'show advanced options', 0
GO
RECONFIGURE
GO
*/