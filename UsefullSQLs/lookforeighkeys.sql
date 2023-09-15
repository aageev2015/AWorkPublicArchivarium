--show all constrains for tbl_Account, which is not cascade
--all tables wich constrains with tbl_account and which raise error on deleting record tbl_account, also show fields
select 	f_obj.name fkName,
	fkid.name LeftTableName,
	fkcol.name LeftColumnName,
	'=' as equal,
	rkid.name RightTableName,
	rkcol.name RightColumnName
	
from 	sysforeignkeys f
inner join sysobjects f_obj on f.constid=f_obj.id
inner join sysobjects fkid on f.fkeyid=fkid.id
	inner join syscolumns fkcol on fkid.id=fkcol.id and f.fkey=fkcol.colid
inner join sysobjects rkid on f.rkeyid=rkid.id
	inner join syscolumns rkcol on rkid.id=rkcol.id and f.rkey=rkcol.colid
where 
rkid.name='tbl_OfferingMovement' and 
objectproperty(f.constid,'CnstIsDeleteCascade')=0
group by f_obj.name,
	 fkid.name,
	 rkid.name,
	 fkcol.name,
	 rkcol.name 
order by f_obj.name,
	 fkid.name,
	 rkid.name,
	 fkcol.name,
	 rkcol.name 

/*
select 	cid.name fkName,
	fkid.name LeftTableName,
	fkcol.name LeftColumnName,
	'=' as equal,
	rkid.name RightTableName,
	rkcol.name RightColumnName
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
	and rkid.name='tbl_OfferingMovement'
	and objectproperty(s.constid,'CnstIsDeleteCascade')=0
group by cid.name,
	 fkid.name,
	 rkid.name,
	 fkcol.name,
	 rkcol.name 
order by cid.name,
	 fkid.name,
	 rkid.name,
	 fkcol.name,
	 rkcol.name 
*/