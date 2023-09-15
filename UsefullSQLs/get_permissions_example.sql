
select
*
from 
(
select 
    class_desc 
    ,USER_NAME(grantee_principal_id) as user_or_role
    ,CASE WHEN class = 0 THEN DB_NAME()
          WHEN class = 1 THEN ISNULL(SCHEMA_NAME(o.uid)+'.','')+OBJECT_NAME(major_id)
          WHEN class = 3 THEN SCHEMA_NAME(major_id) END [Securable]
    ,permission_name
    ,state_desc
    ,'revoke ' + permission_name + ' on ' +
        isnull(schema_name(o.uid)+'.','')+OBJECT_NAME(major_id)+ ' from [' +
        USER_NAME(grantee_principal_id) + ']' as 'revokeStatement'
    ,'grant ' + permission_name + ' on ' +
        isnull(schema_name(o.uid)+'.','')+OBJECT_NAME(major_id)+ ' to ' +
        USER_NAME(grantee_principal_id) + ']' as 'grantStatement'
FROM sys.database_permissions dp
LEFT OUTER JOIN sysobjects o
    ON o.id = dp.major_id
-- where major_id >= 1  -- ignore sysobjects
) s
where s.Securable like 'dbo.tbl_xcl%'
and s.Securable  not in ('dbo.tbl_xcl_Booking', 'dbo.tbl_xcl_BookingInGroup')
order by Securable, user_or_role


/*
select 
	--'grant DELETE on dbo.' + name + ' to TG_INERNETDATA_CD' 
	--'grant INSERT on dbo.' + name + ' to TG_INERNETDATA_CI'
	--'grant SELECT on dbo.' + name + ' to TG_INERNETDATA_CR'
	--'grant Update on dbo.' + name + ' to TG_INERNETDATA_CU'
	'grant SELECT on dbo.' + name + ' to [Все пользователи]'
from sysobjects
where name like 'tbl_xcl%'
and name not like  ('tbl_xcl_Booking%')

*/