select * from Main..Audit_DDL_Events 
union all 
select * from Online_provider..Audit_DDL_Events 
order by DatabaseName, PostTime 



select PostTime,LoginName,UserName,DatabaseName, ObjectName, ObjectType,CommandText, IPAddress, ProgramName, CommandText  from Main..Audit_DDL_Events 
union all 
select PostTime,LoginName,UserName,DatabaseName, ObjectName, ObjectType,CommandText, IPAddress, ProgramName, CommandText from Online_provider..Audit_DDL_Events 
order by DatabaseName, PostTime desc
