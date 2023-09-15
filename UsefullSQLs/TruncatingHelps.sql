--show all constrains for tbl_Account, which is not cascade
--all tables wich constrains with tbl_account and which raise error on deleting record tbl_account, also show fields
select 	--'alter table '+fkid.name+' check CONSTRAINT ALL',
	'alter table '+fkid.name+' drop constraint '+cid.name
	--'ALTER TABLE '+fkid.name+' ADD CONSTRAINT '+cid.name+' FOREIGN KEY ('+fkcol.name+') REFERENCES [tbl_Cashflow] ([ID])'
/*,
	cid.name fkName,
	fkid.name LeftTableName,
	fkcol.name LeftColumnName,
	'=' as equal,
	rkid.name RightTableName,
	rkcol.name RightColumnName*/
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
	and rkid.name='tbl_purchase'
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
