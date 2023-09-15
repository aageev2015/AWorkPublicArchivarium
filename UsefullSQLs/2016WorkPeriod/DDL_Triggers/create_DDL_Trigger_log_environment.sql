/*
-- get logged data

select * from AdminDB.dbo.DDL_Security_Audit_LOG
order by eventid desc

*/

if not exists( select * from sys.databases where name='AdminDB')
begin
    Create DataBase AdminDB;
end

go

use AdminDB;

go

if object_id('DDL_Security_Audit_LOG') is null 
begin
    --drop table AdminDB.dbo.DDL_Security_Audit_LOG
    CREATE TABLE dbo.DDL_Security_Audit_LOG  (
	   EventId int NOT NULL IDENTITY (1, 1) PRIMARY KEY
    ,   EventTime datetime
    ,   DbName nvarchar(100)
    ,   EventType nvarchar(100)
    ,   UserName nvarchar(100)
    ,   HostName nvarchar (100)
    ,   EventTSQL nvarchar(3000)
    ,   spid int
    ,   connect_time datetime
    ,   client_program_name nvarchar(250)
    ,   client_interface_name nvarchar(250)
    ,   client_net_address varchar(50)
    ,   client_tcp_port int
    ,   client_process_id int
    ,   local_net_address varchar(50)
    ,   Data_XML xml
    )
end

go

if exists(select * from  sys.server_triggers where name='DDL_Security_Audit')
begin
    drop trigger [DDL_Security_Audit] ON ALL SERVER
end
go

Create TRIGGER [DDL_Security_Audit]
ON ALL SERVER
FOR DDL_DATABASE_SECURITY_EVENTS, DDL_DATABASE_EVENTS, DDL_SERVER_SECURITY_EVENTS, DDL_TRIGGER_EVENTS
AS
BEGIN

	if object_id('AdminDB..DDL_Security_Audit_LOG') is null
		return

    Declare @ObjectName nvarchar(100) =  EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(100)')

    Declare @EventType nvarchar(100) =  EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)')

    Declare @DbName  nvarchar(100) = isnull( EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(1000)'),'Master')

    Declare @Command nvarchar(1000) =  EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(1000)')

    declare @connect_time datetime;
    declare @client_program_name nvarchar(250);
    declare @client_interface_name nvarchar(250);
    declare @client_net_address varchar(50);
    declare @client_tcp_port int;
    declare @client_process_id int;
    declare @local_net_address varchar(50);

    select  @connect_time = connect_time
    ,	  @client_net_address = client_net_address
    ,	  @client_tcp_port = client_tcp_port
    ,	  @local_net_address = local_net_address
    from sys.dm_exec_connections
    where session_id=@@spid

    select  @client_program_name = program_name
    ,	  @client_interface_name = client_interface_name
    ,	  @client_process_id = host_process_id
    from sys.dm_exec_sessions
    where session_id=@@spid

    INSERT INTO AdminDB..DDL_Security_Audit_LOG
    VALUES (
	   GETDATE()
	,  @DbName
	,  @EventType
	,  suser_sname()
	,  HOST_NAME()
	,  @Command
	,  @@SPID
	,  @connect_time
	,  @client_program_name
	,  @client_interface_name
	,  @client_net_address
	,  @client_tcp_port
	,  @client_process_id
	,  @local_net_address
	,  EVENTDATA()
	)
END
GO

