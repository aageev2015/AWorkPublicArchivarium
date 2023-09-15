select  
	   resource_database_id
,	   l.resource_type
,	   o.name table_name
,	   o.id table_id
,	   count(*) cnt
from sys.dm_tran_locks l
left join sys.partitions p on p.hobt_id=l.resource_associated_entity_id
left join sysobjects o on o.id=p.object_id
where resource_database_id=9
group by resource_database_id,  l.resource_type, o.name,  o.id
order by cnt desc


/*
// key filtered
select  
    i.*
,   l.*
from sys.dm_tran_locks l
left join sys.partitions p on p.hobt_id=l.resource_associated_entity_id
left join sysobjects o on o.id=p.object_id
left join ITEM i on (i.%%lockres%%)=l.resource_description
where resource_database_id=9
and o.name='ITEM'
and l.resource_type='KEy'
order by i.id 
*/


/*
// with  transaction_id

select  
	   resource_database_id
,	   l.request_owner_id
,	   l.resource_type
,	   o.name table_name
,	   o.id table_id
,	   count(*) cnt
from sys.dm_tran_locks l
left join sys.partitions p on p.hobt_id=l.resource_associated_entity_id
left join sysobjects o on o.id=p.object_id
where resource_database_id=9
group by resource_database_id,  l.resource_type, l.request_owner_id, o.name,  o.id
order by cnt desc 
*/