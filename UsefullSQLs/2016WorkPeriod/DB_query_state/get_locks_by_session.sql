select 
    'locks' t_name, resource_database_id, request_session_id, request_owner_id, count(*) as cnt
into #locks
from sys.dm_tran_locks
where resource_type='KEY'
group by resource_database_id, request_session_id, request_owner_id


select * from #locks
order by cnt desc

select 'active_trans' t_name, m.* from sys.dm_tran_active_transactions m
inner join #locks t on t.request_owner_id=m.transaction_id


select 'db_trans' as t_name, m.* from sys.dm_tran_database_transactions m
inner join #locks t on t.request_owner_id=m.transaction_id

select  * from sys.dm_exec_sessionsm
inner join #locks t on t.request_session_id=m.session_id

drop table #locks