/*
	exec sp_gen_log_of_infra 'SHIPPING_DETAILS', 'dbo', 'PRINT'
*/

if object_id('sp_gen_log_of_infra ') is not null
	drop procedure [sp_gen_log_of_infra]
go

create procedure sp_gen_log_of_infra 
	@tableName nvarchar(250),
	@schemaName nvarchar(250) = 'dbo',
	@output varchar(10) = 'PRINT' -- Print, Exec, PrintExec\ExecPrint

as 
begin
	-------------------------   generator code -------------------

	set @tableName = upper(@tableName);

	set @output = upper(@output);
	declare @print int = iif(@output='PRINT' or @output = 'PRINTEXEC' or @output = 'EXECPRINT', 1, 0);
	declare @exec int = iif(@output='EXEC' or @output = 'PRINTEXEC' or @output = 'EXECPRINT', 1, 0);


	---  LOG_OF_@tableName -----
	declare @log_table_Name nvarchar(250) = 'LOG_OF_' + @tableName;

	declare @sql nvarchar(max)='
	if object_id(''[' + @schemaName + '].[' + @log_table_Name + ']'') is null
	begin
		create table [' + @schemaName + '].[' + @log_table_Name + '](
				[id] uniqueidentifier not null primary key default(newid())
			,	[Row_ver] rowversion
			,	[CreatedOn] datetime not null default(getdate())
			,	[context_info] uniqueidentifier not null default(''{00000000-0000-0000-0000-000000000000}'')
			,	[tag] varchar(250) null
	'


	select @sql=@sql+'
			,	[old_'+COLUMN_NAME+'] ' + 
					(case DATA_TYPE
						when 'bigint' then '[bigint]'
						when 'bit' then '[bit]'
						when 'char' then '[char](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
						when 'datetime' then '[datetime]'
						when 'decimal' then '[decimal](' + convert(varchar(20), numeric_precision) + ', ' + convert(varchar(20), numeric_scale) + ')'
						when 'float' then '[float]'
						when 'image' then '[image]'
						when 'int' then '[int]'
						when 'money' then '[money]'
						when 'nchar' then '[nchar](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
						when 'ntext' then '[ntext]'
						when 'numeric' then '[numeric]'
						when 'nvarchar' then '[nvarchar](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
						when 'smallint' then '[smallint]'
						when 'timestamp' then '[timestamp]'
						when 'uniqueidentifier' then '[uniqueidentifier]'
						when 'varbinary' then '[varbinary](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
						when 'varchar' then '[varchar](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
						else '<UnkownType>'
					end) 
			+ ' NULL
			,	[new_'+COLUMN_NAME+'] ' + 
				(case DATA_TYPE
					when 'bigint' then '[bigint]'
					when 'bit' then '[bit]'
					when 'char' then '[char](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
					when 'datetime' then '[datetime]'
					when 'decimal' then '[decimal](' + convert(varchar(20), numeric_precision) + ', ' + convert(varchar(20), numeric_scale) + ')'
					when 'float' then '[float]'
					when 'image' then '[image]'
					when 'int' then '[int]'
					when 'money' then '[money]'
					when 'nchar' then '[nchar](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
					when 'ntext' then '[ntext]'
					when 'numeric' then '[numeric]'
					when 'nvarchar' then '[nvarchar](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
					when 'smallint' then '[smallint]'
					when 'timestamp' then '[timestamp]'
					when 'uniqueidentifier' then '[uniqueidentifier]'
					when 'varbinary' then '[varbinary](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
					when 'varchar' then '[varchar](' + (case when character_maximum_length = -1 then 'max' else convert(varchar(20), character_maximum_length) end)+ ')'
					else '<UnkownType>'
				end) 
			+ ' NULL'
	from information_schema.columns
	where table_name = @tableName
	and data_type not in ('timestamp')
	and table_schema = @schemaName
	order by ordinal_position

	set @sql=@sql+'

			,	[app_name] [nvarchar](128) NULL DEFAULT (app_name())
			,	[client_new_address] [varchar](25) NULL DEFAULT (CONVERT([varchar](25),connectionproperty(''client_net_address''),0))
			,	[spid] [smallint] NULL DEFAULT (@@spid)
		)
	end
	GO

	'

	if (@print = 1 )
		print @sql
	if (@exec = 1 )
		exec (@sql)

	--- TR_LOG_@tableName

	declare @tr_log_name nvarchar(250) = 'TR_LOG_' + @tableName;

	set @sql = '
	if object_id(''' + @tr_log_name + ''') is not null 
		drop trigger [' + @tr_log_name + ']
	GO

	create trigger [' + @tr_log_name + '] on ['+@schemaName+'].[' + @tableName + ']
	after insert, update, delete
	as
	begin
		begin try
			declare @contextInfo uniqueidentifier = convert(uniqueidentifier, isnull(context_info(),0x0))
			insert into ['+@schemaName+'].[' + @log_table_Name + '](
				[context_info]
			,	[tag]
			';

	select
		@sql = @sql + ', [old_' + column_name + ']'
	from information_schema.columns
	where table_name = @tableName
	and data_type not in ('timestamp')
	and table_schema = @schemaName
	order by ordinal_position;

	set @sql = @sql + '
			';

	select
		@sql = @sql + ', [new_' + column_name + ']'
	from information_schema.columns
	where table_name = @tableName
	and data_type not in ('timestamp')
	and table_schema = @schemaName
	order by ordinal_position;

	set @sql = @sql + '
			)
			select 
				@contextInfo
			,	(case	when d.[ID] is not null and i.[ID] is not null then ''update''
						when d.[ID] is null and i.[ID] is not null then ''insert''
						else ''delete''
				end)
			';

	select
		@sql = @sql + ', d.[' + column_name + ']'
	from information_schema.columns
	where table_name = @tableName
	and data_type not in ('timestamp')
	and table_schema = @schemaName
	order by ordinal_position;

	set @sql = @sql + '
			';

	select
		@sql = @sql + ', i.[' + column_name + ']'
	from information_schema.columns
	where table_name = @tableName
	and data_type not in ('timestamp')
	and table_schema = @schemaName
	order by ordinal_position;

	set @sql = @sql + '
			from inserted i
			full join deleted d on i.id=d.id
		end try
		begin catch
			print ''in TR_LOG_@tableName error('' + convert(nvarchar(15), ERROR_NUMBER()) + ''): '' + ERROR_MESSAGE()
		end catch
	end
	GO
	'

	if (@print = 1 )
		print @sql
	if (@exec = 1 )
		exec (@sql)
end