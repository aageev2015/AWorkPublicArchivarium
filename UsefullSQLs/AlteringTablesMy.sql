declare @TableName sysname
declare @TableID int
declare @sql nvarchar(4000)
declare @NewStrCode varchar(2)
set @NewStrCode = char(13)+char(10)

declare TableNames cursor for 
select t1.name as TableName, t1.id TableID from sysobjects t1
where objectproperty(t1.id,'IsUserTable')=1
and not exists(	select * from sysobjects t2 
		where 	t1.id=t2.parent_obj
			and Objectproperty(t2.id,'IsConstraint')=1
			and Objectproperty(t2.id,'IsPrimaryKey')=1
	)
and t1.name not like 'aaa_%'
and t1.name <> 'dtproperties'
order by t1.name

open TableNames
fetch next from TableNames into @TableName, @TableID

--begin tran
while @@fetch_status = 0
begin		
	--if (@TableName='tbl_IncidentMessage') continue
	set @sql='if (exists(select * from syscolumns where id='+cast(@TableID as varchar(16))+' and isnullable=1 and name like ''ID'')) '+@NewStrCode+
		  '	alter table ' + @TableName + ' alter column [ID] uniqueidentifier not null'
	print @sql
	exec (@sql)
	set @sql='if (exists(select * from syscolumns where id='+cast(@TableID as varchar(16))+' and isnullable=1 and name like ''ID'')) '+@NewStrCode+
		  '	alter table ' + @TableName + ' alter column [ID] ADD ROWGUIDCOL'
	print @sql
	exec (@sql)
	set @sql='alter table ' + @TableName + ' add constraint P' + replace(@TableName,'tbl_','') + 'ID primary key clustered (id) on [primary]'
	print @sql
	exec (@sql)
	set @sql='alter table ' + @TableName + ' add constraint PDF' + replace(@TableName,'tbl_','') + 'ID default (newid()) for [id]'
	print @sql
	exec (@sql)
	fetch next from TableNames into @TableName, @TableID
end

close TableNames
deallocate TableNames


--rollback
