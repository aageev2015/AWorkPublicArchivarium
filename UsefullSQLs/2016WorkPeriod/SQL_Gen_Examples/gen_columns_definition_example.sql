

select  TABLE_NAME, '
		,	['+COLUMN_NAME+'] ' + 
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
from information_schema.columns

order by ordinal_position