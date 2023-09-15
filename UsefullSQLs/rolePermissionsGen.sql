--create role CrmReadonlyRole
--exec sp_addrolemember CrmReadonlyRole , Crm4appsReadOnly

set nocount on


declare @fullDataTemplate nvarchar(max) = 'GRANT INSERT, SELECT , UPDATE ON [%1].[%2] TO CrmReadonlyRole'
declare @readonlyDataTemplate nvarchar(max) = 'GRANT SELECT ON [%1].[%2] TO CrmReadonlyRole'
declare @fullRoutineTemplate nvarchar(max) = 'GRANT EXECUTE ON [%1].[%2] TO CrmReadonlyRole'
declare @readonlyRoutineTemplate nvarchar(max) = 'DENY EXECUTE ON [%1].[%2] TO CrmReadonlyRole'
declare @fullFunctionTemplate nvarchar(max) = 'GRANT EXECUTE ON [%1].[%2] TO CrmReadonlyRole'
declare @fullTableFunctionTemplate nvarchar(max) = 'GRANT SELECT ON [%1].[%2] TO CrmReadonlyRole'
declare @fullAccessObjects table (fa_table_name nvarchar(250))

insert into @fullAccessObjects values
	-- tables
	('dbo.USERS'), ('dbo.USER_PERMISSION'), ('dbo.USER_ALLOWED_AREAS'), ('dbo.AREA_TO_USERS'), 
	('dbo.LOG'), ('dbo.CACHE_INFO'), ('dbo.PROFILE'), ('dbo.SP_START_LOG'), ('dbo.SP_STOP_LOG'), 
	-- routines
	('dbo.GET_TRANSACTION_ID'), ('dbo.ITEM_FIND_NEW_ITEM'), ('dbo.LOCATION_FIND_NEW_LOCATION'), 
insert into @fullAccessObjects select TABLE_SCHEMA + '.' + TABLE_NAME from INFORMATION_SCHEMA.TABLES where table_name like 'LOG_OF%'

print 'Next is full access tables'

select * from @fullAccessObjects order by 1

print 'exec next script'
select 
replace(replace(
	IIF(fullAccess.fa_table_name is null, @readonlyDataTemplate, @fullDataTemplate)
	,'%1', TABLE_SCHEMA)
	,'%2', TABLE_NAME)
from INFORMATION_SCHEMA.TABLES t
left join @fullAccessObjects fullAccess on fullAccess.fa_table_name = TABLE_SCHEMA + '.' + TABLE_NAME
order by IIF(fullAccess.fa_table_name is null, @readonlyDataTemplate, @fullDataTemplate), TABLE_SCHEMA, table_name


-- imlementation below not universal for functions
-- select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_TYPE='FUNCTION'

select 
replace(replace(
	iif(DATA_TYPE='TABLE', @fullTableFunctionTemplate, @fullFunctionTemplate)
	,'%1', ROUTINE_SCHEMA)
	,'%2', ROUTINE_NAME)
from  INFORMATION_SCHEMA.ROUTINES t
where t.ROUTINE_TYPE='FUNCTION'
order by 1 desc, ROUTINE_SCHEMA, ROUTINE_NAME

select 
replace(replace(
	IIF(	fullAccess.fa_table_name is null
	, @readonlyRoutineTemplate, @fullRoutineTemplate)
	,'%1', ROUTINE_SCHEMA)
	,'%2', ROUTINE_NAME)
from  INFORMATION_SCHEMA.ROUTINES t
left join @fullAccessObjects fullAccess on fullAccess.fa_table_name = ROUTINE_SCHEMA + '.' + ROUTINE_NAME
where t.ROUTINE_TYPE='PROCEDURE'
order by 1 desc, ROUTINE_SCHEMA, ROUTINE_NAME

