CREATE SERVER AUDIT [AppLog_Audits]
TO FILE 
(	FILEPATH = N'D:\SQLDB\Audits\'
	,MAXSIZE = 0 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
)
ALTER SERVER AUDIT [AppLog_Audits] WITH (STATE = ON)
GO

CREATE SERVER AUDIT SPECIFICATION [InstanceAudits]
FOR SERVER AUDIT [AppLog_Audits]
ADD (BACKUP_RESTORE_GROUP),
ADD (AUDIT_CHANGE_GROUP),
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (BROKER_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (DATABASE_MIRRORING_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (LOGOUT_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (SERVER_STATE_CHANGE_GROUP),
ADD (DATABASE_OWNERSHIP_CHANGE_GROUP)
WITH (STATE = ON)
GO
