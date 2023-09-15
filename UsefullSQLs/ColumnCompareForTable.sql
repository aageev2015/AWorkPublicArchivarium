
declare @str varchar(1000)
set @str=''
select  @str=@str+','+t2.name from crmDB320..sysobjects t1
inner join crmDB320..syscolumns t2
on t2.id=t1.id
where exists (select *
	from sysobjects t3 
	inner join syscolumns t4
		on t3.id=t4.id
	where t3.name=t1.name
		and t2.name=t4.name
)
and 
	t1.name='tbl_Task'
print @str