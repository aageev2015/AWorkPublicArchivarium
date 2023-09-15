exec sp_configure 'allow updates', 1

reconfigure with override

GO

 

update sysusers 

set name = upper(name)

where name = 'tg_Account'

GO

 

exec sp_configure 'allow updates', 0

reconfigure with override

GO
