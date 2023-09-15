--all user tables with columns, types, length
select obj.name as TableName,col.name as ColumnName, type.name as typeName,col.length 
from syscolumns col, sysobjects obj, systypes type
where col.id=obj.id
and col.xusertype=type.xusertype
and obj.xtype='U'
order by obj.name,col.name