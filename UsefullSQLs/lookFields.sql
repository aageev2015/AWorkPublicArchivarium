select 	t1.name tableName, 
	t2.Name as columnName, 
	(case when t3.name='nvarchar' then
		t3.name+ '('+cast(t2.length as varchar(5))+')'
	else
		t3.name
	end)  as type,
	t5.name+'.'+t6.name as Relation
from sysobjects t1	
inner join syscolumns t2 on (
	t1.id=t2.id
)
inner join systypes t3 on (
	t2.xusertype=t3.xusertype

)
left join sysforeignkeys t4 on (
	t4.fkeyid = t1.id and
	t4.fkey = t2.colid
)
left join sysobjects t5 on (
	t4.rkeyid=t5.id
)
left join syscolumns t6 on (
	t6.colid=t4.rkey and
	t6.id=t4.rkeyid
)
where t1.xtype ='U'
and (
t1.name = 'tbl_Account' or
t1.name = 'tbl_Contact' or
t1.name = 'tbl_Opportunity' or
t1.name = 'tbl_Contract' or
t1.name = 'tbl_Document' or
t1.name = 'tbl_Task' or
t1.name = 'tbl_Incident' 
)
order by t1.name,t2.colid


select * from sysforeignkeys