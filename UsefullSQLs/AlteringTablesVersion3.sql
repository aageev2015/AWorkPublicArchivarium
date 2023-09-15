declare @TableName sysname
declare @sql nvarchar(4000)

begin transaction

declare t cursor for
select name from 
sysobjects so1
where 
--  NOT EXISTS(
--  SELECT OBJECT_NAME(CONSTID) 
--  FROM SYSCONSTRAINTS SC 
--  WHERE OBJECT_NAME(ID) = SO1.NAME
--  AND (SELECT NAME FROM SYSCOLUMNS 
--  WHERE ID = OBJECT_ID(SO1.NAME) AND 
--  COLID = SC.COLID) = 'ID')
--  AND 
so1.xtype = 'U'
and so1.name like 'tbl_%'
order by name

open t 
fetch next from t into @TableName

while @@fetch_status = 0
begin


	set @sql = N'
	declare ICursor cursor for select sysindexes.Name, sysindexes.indid  from sysindexes
		join
		sysobjects on sysobjects.id = sysindexes.id
		where sysobjects.Name = ''' + @TableName + N'''  
	declare @IndexName nvarchar(32)
	declare @IndexID int
	declare @sql nvarchar(1000)
	open ICursor 
	while 1 = 1
	begin 
		fetch next from ICursor into @IndexName, @IndexID
		if (@@fetch_status = -1) break
		if (@@fetch_status = -2) continue 
		if (INDEX_COL( ''' + @TableName + ''' , @IndexID , 1 ) = ''ID'') 
		begin 
			set @sql = ''DROP INDEX ' + @TableName + N'.'' + @IndexName 
			print @sql
			exec (@sql)
		end

	end
	close ICursor
	deallocate ICursor'

	print @sql
	exec(@sql)


	if (COLUMNPROPERTY (Object_ID(@TableName), 'ID', 'IsRowGuidCol') = 1)
	BEGIN
		set @sql = N' ALTER TABLE [' + @TableName + N'] ALTER COLUMN ID DROP ROWGUIDCOL'
		print @sql
		exec(@sql)
	END
/*

	set @sql = N' ALTER TABLE [' + @TableName + N'] ALTER COLUMN ID uniqueidentifier NOT NULL'
	print @sql
	exec(@sql)

	set @sql = N' ALTER TABLE [' + @TableName + N'] ADD CONSTRAINT [PDF' + SUBSTRING(@TableName, 5, LEN(@TableName)) + N'ID] DEFAULT (newid()) FOR [ID]'
	print @sql
	exec(@sql)
*/

	set @sql = N' ALTER TABLE [' + @TableName + N'] ALTER COLUMN ID ADD ROWGUIDCOL'
	print @sql
	exec(@sql)
/*	

	set @sql = N' ALTER TABLE [' + @TableName + N'] ADD CONSTRAINT [P' + SUBSTRING(@TableName, 5, LEN(@TableName)) + N'ID] PRIMARY KEY (ID)'
	print @sql
	exec(@sql)


	set @sql = N' ALTER TABLE [' + @TableName + N'] ADD [UniqueID] uniqueidentifier'
	print @sql
	exec(@sql)
	
	set @sql = N' UPDATE [' + @TableName + N'] set [UniqueID] = newid()'
	print @sql
	exec(@sql)
	
	set @sql = N'declare rec cursor for select [id], [UniqueID] from [' + @TableName + N'] order by [ID] 
		declare @LastID uniqueidentifier
		declare @CurrentID uniqueidentifier
		declare @CurrentUniqueID uniqueidentifier
		set @LastID = null;
		open rec
		while 1 = 1
		begin
			if (@@fetch_status = -1) break
			if (@@fetch_status = -2) continue
			fetch next from rec into @CurrentID, @CurrentUniqueID
			if (@CurrentID = @LastID) 
			begin
				delete from [' + @TableName + N'] where [UniqueID] = @CurrentUniqueID  
			end
			else 
			begin
				set @LastID = @CurrentID
			end 
		end
		close rec
		deallocate rec'
	print @sql
	exec(@sql)

	set @sql = N' ALTER TABLE [' + @TableName + N'] drop column [UniqueID]'
	print @sql
	exec(@sql)	

	set @sql = N' ALTER TABLE [' + @TableName + N'] alter column id uniqueidentifier not null'
	print @sql
	exec(@sql)	

	set @sql = N' ALTER TABLE [' + @TableName + N'] ADD CONSTRAINT [P' + SUBSTRING(@TableName, 5, LEN(@TableName)) + N'ID] PRIMARY KEY (ID)'
	print @sql
	exec(@sql)
*/

	fetch next from t into @TableName
end 


close t
deallocate t
--rollback
commit