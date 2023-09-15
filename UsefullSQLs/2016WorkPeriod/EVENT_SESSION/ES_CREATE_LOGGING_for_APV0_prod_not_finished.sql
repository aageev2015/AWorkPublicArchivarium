-- https://www.mssqltips.com/sqlservertip/2144/an-overview-of-extended-events-in-sql-server-2008/
-- https://www.mssqltips.com/sqlservertip/2155/getting-started-with-extended-events-in-sql-server-2008/
-- with not existed read info: https://amihalj.wordpress.com/2013/01/29/tracking-transaction-log-records-with-sql-server-2012-extended-events/

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AwesomeSystemV0_event_session')
    DROP EVENT session AwesomeSystemV0_event_session ON SERVER;
GO


-- by wizard help
CREATE EVENT SESSION AwesomeSystemV0_event_session ON SERVER 
ADD EVENT sqlserver.rpc_completed(
	SET collect_data_stream=(0)
	,	collect_statement=(1)
    ACTION(
		package0.collect_system_time,
		package0.event_sequence,
		package0.last_error,
		package0.process_id,
		sqlos.system_thread_id,
		sqlserver.client_app_name,
		sqlserver.client_connection_id,
		sqlserver.client_hostname,
		sqlserver.client_pid,
		sqlserver.context_info,
		sqlserver.database_id,
		sqlserver.database_name,
		sqlserver.is_system,
		sqlserver.nt_username,
		sqlserver.request_id,
		sqlserver.session_id,
		sqlserver.session_nt_username,
		sqlserver.transaction_id,
		sqlserver.transaction_sequence,
		sqlserver.username
	)
    WHERE (
		[sqlserver].[database_id]=(<db_id result here>)
	and	writes>0
	)
)
,
ADD EVENT sqlserver.sp_statement_completed(
	SET collect_object_name=(1)
    ACTION(
		package0.event_sequence,
		package0.last_error,
		package0.process_id,
		sqlos.system_thread_id,
		sqlserver.client_app_name,
		sqlserver.client_connection_id,
		sqlserver.client_hostname,
		sqlserver.client_pid,
		sqlserver.context_info,
		sqlserver.database_id,
		sqlserver.database_name,
		sqlserver.is_system,
		sqlserver.nt_username,
		sqlserver.request_id,
		sqlserver.session_id,
		sqlserver.session_nt_username,
		sqlserver.transaction_id,
		sqlserver.transaction_sequence,
		sqlserver.username,
		sqlserver.tsql_stack
	)
    WHERE (
			[sqlserver].[database_id]=(<db_id result here>)
		and	writes>0
	and object_name <> 'USER_SOMETHING_CALCULATE'
	and object_name <> 'USER_SOMETHING_CALCULATE_AREA'
	and object_name <> 'USER_SOMETHING_CALCULATE_AREA_template'
	and object_name <> 'USER_CREATE_PARAMS_FOR_AREA'
	and object_name <> 'Dynamic SQL'
	
	)
)


ADD TARGET package0.asynchronous_file_target(
				SET filename=		N'<full file path here>.xel'		--N'd:\temp\MSSQL_Event_Session_Logs\AwesomeSystemV0_event_session.xel'
				,	metadatafile=	N'<full file path here>.xem' 	--N'd:\temp\MSSQL_Event_Session_Logs\AwesomeSystemV0_event_session.xem'
				,	max_file_size=(100)
)
WITH (
	MAX_MEMORY=64MB
,	EVENT_RETENTION_MODE=NO_EVENT_LOSS
,	TRACK_CAUSALITY=ON
,	STARTUP_STATE=ON
,	MAX_DISPATCH_LATENCY = 30 SECONDS
)
GO





/*
--START LOGGING
ALTER EVENT SESSION AwesomeSystemV0_event_session
ON SERVER
STATE=START

GO
*/

--STOP LOGGING
/*
ALTER EVENT SESSION AwesomeSystemV0_event_session
ON SERVER
STATE=STOP
GO
*/