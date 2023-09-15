-- https://www.mssqltips.com/sqlservertip/2144/an-overview-of-extended-events-in-sql-server-2008/
-- https://www.mssqltips.com/sqlservertip/2155/getting-started-with-extended-events-in-sql-server-2008/
-- with not existed read info: https://amihalj.wordpress.com/2013/01/29/tracking-transaction-log-records-with-sql-server-2012-extended-events/

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AwesomeSystemV0_session')
    DROP EVENT session AwesomeSystemV0_session ON SERVER;
GO

/*
-- by myself
CREATE EVENT SESSION AwesomeSystemV0_session
ON SERVER
ADD EVENT sqlserver.rpc_completed (
	SET collect_statement = (1)
    ACTION (    
        package0.collect_system_time,
        package0.event_sequence,
		package0.process_id,
		sqlserver.session_id,
		sqlserver.client_connection_id,
		sqlserver.transaction_id,
		sqlserver.transaction_sequence,
		sqlserver.request_id,
		sqlserver.client_pid,
		sqlserver.database_id,
		sqlserver.database_name,
		sqlserver.client_hostname,
		sqlserver.nt_username,
		sqlserver.username,
		sqlserver.client_app_name,
		sqlserver.session_nt_username,
		sqlserver.sql_text,
		sqlserver.context_info
    ) 
    WHERE
		sqlserver.database_id = 34 --ID OF THE DATABASE
)
ADD TARGET package0.asynchronous_file_target(
	SET filename=N'd:\temp\MSSQL_Event_Session_Logs\AwesomeSystemV0_session.xel'		--FILENAME SHOULD BE CHECKED
	,	metadatafile=N'd:\temp\MSSQL_Event_Session_Logs\AwesomeSystemV0_session.xem'	--FILENAME SHOULD BE CHECKED
	,	max_file_size=(100)
)	
WITH (	MAX_MEMORY = 64MB
	,	EVENT_RETENTION_MODE = NO_EVENT_LOSS
	,	TRACK_CAUSALITY = ON
	,	STARTUP_STATE = ON
	,	MAX_DISPATCH_LATENCY = 30 SECONDS
);
GO
*/


-- by wizard help
CREATE EVENT SESSION AwesomeSystemV0_session ON SERVER 
ADD EVENT sqlserver.rpc_completed(
	SET collect_data_stream=(0)
	,	collect_statement=(1)
    ACTION(
		--package0.callstack,	-- callstack from sql server dlls
		--package0.collect_cpu_cycle_time,
		--package0.collect_current_thread_id,
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
		--sqlserver.server_principal_name,
		--sqlserver.server_principal_sid,
		sqlserver.session_id,
		sqlserver.session_nt_username,
		--sqlserver.session_server_principal_name,
		--sqlserver.sql_text,			-- statement contains this and last is more informative
		sqlserver.transaction_id,
		sqlserver.transaction_sequence,
		sqlserver.username
		--sqlserver.query_hash -- is 0 all time
	)
    WHERE (
		[sqlserver].[database_id]=(5)
	and	writes>0
	)
)
,
ADD EVENT sqlserver.sp_statement_completed(
	SET collect_object_name=(1)
    ACTION(
		--package0.callstack,
		--package0.collect_cpu_cycle_time,
		--package0.collect_current_thread_id,
		--package0.collect_system_time,
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
		--sqlserver.server_principal_name,
		--sqlserver.server_principal_sid,
		sqlserver.session_id,
		sqlserver.session_nt_username,
		--sqlserver.session_server_principal_name,
		--sqlserver.sql_text,
		sqlserver.transaction_id,
		sqlserver.transaction_sequence,
		sqlserver.username,
		sqlserver.tsql_stack
		--sqlserver.query_hash
	)
    WHERE (
			[sqlserver].[database_id]=(5)
		and	writes>0
	and object_name <> 'USER_SP_SYS_CALC'
	and object_name <> 'USER_SP_SYS_CALC_AREA'
	and object_name <> 'USER_SP_SYS_CALC_AREA_template'
	and object_name <> 'USER_CREATE_SYS_CALC_AREA'
	and object_name <> 'Dynamic SQL'
	)
)


ADD TARGET package0.asynchronous_file_target(
				SET filename=		N'c:\SQLLogs\AwesomeSystemV0_session.xel'
				,	metadatafile=	N'c:\SQLLogs\AwesomeSystemV0_session.xem'
				,	max_file_size=(100)
)
WITH (
	MAX_MEMORY=64MB
,	EVENT_RETENTION_MODE=NO_EVENT_LOSS
,	TRACK_CAUSALITY=ON
,	STARTUP_STATE=ON
,	MAX_DISPATCH_LATENCY = 10 SECONDS
)
GO





/*
--START LOGGING
ALTER EVENT SESSION AwesomeSystemV0_session
ON SERVER
STATE=START

GO
*/

--STOP LOGGING
/*
ALTER EVENT SESSION AwesomeSystemV0_session
ON SERVER
STATE=STOP
GO
*/