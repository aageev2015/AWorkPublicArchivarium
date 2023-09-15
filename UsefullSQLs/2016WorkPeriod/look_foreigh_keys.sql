
select 
    
   t1.name as right_table, c1.name right_column, t2.name left_table, c2.name left_column, object_name(fk.constid), fk.*
   --'select '''+c1.Name+''' as table_name,* from ['+c1.name+'] where ['+c1.name+']='''+@searchAsString+''''
from sysforeignkeys fk
inner join sysobjects t1 on fk.fkeyid=t1.id
inner join syscolumns c1 on c1.id=t1.id and c1.colid=fk.fkey
inner join sysobjects t2 on fk.rkeyid=t2.id
inner join syscolumns c2 on c2.id=t2.id and c2.colid=fk.rkey
where 'ITEM.ID' in (t1.name+'.'+c1.name, t2.name+'.'+c2.name)
and objectproperty(fk.constid, 'CnstIsDeleteCascade') = 0
