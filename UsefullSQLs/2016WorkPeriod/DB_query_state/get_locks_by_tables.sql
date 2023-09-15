create table #tmp_sp_lock(
    spid int
,   dbid int
,   objid int
,   indid int
,   type nvarchar(50)
,   resource nvarchar(100)
,   mode nvarchar(50)
,   status nvarchar(50)
)


insert INTO    #tmp_sp_lock
exec sp_lock

select o.id, o.name obj_name, d.database_id, d.name as dbname, count(*) cnt from #tmp_sp_lock l
inner join sys.databases d on d.database_id=l.dbid
inner join sysobjects o on o.id=l.objid
group by o.id,  o.name, d.database_id, d.name
order by cnt desc

drop table #tmp_sp_lock

