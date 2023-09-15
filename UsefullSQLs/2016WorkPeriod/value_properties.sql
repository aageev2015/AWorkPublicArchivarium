;with props as (
	select 'BaseType' as prop
		union	select 'TotalBytes' as prop
		union	select 'Precision' as prop
		union	select 'Scale' as prop
		union	select 'TotalBytes' as prop
		union	select 'Collation' as prop
		union	select 'MaxLength' as prop
)
select t.prop, SQL_VARIANT_PROPERTY(N'', t.prop)
from props t