--script generator

select 
--code,path
'print '''+code+'''
insert into '+code+'
select * from Demo331..'+code+' t1
where not exists(select * from '+code+' t2 where t1.id=t2.id)
update t1
set CreatedById=''{CCACD52F-B640-477A-8A86-A17032120446}'',
    ModifiedOn=t2.modifiedon
from '+code+' t1,InfopulseDemo331..'+code+' t2
where t1.id=t2.id
------------------------'
 from tbl_Service
where serviceTypeCode ='Table'
and (path like 'ConfigurationItem%')
and code not like '%right'