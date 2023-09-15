EXEC sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
RECONFIGURE;  
GO  

exec xp_cmdshell 'del /Q d:\temp\db_bak_temp.bak'
GO

BACKUP DATABASE AwesomeSystemV0_TEST TO DISK = 'd:\temp\db_bak_temp.bak' WITH INIT
GO

if exists(select * from sys.databases where name='AwesomeSystemV0_TEST_before_get')
begin
	ALTER DATABASE AwesomeSystemV0_TEST_before_get SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
end
GO

RESTORE FILELISTONLY
   FROM disk = 'd:\temp\db_bak_temp.bak'    
RESTORE DATABASE AwesomeSystemV0_TEST_before_get
   FROM disk = 'd:\temp\db_bak_temp.bak'
   WITH replace,
   MOVE 'AwesomeSystemV0_TEST' TO 'C:\Program Files\Microsoft SQL Server14\MSSQL12.MSSQLSERVER14\MSSQL\DATA\AwesomeSystemV0_TEST_before_get.mdf', 
   MOVE 'AwesomeSystemV0_TEST_log' TO 'C:\Program Files\Microsoft SQL Server14\MSSQL12.MSSQLSERVER14\MSSQL\DATA\AwesomeSystemV0_TEST_before_get_log.ldf', 
   stats = 5
GO

ALTER DATABASE AwesomeSystemV0_TEST_before_get SET MULTI_USER;
GO

EXEC sp_configure 'xp_cmdshell', 0;  
GO  
RECONFIGURE;  
GO
EXEC sp_configure 'show advanced options', 0;  
GO  
RECONFIGURE;  
GO  


