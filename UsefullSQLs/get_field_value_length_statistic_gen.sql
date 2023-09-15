select
	replace(
		'union select ''%1'' name, min(len([%1])) mn, max(len([%1])) mx, sum(len([%1])) sm, count(*) cnt, avg(len([%1])) avg from item_ext2 where [%1] is not null'
		,'%1', column_name),
	replace(
		'len(isnull([%1],''''))+'
		,'%1', column_name)
from INFORMATION_SCHEMA.columns
where table_name ='item_ext2'
and data_type='nvarchar'
