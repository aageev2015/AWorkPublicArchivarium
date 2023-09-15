if not object_id('temp_SafeDropObject', 'P') is null
begin
	drop procedure [temp_SafeDropObject]
end
GO
create procedure [temp_SafeDropObject] 
	@Object sysname,
	@Type sysname = 'U'
AS
begin
	set nocount on

	declare @Drop nvarchar(1000)

	if @Type = 'U' set @Drop = 'drop table [' + @Object + ']' else
	if @Type = 'V' set @Drop = 'drop view [' + @Object + ']' else
	if @Type = 'P' set @Drop = 'drop procedure [' + @Object + ']' else
	if @Type = 'FN' set @Drop = 'drop function [' + @Object + ']'

	exec('if not object_id(''' + @Object + ''', ''' + @Type + ''') is null ' + @Drop)
end
GO

exec [temp_SafeDropObject] 'temp_SafeGetServerVersion', 'FN'
GO
exec [temp_SafeDropObject] 'temp_SafeCreateRole', 'P'
GO
exec [temp_SafeDropObject] 'temp_SafeCreateTableGroup', 'P'
GO

create function [temp_SafeGetServerVersion] ()
returns int
AS
begin
	return (select @@microsoftversion /0x01000000)
end
GO

create procedure [temp_SafeCreateRole] 
	@Role sysname
AS
begin
	set nocount on

	if (not exists(select * from sysusers where name = @Role and issqlrole = 1))
	begin
		if ((select [dbo].[temp_SafeGetServerVersion] ()) = 8)
		begin
			exec('exec sp_addrole N''' + @Role + '''')
		end else
		begin
			exec('create role [' + @Role + ']')
		end	
	end
end
GO

create procedure [temp_SafeCreateTableGroup] (
	@TableGroup sysname,
	@TableGroupCaption sysname
)
AS
begin
	set nocount on
	declare @trancount int
	
	exec [temp_SafeCreateRole] @TableGroup
	set @trancount = @@trancount
	if @trancount > 0 commit
	exec sp_addrolemember 'TG', @TableGroup
	if @trancount > 0 begin tran

	declare @ChildTableGroup sysname

	set @ChildTableGroup = @TableGroup + '_CR'
	exec [temp_SafeCreateRole] @ChildTableGroup
	set @trancount = @@trancount
	if @trancount > 0 commit
	exec sp_addrolemember @TableGroup, @ChildTableGroup
	if @trancount > 0 begin tran

	set @ChildTableGroup = @TableGroup + '_CI'
	exec [temp_SafeCreateRole] @ChildTableGroup
	set @trancount = @@trancount
	if @trancount > 0 commit
	exec sp_addrolemember @TableGroup, @ChildTableGroup
	if @trancount > 0 begin tran

	set @ChildTableGroup = @TableGroup + '_CU'
	exec [temp_SafeCreateRole] @ChildTableGroup
	set @trancount = @@trancount
	if @trancount > 0 commit
	exec sp_addrolemember @TableGroup, @ChildTableGroup
	if @trancount > 0 begin tran

	set @ChildTableGroup = @TableGroup + '_CD'
	exec [temp_SafeCreateRole] @ChildTableGroup
	set @trancount = @@trancount
	if @trancount > 0 commit
	exec sp_addrolemember @TableGroup, @ChildTableGroup
	if @trancount > 0 begin tran

	declare @ParentTableGroupID uniqueidentifier
	declare @TableGroupID uniqueidentifier

	set @ParentTableGroupID = (select [ID] from [tbl_TableGroup] where [SQLObjectName] = 'TG')

	set @TableGroupID = (select [ID] from [tbl_TableGroup] where [SQLObjectName] = @TableGroup)

	if (@TableGroupID is null)
	begin
		set @TableGroupID = newid()

		insert into [tbl_TableGroup] ([ID], [ParentID], [Name], [Code], [SQLObjectName])
		values(@TableGroupID, @ParentTableGroupID, @TableGroupCaption, @TableGroup, @TableGroup)
	end else 
	begin
		delete from [tbl_TableGroup]
		where [ParentID] = @TableGroupID
	end

	set @ChildTableGroup = @TableGroup + '_CR'
	insert into [tbl_TableGroup] ([ID], [ParentID], [Name], [Code], [SQLObjectName])
	values(newid(), @TableGroupID, @ChildTableGroup, @ChildTableGroup, @ChildTableGroup)
	set @ChildTableGroup = @TableGroup + '_CI'
	insert into [tbl_TableGroup] ([ID], [ParentID], [Name], [Code], [SQLObjectName])
	values(newid(), @TableGroupID, @ChildTableGroup, @ChildTableGroup, @ChildTableGroup)
	set @ChildTableGroup = @TableGroup + '_CU'
	insert into [tbl_TableGroup] ([ID], [ParentID], [Name], [Code], [SQLObjectName])
	values(newid(), @TableGroupID, @ChildTableGroup, @ChildTableGroup, @ChildTableGroup)
	set @ChildTableGroup = @TableGroup + '_CD'
	insert into [tbl_TableGroup] ([ID], [ParentID], [Name], [Code], [SQLObjectName])
	values(newid(), @TableGroupID, @ChildTableGroup, @ChildTableGroup, @ChildTableGroup)
end
GO



--exec [temp_SafeCreateTableGroup] 'tg_Opportunities', N'Opportunities'
--GO
--exec [temp_SafeCreateTableGroup] 'tg_PipeLines', N'Pipe lines'
--GO
--exec [temp_SafeCreateTableGroup] 'tg_Offerings', N'Offerings'
--GO
--exec [temp_SafeCreateTableGroup] 'tg_Invoice', N'Invoice'
--GO
--exec [temp_SafeCreateTableGroup] 'tg_Files', N'Files'
--GO
--exec [temp_SafeCreateTableGroup] 'tg_Contract', N'Contract'
--GO
--exec [temp_SafeCreateTableGroup] 'tg_Workflow', N'Process'
--GO


if not object_id('temp_SafeCreateTableGroup', 'P') is null
begin
	drop procedure [temp_SafeCreateTableGroup]
end

