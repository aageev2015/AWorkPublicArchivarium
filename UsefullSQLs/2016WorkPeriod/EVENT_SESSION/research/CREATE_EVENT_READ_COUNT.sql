SELECT 
	count(*)
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