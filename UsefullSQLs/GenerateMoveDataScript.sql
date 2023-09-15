declare @UpdatedTableName varchar(100)
set @UpdatedTableName='tbl_Account'

declare @SelectTemp varchar(4000)

declare @FieldsCompare varchar(4000)
set @FieldsCompare=''

select @FieldsCompare=@FieldsCompare+
't1.'+t2.name+'=t2.'+t2.name +',
'
from Company1Demo330..sysobjects t1
inner join syscolumns t2 on (
	t1.id=t2.id
)
left join company2Demo330..sysobjects t3 on (
	t1.name=t3.name
)
left join company2demo330..syscolumns t4 on (
	t3.id=t4.id
	and t4.name=t2.name
)
where t1.name ='tbl_Account'

set @SelectTemp='
update t1 set
'+substring(@FieldsCompare, 1, len(@FieldsCompare)-3) + '
from tbl_Account t1, company2Demo330..tbl_Account t2
where t1.id=t2.id'

print @SelectTemp