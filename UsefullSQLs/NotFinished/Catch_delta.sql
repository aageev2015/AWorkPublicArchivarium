select * from INFORMATION_SCHEMA.TABLES t
where not exists(select * from INFORMATION_SCHEMA.COLUMNS c where c.TABLE_NAME = t.TABLE_NAME and c.COLUMN_NAME = 'ID')
and TABLE_TYPE = 'BASE TABLE'
and table_schema in ('dbo','domain1','domain2', 'transfer')
and table_name not in ('__MigrationHistory', 'DESCRIPT_COMMENTS', 'SEQUENCES', 'PROCEDURES_LOG')
and table_name not like '%test%'
and table_name not like '%temp%'


STOCK
HISTORY

transfer.