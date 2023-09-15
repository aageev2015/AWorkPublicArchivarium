declare @Result nvarchar(4000)
set @Result = N''
select @Result = @Result + name + ', '
from(
select top 10 name from tbl_account) q
print @result


