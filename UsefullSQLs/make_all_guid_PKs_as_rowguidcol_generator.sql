declare @sql nvarchar(max) = ''

SELECT @sql = @sql +
		replace(replace(replace(
N'alter table [%1].[%2] alter column [%3] ADD ROWGUIDCOL
go
',
			'%1',object_schema_name(ic.OBJECT_ID)),
			'%2',object_name(ic.OBJECT_ID)),
			'%3',columns.name  )
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic ON i.OBJECT_ID = ic.OBJECT_ID AND i.index_id = ic.index_id
INNER JOIN sys.columns columns on columns.object_id=ic.object_id and columns.column_id = ic.column_id
WHERE i.is_primary_key = 1
and TYPE_NAME(columns.system_type_id) = 'uniqueidentifier'
and COLUMNPROPERTY(ic.object_id, COL_NAME(ic.OBJECT_ID,ic.column_id)  , 'IsRowGuidCol') = 0

print @sql