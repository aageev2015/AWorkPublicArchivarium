begin
	declare @SupervisorID uniqueidentifier
	declare @SupervisorContactID uniqueidentifier
	declare @SupervisorAccountID uniqueidentifier
	declare @SupervisorAccountName nvarchar(250)
	declare @TableName    sysname
	declare @SQL          nvarchar(4000)
	declare @Count        int
	declare @ColumnName   sysname
	declare @IndexName    sysname
	declare @ColumnsSQL   nvarchar(4000)
	declare @UpdateSQL    nvarchar(4000)
	declare @DeleteSQL    nvarchar(4000)
	declare @SupervisorUserID varchar(38)
	declare @COLUMN_DEFAULT nvarchar(4000)
	declare @IS_NULLABLE varchar(3)
	declare @DATA_TYPE sysname
	declare @CHARACTER_MAXIMUM_LENGTH smallint
	declare @NullableName varchar(15)
	declare @NON_UNIQUIE smallint
	declare @NON_UNIQUIE_NAME varchar(15)
	declare @COLUMN_NAMEs nvarchar(1000)
	
	set nocount on

	declare c cursor for
	select table_name from information_schema.columns c1
	where exists(select * from information_schema.columns c2
	where c1.column_name = c2.column_name
	and c2.column_name = 'ParentGroupID')
	and not table_name in ('tbl_AccountGroup', 'tbl_CampaignGroup', 'tbl_ContactGroup',
	'tbl_ContractGroup', 'tbl_DocumentGroup', 'tbl_InvoiceGroup', 'tbl_LibraryGroup',
	'tbl_MailMessageGroup', 'tbl_OfferingGroup', 'tbl_OpportunityGroup', 'tbl_ReportGroup',
	'tbl_TaskGroup')
	order by c1.table_name
	
	open c 
	
	while (1 = 1) 
	begin
		fetch next from c into @TableName
	
		if @@fetch_status = -1 break
		if @@fetch_status = -2 continue
	
		exec('select top 1 [ID], [Name], [IsFiltered], [ParentGroupID], [FilterData], 
		[OwnerID], [IsPrivate], [Description] into [##' + @TableName + '] from [' + @TableName + ']
		where [ParentGroupID] is null') 
	end 
	close c
	deallocate c

	select top 1 [ID], [ParentID], [TypeID], [Name], [IsPrivate], [OwnerID], [XMLData], [Description] 
	into #tbl_OLAP from [tbl_OLAP] where [ParentID] is null

	select top 1 [ID], [Name], [ParentID], [IsGroup], [FilterData], [OwnerID], [IsPrivate], 
	[FunctionID], [IsFiltered], [Description] into #tbl_ForecastItem
	from [tbl_ForecastItem]
	where [ParentID] is null	
	
	create table #index (
		TABLE_QUALIFIER sysname,
		TABLE_OWNER sysname,
		TABLE_NAME sysname,
		NON_UNIQUIE smallint,
		INDEX_QUALIFIER	nvarchar(128),
		INDEX_NAME nvarchar(128),
		TYPE smallint,
		SEQ_IN_INDEX smallint,
		COLUMN_NAME nvarchar(128), 
		COLLATION char(1),
		CARDINALITY int,
		PAGES int,
		FILTER_CONDITION varchar(128)
	)
	
	set @SupervisorUserID = (select id from tbl_AdminUnit where Name = N'Supervisor')
	
	declare c_Cursor cursor for
	select 
		name
	from sysobjects
	where 
		name like N'tbl_%'
		and xtype = N'U'
	order by name
	
	open c_Cursor
	while 1 = 1
	begin
		fetch c_Cursor	into @TableName
	
		if @@fetch_status = -1 break
		if @@fetch_status = -2 continue
	
		insert into #index
		exec sp_statistics @Table_Name = @TableName
	end
	close c_Cursor
	deallocate c_Cursor
	
	declare c_Index cursor for
	select 
		distinct [INDEX_NAME], [TABLE_NAME]
	from #index
	where not INDEX_NAME is null and not TYPE = 1 and not INDEX_NAME like N'PK_%'
	
	open c_Index
	while 1 = 1
	begin
		fetch c_Index into @IndexName, @TableName
	
		if @@fetch_status = -1 break
		if @@fetch_status = -2 continue
	
		set @sql = N'drop index [' + @TableName + N'].[' + @IndexName + N']'
		print @sql
		exec(@sql)
	end
	close c_Index
	deallocate c_Index
	
	select @SupervisorID = ID,
	@SupervisorContactID = UserContactID
	from tbl_AdminUnit
	where Name = 'Supervisor'

	select 
	@SupervisorAccountID = AccountID
	from tbl_Contact
	where ID = @SupervisorContactID

	select 
	@SupervisorAccountName = Name
	from tbl_Account
	where ID = @SupervisorAccountID
	
	update tbl_AdminUnit 
	set CreatedByID = @SupervisorID,
	ModifiedByID = @SupervisorID
	
	update tbl_Service
	set CreatedByID = @SupervisorID,
	ModifiedByID = @SupervisorID,
	LockedByUserID = null
	
	select * into #tmp_License
	from tbl_License
	where UserID = @SupervisorID
	
	select * into #tmp_LicenseModuleInProduct
	from tbl_LicenseModuleInProduct
	
	select * into #tmp_LicenseProduct
	from tbl_LicenseProduct
	
	select * into #tmp_Report
	from tbl_Report
	
	select * into #tmp_RemindInterval
	from [tbl_RemindInterval]  

	select [Code], [Description], [ValueTypeID], [StringValue], [DateTimeValue], [Caption] into #Customer
	from [tbl_SystemSetting] 
	where [Code] = 'CustomerID'
	
	declare c_Tables cursor local for
	select 
		Name
	from sysobjects
	where Name like N'tbl_%'
	and not Name in(N'tbl_Service', N'tbl_DatabaseInfo', N'tbl_DictionarySettings')
	and xtype = N'U'
	order by Name
	
	open c_Tables 
	
	while 1 = 1
	begin
		fetch c_Tables	into @TableName
	
		if @@fetch_status = -1 break
		if @@fetch_status = -2 continue
	
		set @SQL = N'select @count = count(*) from [' + @TableName + N']'
		exec sp_executesql @SQL, N'@Count int out', @Count = @Count out
		if (@Count = 0)
		begin
			continue
		end
		set @SQL = 'Table: ' + @TableName + '. Records Count: ' + cast(@Count as varchar)
		set @ColumnsSQL = ''
	
		declare c_Fields cursor for
		select distinct syscolumns.Name AS ColumnName
		from syscolumns
		inner join sysobjects ON syscolumns.id = sysobjects.id
		where sysobjects.Name = @TableName
		and upper(syscolumns.Name) <> 'ID'
		--     order by sysobjects.Name, syscolumns.Name
		
		open c_Fields
		while 1 = 1
		begin
			fetch c_Fields	into @ColumnName
		
			if @@fetch_status = -1 break
			if @@fetch_status = -2 continue
		
			if ((@ColumnName = N'Name') and (@TableName = N'tbl_Contact'))
			begin
				continue
			end else
			begin
				if (@ColumnsSQL = '')
				begin
					set @ColumnsSQL = N'[' + @ColumnName + N'] = NULL'
				end else
				begin
					set @ColumnsSQL = @ColumnsSQL + N', [' + @ColumnName + N'] = NULL'
				end	
			end
		end
		close c_Fields
		deallocate c_Fields
	
		set @UpdateSQL = N' ALTER TABLE [' + @TableName + N'] DISABLE TRIGGER ALL '
		print @UpdateSQL
		exec(@UpdateSQL)

		set @UpdateSQL = N' UPDATE [' + @TableName + N'] 
 SET ' + @ColumnsSQL
		if (@TableName = N'tbl_AdminUnit')
		begin
			set @UpdateSQL = @UpdateSQL + N' WHERE not [Name] = N''Supervisor'''
		end
		print @UpdateSQL 
		exec (@UpdateSQL)
	
		set @UpdateSQL = N' ALTER TABLE [' + @TableName + N'] ENABLE TRIGGER ALL '
		print @UpdateSQL
		exec(@UpdateSQL)
	end
	close c_Tables
	deallocate c_Tables
	
	--  select * from tbl_Contact
	
	declare c_DeletedTables cursor local for
	select Name
	from sysobjects
	where Name like N'tbl_%'
	and not Name in (N'tbl_Service', N'tbl_Contact', N'tbl_AdminUnit', N'tbl_DictionarySettings', N'tbl_DatabaseInfo')
	and xtype = N'U'
	order by Name
	
	open c_DeletedTables
	while 1 = 1
	begin
		fetch c_DeletedTables into @TableName
	
		if @@fetch_status = -1 break
		if @@fetch_status = -2 continue
	
		set @DeleteSQL = N'DELETE FROM [' + @TableName + N']'
	
		if ((@TableName = 'tbl_Contact') or (@TableName = 'tbl_AdminUnit'))
		begin
			set @DeleteSQL = @DeleteSQL + ' WHERE ISNULL([Name], '''') <> N''Supervisor'''
		end
		print @DeleteSQL
		exec (@DeleteSQL)
	end
	close c_DeletedTables
	deallocate c_DeletedTables
	
	set @DeleteSQL = N'DELETE FROM [tbl_AdminUnit] WHERE ISNULL([Name], N'''') <> N''Supervisor'''
	print @DeleteSQL
	exec (@DeleteSQL)
	
	declare c_Index cursor for
	select 	
		distinct [INDEX_NAME], [TABLE_NAME], [NON_UNIQUIE]
	from #index
	where not INDEX_NAME is null and not TYPE = 1 and not INDEX_NAME like N'PK_%'
	
	open c_Index
	while 1 = 1
	begin
		fetch c_Index into @IndexName, @TableName, @NON_UNIQUIE 
	
		if @@fetch_status = -1 break
		if @@fetch_status = -2 continue
	
		set @NON_UNIQUIE_NAME = N''
		if @NON_UNIQUIE = 0
		begin
			set @NON_UNIQUIE_NAME = N' unique'
		end
	
		set @COLUMN_NAMEs = N''
	
		select @COLUMN_NAMEs = @COLUMN_NAMEs + N'[' + COLUMN_NAME + N'],'
		from #index
		where INDEX_NAME = @IndexName and TABLE_NAME = @TableName
	
		set @COLUMN_NAMEs = substring(@COLUMN_NAMEs, 1, len(@COLUMN_NAMEs) - 1)
	
		set @sql = N'create' + @NON_UNIQUIE_NAME + N' index [' + @IndexName + 
		N'] on [' + @TableName + N'](' + @COLUMN_NAMEs + N')'
	
		print @sql
		exec(@sql)		
	end
	close c_Index
	deallocate c_Index

	declare c cursor for
	select table_name from information_schema.columns c1
	where exists(select * from information_schema.columns c2
	where c1.column_name = c2.column_name
	and c2.column_name = 'ParentGroupID')
	and not table_name in ('tbl_AccountGroup', 'tbl_CampaignGroup', 'tbl_ContactGroup',
	'tbl_ContractGroup', 'tbl_DocumentGroup', 'tbl_InvoiceGroup', 'tbl_LibraryGroup',
	'tbl_MailMessageGroup', 'tbl_OfferingGroup', 'tbl_OpportunityGroup', 'tbl_ReportGroup',
	'tbl_TaskGroup')
	order by c1.table_name
	
	open c 
	
	while (1 = 1) 
	begin
		fetch next from c into @TableName
	
		if @@fetch_status = -1 break
		if @@fetch_status = -2 continue
	
		exec('insert into [' + @TableName + '] ([ID], [Name], [IsFiltered], [ParentGroupID], 
		[FilterData], [OwnerID], [IsPrivate], [Description])
		select [ID], [Name], [IsFiltered], [ParentGroupID], [FilterData], 
		[OwnerID], [IsPrivate], [Description] from [##' + @TableName + ']
		where not exists(select * from [' + @TableName + '])') 
	
		exec('drop table [##' + @TableName + ']')
	end 
	close c
	deallocate c

	insert into [tbl_OLAP] ([ID], [ParentID], [TypeID], [Name], [IsPrivate], 
	[OwnerID], [XMLData], [Description])
	select [ID], [ParentID], [TypeID], [Name], [IsPrivate], 
	[OwnerID], [XMLData], [Description] 
	from #tbl_OLAP

	insert into [tbl_ForecastItem]([ID], [Name], [ParentID], [IsGroup], [FilterData], [OwnerID], [IsPrivate], 
	[FunctionID], [IsFiltered], [Description])
	select [ID], [Name], [ParentID], [IsGroup], [FilterData], [OwnerID], [IsPrivate], 
	[FunctionID], [IsFiltered], [Description]
	from #tbl_ForecastItem

	if (not exists(select * from [tbl_Account] where [ID] = @SupervisorAccountID))
	begin
		insert into [tbl_Account] ([ID], [Name])
		select @SupervisorAccountID, @SupervisorAccountName
	end else
	begin
		update [tbl_Account]
		set [Name] = @SupervisorAccountName
		where [ID] = @SupervisorAccountID
	end

	update [tbl_Contact]
	set [AccountID] = @SupervisorAccountID
	where [ID] = @SupervisorContactID

	insert into [tbl_License]
	select * from #tmp_License
	
	insert into [tbl_LicenseProduct]
	select * from #tmp_LicenseProduct
	
	insert into [tbl_LicenseModuleInProduct]
	select * from #tmp_LicenseModuleInProduct
	
	insert into [tbl_Report]
	select * from #tmp_Report
	
	insert into [tbl_RemindInterval]
	select * from #tmp_RemindInterval   

	insert into [tbl_SystemSetting] ([ID], [Code], [Description], [ValueTypeID], [StringValue], [DateTimeValue], [Caption])
	select newid(), [Code], [Description], [ValueTypeID], [StringValue], [DateTimeValue], [Caption]
	from #Customer
	
	set @DeleteSQL = 'DELETE FROM [tbl_Contact] WHERE ISNULL([Name], N'''') <> N''Supervisor'''
	print @DeleteSQL
	exec (@DeleteSQL)
	drop table #index
	drop table #tmp_License
	drop table #tmp_LicenseModuleInProduct
	drop table #tmp_LicenseProduct
	drop table #tmp_Report
	drop table #tmp_RemindInterval
	
	set nocount off
end