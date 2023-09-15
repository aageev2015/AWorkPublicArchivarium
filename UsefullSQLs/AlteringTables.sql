declare @TableName sysname
declare @sql nvarchar(4000)

begin transaction

declare t cursor for
select name from 
sysobjects so1
where 
--  not exists(
--  Select Object_Name(constid) 
--  From SysConstraints sc 
--  Where Object_Name(id) = so1.name
--  And (Select Name From SysColumns 
--  Where id = Object_ID(so1.name) And 
--  ColID = sc.ColID) = 'ID')
--  and 
so1.xtype = 'U'
and so1.name like 'tbl_%'
order by name

open t 
fetch next from t into @TableName

while @@fetch_status = 0
begin

	ALTER TABLE dbo.tbl_MailMessage ALTER COLUMN ID
	ADD ROWGUIDCOL
	
/*	set @sql = N' ALTER TABLE [' + @TableName + N'] ADD CONSTRAINT [PDF' + SUBSTRING(@TableName, 5, LEN(@TableName)) + N'ID] DEFAULT (newid()) FOR [ID]'
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
commit