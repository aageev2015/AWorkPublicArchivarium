if object_id('tbl_EVENT_SESSION_log') is not null
	drop table tbl_EVENT_SESSION_log
go 
create table tbl_EVENT_SESSION_log (
	id int IDENTITY(1,1) not null
,		CONSTRAINT PKtbl_EVENT_SESSION_log_id PRIMARY KEY NONCLUSTERED (id)
,	[XEvent] xml
,	writes varchar(50)
,	event_name varchar(50)
,	[timestamp] datetime not null
,	session_id int
,	event_sequence	int not null
,	transaction_id	int 
,	transaction_sequence bigint
,	username	varchar(250)
,	client_app_name	varchar(250)
,	client_hostname	varchar(250)
,	client_pid int
,	[statement] nvarchar(max)
,	[context_info] nvarchar(250)
,	database_id int 
,	database_name varchar(250)
,	[object_name] varchar(250)
,	attach_activity_id varchar(50)
,	process_id int
,	session_nt_username varchar(250)
)
go
create nonclustered index Itbl_EVENT_SESSION_log_transaction_id on tbl_EVENT_SESSION_log (transaction_id)
go
create nonclustered index Itbl_EVENT_SESSION_log_object_name on tbl_EVENT_SESSION_log ([object_name])
go
create nonclustered index Itbl_EVENT_SESSION_log_statement on tbl_EVENT_SESSION_log ([timestamp])
go
create nonclustered index Itbl_EVENT_SESSION_log_event_sequence on tbl_EVENT_SESSION_log ([event_sequence])
go
create clustered index Itbl_EVENT_SESSION_log_event_clustered on tbl_EVENT_SESSION_log ([timestamp], [event_sequence])
go
create nonclustered index Itbl_EVENT_SESSION_log_event_name on tbl_EVENT_SESSION_log ([event_name])
go
/*
if exists(select top 1 1 from sys.fulltext_catalogs where name='Ctbl_EVENT_SESSION_log_statement')
	drop fulltext catalog Ctbl_EVENT_SESSION_log_statement
go
CREATE FULLTEXT CATALOG Ctbl_EVENT_SESSION_log_statement WITH ACCENT_SENSITIVITY = OFF
go
CREATE FULLTEXT INDEX ON tbl_EVENT_SESSION_log ([statement])
KEY INDEX PKtbl_EVENT_SESSION_log_id ON Ctbl_EVENT_SESSION_log_statement
WITH STOPLIST = SYSTEM
go
*/
