
USE master;

declare @startTime datetime = getdate();

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
print '1 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

EXEC sp_configure 'xp_cmdshell',1
RECONFIGURE

print '2 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

DECLARE @dbName NVARCHAR(255) = 'AwesomeSystemV0_MAIN_TEST'
DECLARE @copyDBName NVARCHAR(255) = 'AwesomeSystemV0_MAIN_TEST2'

-- get DB files
CREATE TABLE ##DBFileNames([FileName] NVARCHAR(255))
EXEC('
    INSERT INTO ##DBFileNames([FileName])
    SELECT [filename] FROM ' + @dbName + '.sys.sysfiles')

print '3 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))
-- drop connections
EXEC('ALTER DATABASE [' + @dbName + '] SET OFFLINE WITH ROLLBACK IMMEDIATE')

print '4 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

EXEC('ALTER DATABASE [' + @dbName + '] SET SINGLE_USER')

print '5 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

-- detach
EXEC('EXEC sp_detach_db @dbname = ''' + @dbName + '''')

print '6 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

-- copy files
DECLARE @filename NVARCHAR(255), @path NVARCHAR(255), @ext NVARCHAR(255), @copyFileName NVARCHAR(255), @command NVARCHAR(MAX) = ''
DECLARE 
    @oldAttachCommand NVARCHAR(MAX) = 
'CREATE DATABASE [' + @dbName + '] ON ', 
    @newAttachCommand NVARCHAR(MAX) = 
	'IF DB_ID(''' + @copyDBName + ''') IS NOT NULL 
BEGIN
	ALTER DATABASE [' + @copyDBName + '] SET OFFLINE WITH ROLLBACK IMMEDIATE
	DROP DATABASE [' + @copyDBName + ']
END
        CREATE DATABASE [' + @copyDBName + '] ON '

DECLARE curs CURSOR FOR 
SELECT [filename] FROM ##DBFileNames
OPEN curs 

print '7 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

FETCH NEXT FROM curs INTO @filename
WHILE @@FETCH_STATUS = 0  
BEGIN
    SET @path = REVERSE(RIGHT(REVERSE(@filename),(LEN(@filename)-CHARINDEX('\', REVERSE(@filename),1))+1))
    SET @ext = RIGHT(@filename,4)
    SET @copyFileName = @path + @copyDBName + @ext

    SET @command = 'EXEC master..xp_cmdshell ''COPY "' + @filename + '" "' + @copyFileName + '"'''
    PRINT @command
    EXEC(@command);

    SET @oldAttachCommand = @oldAttachCommand + '(FILENAME = "' + @filename + '"),'
    SET @newAttachCommand = @newAttachCommand + '(FILENAME = "' + @copyFileName + '"),'

    FETCH NEXT FROM curs INTO @filename
END
CLOSE curs 
DEALLOCATE curs

-- attach
SET @oldAttachCommand = LEFT(@oldAttachCommand, LEN(@oldAttachCommand) - 1) + ' FOR ATTACH'
SET @newAttachCommand = LEFT(@newAttachCommand, LEN(@newAttachCommand) - 1) + ' FOR ATTACH'

print '9 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

-- attach old db
PRINT @oldAttachCommand
EXEC(@oldAttachCommand)

print '10 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

-- attach copy db
PRINT @newAttachCommand
EXEC(@newAttachCommand)

print '11 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))

DROP TABLE ##DBFileNames

EXEC sp_configure 'xp_cmdshell',0
RECONFIGURE

EXEC sp_configure 'show advanced options', 0
RECONFIGURE;



print '12 : ' + convert(nvarchar(50), datediff(ms, @startTime, getdate()))