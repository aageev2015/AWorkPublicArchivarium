
	if object_id('[dbo].[LOG_OF_SHOP]') is null
	begin
		create table [dbo].[LOG_OF_SHOP](
				[id] uniqueidentifier not null primary key default(newid())
			,	[Row_ver] rowversion
			,	[CreatedOn] datetime not null default(getdate())
			,	[context_info] uniqueidentifier not null default('{00000000-0000-0000-0000-000000000000}')
			,	[tag] varchar(250) null
	
			,	[old_ID] [int] NULL
			,	[new_ID] [int] NULL
			,	[old_CODE] [nvarchar](50) NULL
			,	[new_CODE] [nvarchar](50) NULL
			,	[old_NAME] [nvarchar](50) NULL
			,	[new_NAME] [nvarchar](50) NULL
			,	[old_ACTIVE] [char](1) NULL
			,	[new_ACTIVE] [char](1) NULL
			
			--.... removed fields ...

			,	[app_name] [nvarchar](128) NULL DEFAULT (app_name())
			,	[client_new_address] [varchar](25) NULL DEFAULT (CONVERT([varchar](25),connectionproperty('client_net_address'),0))
			,	[spid] [smallint] NULL DEFAULT (@@spid)
		)
	end
	GO

	

	if object_id('TR_LOG_SHOP') is not null 
		drop trigger [TR_LOG_SHOP]
	GO

	create trigger [TR_LOG_SHOP] on [dbo].[SHOP]
	after insert, update, delete
	as
	begin
		begin try
			declare @contextInfo uniqueidentifier = convert(uniqueidentifier, isnull(context_info(),0x0))
			insert into [dbo].[LOG_OF_SHOP](
				[context_info]
			,	[tag]
			, [old_ID], [old_CODE], [old_NAME], [old_ACTIVE], -- ... removed fields ...
			, [new_ID], [new_CODE], [new_NAME], [new_ACTIVE], -- ... removed fields ...
			)
			select 
				@contextInfo
			,	(case	when d.[ID] is not null and i.[ID] is not null then 'update'
						when d.[ID] is null and i.[ID] is not null then 'insert'
						else 'delete'
				end)
			, d.[ID], d.[CODE], d.[NAME], d.[ACTIVE], -- ... removed fields ...
			, i.[ID], i.[CODE], i.[NAME], i.[ACTIVE], -- ... removed fields ...
			from inserted i
			full join deleted d on i.id=d.id
		end try
		begin catch
			print 'in TR_LOG_SHOP error(' + convert(nvarchar(15), ERROR_NUMBER()) + '): ' + ERROR_MESSAGE()
		end catch
	end
	GO
	
