declare @DiagramID uniqueidentifier
set @DiagramID = '{34F0E9CB-E306-4DE8-994A-44C6E24BF2FD}'



delete from tbl_task
where id in (
select id from tbl_task t1
where workflowitemid in 
	(select t2.id from tbl_workflowitem t2 where 
		t2.workflowid in (select t3.id from 
			tbl_workflow t3 where t3.DiagramServiceID=@DiagramID
)))

delete from 
tbl_workflow where DiagramServiceID=@DiagramID
