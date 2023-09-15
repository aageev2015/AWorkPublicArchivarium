--- merge
create table #tmp(val int primary key, caption nvarchar(100))
create table #tmpNew(val int primary key)

insert into #tmp(val) select * from dbo.fn_genrows(10000)
insert into #tmpnew select number+9000 from dbo.fn_genrows(10000)

DBCC DROPCLEANBUFFERS
begin tran

	MERGE INTO #tmp AS t1  
	USING #tmpnew AS t2 
	ON t1.val = t2.val
	WHEN MATCHED THEN  
		UPDATE SET caption = 'updated ' + convert(nvarchar(10), t2.val)
	WHEN NOT MATCHED BY TARGET THEN  
		INSERT VALUES (t2.Val, 'inserted');
commit

select * from #tmp order by val

drop table #tmp
drop table #tmpNew
GO
-- insert-update

create table #tmp(val int primary key, caption nvarchar(100))
create table #tmpNew(val int primary key)

insert into #tmp(val) select * from dbo.fn_genrows(10000)
insert into #tmpnew select number+9000 from dbo.fn_genrows(10000)

DBCC DROPCLEANBUFFERS
begin tran

	update t1 
	set caption = 'updated ' + convert(nvarchar(10), t2.val)
	from #tmp t1
	inner join #tmpnew t2 on t1.val=t2.val

	insert into #tmp (val, caption)
	select t2.val, 'inserted' from #tmpnew t2
	left join #tmp t1 on t1.val=t2.val
	where t1.val is null
	
commit

select * from #tmp order by val

drop table #tmp
drop table #tmpNew