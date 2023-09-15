/*
select 
	'union select '''+Table_Name+''' table_name, count(*) as cnt from [' + table_name + ']'
from INFORMATION_SCHEMA.TABLES

*/

create table table_statictis(
	table_name nvarchar(50)
,	cnt int 
)

insert into table_statictis
select 'BARCODE' table_name, count(*) as cnt from [BARCODE]
... removed ~5...
union select 'SENDING_LINE_DVL' table_name, count(*) as cnt from [SHIPPING_LINE_DVL]
union select 'HISTORY' table_name, count(*) as cnt from [HISTORY]
... removed ~5...
union select 'ITEM' table_name, count(*) as cnt from [ITEM]
... removed ~100 ...