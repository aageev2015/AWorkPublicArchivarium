USE [master]
GO

create table #backupInformation (LogicalName nvarchar(100),
								PhysicalName nvarchar(100),
								Type nvarchar(1),
								FileGroupName nvarchar(50) ,
								Size bigint ,
								MaxSize bigint,
								FileId int,
								CreateLSN int,
								DropLSN int,
								UniqueId uniqueidentifier,
								ReadOnlyLSN int,
								ReadWriteLSN int,
								BackupSizeInBytes int,
								SourceBlockSize int,
								FileGroupId int,
								LogGroupGUID uniqueidentifier,
								DifferentialBaseLSN bigint,
								DifferentialBaseGUID uniqueidentifier,
								IsReadOnly bit,
								IsPresent bit,
								TDEThumbprint nvarchar(100));

insert into #backupInformation exec('restore filelistonly from disk = ''$(bak)''')

DECLARE @logicalNameD nvarchar(255);
DECLARE @logicalNameL nvarchar(255);
DECLARE @returncode INT;
DECLARE @path nvarchar(4000);
DECLARE @datafile nvarchar(MAX);
DECLARE @logfile nvarchar(MAX);

exec @returncode = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultData', @path output, 'no_output'

SET @datafile = @path + N'\$(database).mdf';
SET @logfile = @path + N'\$(database).ldf';

select top 1 @logicalNameD = LogicalName from #backupInformation where Type = 'D';
select top 1 @logicalNameL = LogicalName from #backupInformation where Type = 'L';

DROP TABLE #backupInformation

if db_id('$(database)') is not null EXEC (N'DROP DATABASE $(database);')

RESTORE DATABASE $(database)
FROM DISK = N'$(bak)'
WITH REPLACE,
MOVE @logicalNameD TO @datafile,
MOVE @logicalNameL TO @logfile
GO