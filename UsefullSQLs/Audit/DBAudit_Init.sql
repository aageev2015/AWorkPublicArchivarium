SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Audit_DDL_Events](
	[ID] [uniqueidentifier] ROWGUIDCOL  NOT NULL default(newid())
,	[PostTime] [nvarchar](50) NULL
,	[LoginName] [nvarchar](150) NULL
,	[UserName] [nvarchar](150) NULL
,	[DatabaseName] [nvarchar](150) NULL
,	[SchemaName] [nvarchar](150) NULL
,	[ObjectName] [nvarchar](150) NULL
,	[ObjectType] [nvarchar](150) NULL
,   [HostName]    NVARCHAR(64) null
,   [IPAddress]   NVARCHAR(32) null
,   [ProgramName] NVARCHAR(255) null
,	[CommandText] [nvarchar](max) NULL
,	[EventData] xml null
 CONSTRAINT [PAudit_DDL_EventsID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


CREATE  TRIGGER [tr_Audit_DDL] 
ON DATABASE 
AFTER DDL_DATABASE_LEVEL_EVENTS
--CREATE_TABLE, ALTER_TABLE, DROP_TABLE, 
--NOT FOR REPLICATION 
AS 
BEGIN
	SET NOCOUNT ON
	DECLARE @event xml; 
	DECLARE @ip VARCHAR(32) =
		(
			SELECT client_net_address
				FROM sys.dm_exec_connections
				WHERE session_id = @@SPID
		);
	declare @LoginName nvarchar(150);
	declare @ObjectType nvarchar(150);

	SET @event = EVENTDATA(); 

	set @LoginName = CONVERT(nvarchar(150), @event.query('data(/EVENT_INSTANCE/LoginName)'));
	set @ObjectType = CONVERT(nvarchar(150), @event.query('data(/EVENT_INSTANCE/ObjectType)'));

	/*
	-- filter
	if	(	(	(@LoginName = 'EVPARIS\sqlworker') and 
				(@ObjectType in ('STATISTICS', 'INDEX'))
			)
		) 
	begin
		return;
	end
	*/

	INSERT INTO [Audit_DDL_Events] (
		[PostTime]
	,	[LoginName]
	,	[UserName]
	,	[DatabaseName]
	,	[SchemaName]
	,	[ObjectName]
	,	[ObjectType]
	,	[CommandText]
	,	[EventData]
	,	[HostName]
	,	[IPAddress]
	,	[ProgramName]
	)
	VALUES ( 
		REPLACE(CONVERT(nvarchar(50), @event.query('data(/EVENT_INSTANCE/PostTime)')), 'T', ' ')
	,	@LoginName
	,	CONVERT(nvarchar(150), @event.query('data(/EVENT_INSTANCE/UserName)')) 
	,	CONVERT(nvarchar(150), @event.query('data(/EVENT_INSTANCE/DatabaseName)')) 
	,	CONVERT(nvarchar(150), @event.query('data(/EVENT_INSTANCE/SchemaName)'))  
	,	CONVERT(nvarchar(150), @event.query('data(/EVENT_INSTANCE/ObjectName)'))  
	,	@ObjectType
	,	REPLACE(CONVERT(nvarchar(max), @event.query('data(/EVENT_INSTANCE/TSQLCommand/CommandText)')), '&#x0D;', char(13) + char(10))
	,	@event
	,	host_name()
	,	@ip
	,	program_name()
	);
END



/*
Audit Testing

create procedure sp_test
as
return
go

select * from Audit_DDL_Events order by PostTime
go

drop procedure sp_test
select * from Audit_DDL_Events order by PostTime
go

*/


/*
Remove audit

drop trigger tr_Audit_DDL 
on database
GO

drop table Audit_DDL_Events
GO

*/