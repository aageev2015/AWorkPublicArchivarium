EXEC sp_configure 'show advanced options', 1;
RECONFIGURE
EXEC sp_configure 'xp_cmdshell',1
RECONFIGURE

EXEC master..xp_cmdshell 'dir d:\'

EXEC sp_configure 'xp_cmdshell',0
RECONFIGURE

EXEC sp_configure 'show advanced options', 0
RECONFIGURE