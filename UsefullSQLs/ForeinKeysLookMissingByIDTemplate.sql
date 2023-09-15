--show all constrains fro tbl_Account, wich is not cascade
--all tables wich constrains with tbl_account and for wich give error on deleting record tbl_account, also show fields
select t2.name, t1.name from syscolumns t1
left join sysobjects t2 on ( 
	t1.id=t2.id
)
where exists(select * from tbl_Service t3 where t2.name=t3.code)
and t1.name like '%ID'
and not t1.name in ('ModifiedByID', 'CreatedByID', 'ID')
and not exists(
	select 	
		*
		
	from 	sysforeignkeys s, 
		sysobjects cid, 
		sysobjects fkid, 
		syscolumns fkcol
	where 	s.constid=cid.id
		and s.fkeyid=fkid.id
		and s.fkey=fkcol.colid
		and fkid.id=fkcol.id
	and fkid.id=t2.id
	and fkcol.name=t1.name
		and objectproperty(s.constid,'CnstIsDeleteCascade')=0
	group by cid.name,
		 fkid.name,
		 fkcol.name
)
order by t2.name,t1.name



	select 	
		(fkid.name +'.'+
		fkcol.name)  LeftTableName
		
	from 	sysforeignkeys s, 
		sysobjects cid, 
		sysobjects fkid, 
		sysobjects rkid,
		syscolumns fkcol,
		syscolumns rkcol
	where 	s.constid=cid.id
		and s.fkeyid=fkid.id
		and s.rkeyid=rkid.id
		and s.fkey=fkcol.colid
		and s.rkey=rkcol.colid
		and fkid.id=fkcol.id
		and rkid.id=rkcol.id
		and objectproperty(s.constid,'CnstIsDeleteCascade')=0
	group by cid.name,
		 fkid.name,
		 rkid.name,
		 fkcol.name,
		 rkcol.name 
	order by fkid.name,fkcol.name

