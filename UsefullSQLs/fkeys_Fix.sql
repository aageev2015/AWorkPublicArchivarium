changeUserLogin

Syntax
sp_change_users_login [ @Action = ] 'action' 
    [ , [ @UserNamePattern = ] 'user' ] 
    [ , [ @LoginName = ] 'login' ]

Arguments
[@Action =] 'action'

Describes the action to be performed by the procedure. action is varchar(10), and can be one of these values.

Value Description 
Auto_Fix 
Links user entries in the sysusers table in the current database to logins of the same name in syslogins. It is recommended that the result from the Auto_Fix statement be checked to confirm that the links made are the intended outcome. Avoid using Auto_Fix in security-sensitive situations. Auto_Fix makes best estimates on links, possibly allowing a user more access permissions than intended. 
user must be a valid user in the current database, and login must be NULL, a zero-length string (''), or not specified.
 
Report 
Lists the users, and their corresponding security identifiers (SID), that are in the current database, not linked to any login. 
user and login must be NULL, a zero-length string (''), or not specified.
 
Update_One

sp_change_users_login 'fkeys', 'fkeys', Update_One

mssql2005
exec sp_change_users_login 'UPDATE_ONE', 'fkeys', 'fkeys'