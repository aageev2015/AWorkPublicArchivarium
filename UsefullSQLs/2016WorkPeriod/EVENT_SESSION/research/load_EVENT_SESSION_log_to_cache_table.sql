truncate table tbl_EVENT_SESSION_log
go
insert into tbl_EVENT_SESSION_log (
	[XEvent], writes, event_name, [timestamp], session_id, event_sequence, transaction_id, transaction_sequence, username, client_app_name, client_hostname, client_pid, [statement], [context_info], database_id, database_name, [object_name], attach_activity_id, process_id, session_nt_username
)
SELECT 
	XEvent,
	XEvent.value('(event/data[@name="writes"]/value)[1]', 'varchar(50)') AS writes,
    XEvent.value('(event/@name)[1]', 'varchar(50)') AS event_name,
    DATEADD(hh, 
            DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP),
            XEvent.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp],
    --XEvent.value('(event/data[@name="index_id"]/value)[1]', 'int') AS [index_id],						-- not exists - checked
    XEvent.value('(event/action[@name="session_id"]/value)[1]', 'int') AS [session_id],
	XEvent.value('(event/action[@name="event_sequence"]/value)[1]', 'int') AS [event_sequence],
	COALESCE(XEvent.value('(event/data[@name="transaction_id"]/value)[1]', 'int'), 
             XEvent.value('(event/action[@name="transaction_id"]/value)[1]', 'int')) AS [transaction_id],
	COALESCE(XEvent.value('(event/data[@name="transaction_sequence"]/value)[1]', 'bigint'), 
             XEvent.value('(event/action[@name="transaction_sequence"]/value)[1]', 'bigint')) AS [transaction_sequence],
    XEvent.value('(event/action[@name="username"]/value)[1]', 'nvarchar(100)') AS [username],
	XEvent.value('(event/action[@name="client_app_name"]/value)[1]', 'nvarchar(100)') AS client_app_name,
    XEvent.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(100)') AS [client_hostname],
    XEvent.value('(event/action[@name="client_pid"]/value)[1]', 'int') AS [client_pid],
    --XEvent.value('(event/data[@name="object_id"]/value)[1]', 'int') AS [object_id],				-- not exists - checked
    --XEvent.value('(event/data[@name="log_record_size"]/value)[1]', 'int') AS [log_record_size],	-- not exists - checked
    --XEvent.value('(event/data[@name="operation"]/text)[1]', 'varchar(50)') AS [operation],		-- not exists - checked
    --XEvent.value('(event/data[@name="context"]/text)[1]', 'varchar(50)') AS [context],
    --XEvent.value('(event/data[@name="transaction_start_time"]/value)[1]', 'datetime2') AS [transaction_start_time],
    --XEvent.value('(event/data[@name="replication_command"]/value)[1]', 'int') AS [replication_command],
    XEvent.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(1000)') AS [statement],
	--XEvent.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(1000)') AS [sql_text],		-- look statement
    --CAST(SUBSTRING(XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(50)'), 38, 10) AS int) as event_sequence,
	XEvent.value('(event/action[@name="context_info"]/value)[1]', 'nvarchar(100)') AS [context_info],
    COALESCE(XEvent.value('(event/data[@name="database_id"]/value)[1]', 'int'), 
             XEvent.value('(event/action[@name="database_id"]/value)[1]', 'int')) AS database_id,
	XEvent.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(1000)') AS [database_name],
	XEvent.value('(event/data[@name="object_name"]/value)[1]', 'nvarchar(1000)') AS [object_name],
	XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(50)') as attach_activity_id,
	XEvent.value('(event/action[@name="process_id"]/value)[1]', 'int') AS [process_id],
	XEvent.value('(event/action[@name="session_nt_username"]/value)[1]', 'nvarchar(100)') AS session_nt_username
	--XEvent.value('(event/action[@name="query_hash"]/value)[1]', 'nvarchar(100)') AS query_hash
FROM (
    SELECT CAST(event_data AS XML) AS XEvent
    FROM sys.fn_xe_file_target_read_file('d:\temp\MSSQL_Event_Session_Logs\AwesomeSystemV0_session*.xel', --FILENAME SHOULD BE CHECKED
	'd:\temp\MSSQL_Event_Session_Logs\AwesomeSystemV0_session*.xem', null, null)) as src				   --FILENAME SHOULD BE CHECKED
ORDER BY 
    DATEADD(hh, 
            DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), 
            XEvent.value('(event/@timestamp)[1]', 'datetime2')) desc,
    CAST(SUBSTRING(XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(50)'), 1, 36) AS uniqueidentifier) desc,
    CAST(SUBSTRING(XEvent.value('(event/action[@name="attach_activity_id"]/value)[1]', 'varchar(50)'), 38, 10) AS int) desc
GO


/*
-- look query by handle
select * from sys.dm_exec_sql_text(<varbinary handle here like 0x023403498...>) as t
*/