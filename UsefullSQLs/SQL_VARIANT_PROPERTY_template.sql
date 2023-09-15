select 
SQL_VARIANT_PROPERTY(val,'BaseType') BaseType, 
SQL_VARIANT_PROPERTY(val,'Precision') Precision,
SQL_VARIANT_PROPERTY(val,'Scale') Scale,
SQL_VARIANT_PROPERTY(val,'TotalBytes') TotalBytes,
SQL_VARIANT_PROPERTY(val,'Collation') Collation,
SQL_VARIANT_PROPERTY(val,'MaxLength') MaxLength
from ( values(convert(char(8000), '')) ) t(val)



select 
	prop, SQL_VARIANT_PROPERTY(val, prop)	
from ( values(convert(char(8000), '')) ) val(val)
cross join (values
	('BaseType'),
	('Precision'),
	('Scale'),
	('TotalBytes'),
	('Collation'),
	('MaxLength')
) prop(prop)