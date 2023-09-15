@cls
 
@time /T
 
@echo Drop temp database
@d:\Work\sql\sqlcmd -SLocalhost -Hlocalhost -Q"EXEC msdb.dbo.sp_delete_database_backuphistory @db_nm = N'Dev332_temp'"
@d:\Work\sql\sqlcmd -SLocalhost -Hlocalhost -Q"ALTER DATABASE [Dev332_temp] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE"
@start "Drop" /b /wait d:\Work\sql\sqlcmd -SLocalhost -HLocalhost -Q"DROP DATABASE [Dev332_temp]"
 
@echo Backup database
@start "Backup" /b /wait d:\Work\sql\sqlcmd -SLocalhost -HLocalhost -Q"BACKUP DATABASE [Developing332] TO  DISK = N'd:\MSSQL2000\Backup\Autobuild\Dev332_temp.bak' WITH NOFORMAT, INIT, NAME = N'Developing332-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10"
 
@echo Restore database
@start "Restore" /b /wait d:\Work\sql\sqlcmd -SLocalhost -HLocalhost -Q"RESTORE DATABASE [Dev332_temp] FROM  DISK = N'd:\MSSQL2000\Backup\Autobuild\Dev332_temp.bak' WITH  FILE = 1, MOVE N'Developing311_Data' TO N'd:\MSSQL2000\Dev332_temp.mdf', MOVE N'Developing311_Log' TO N'd:\MSSQL2000\Dev332_temp.ldf',  NOUNLOAD,  REPLACE,  STATS = 10"
 
@start "Alter" /b /wait d:\Work\sql\sqlcmd -SLocalhost -HLocalhost -dDev332_temp -Q"update tbl_Service set LockedByUserID = null"
@title !!!Finish!!!
@pause
