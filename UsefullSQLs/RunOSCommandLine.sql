--Not whure why tsmergeservices not works correctly
declare @UserSelectQuery varchar(4000)
declare @PreFix varchar(20)
declare @PostFix varchar(100)
declare @Divider varchar(100)
declare @commandline varchar(4000)

set @Divider=';'
set @PreFix=''
set @PostFix=''
set @UserSelectQuery='
select t1.code
from tbl_service t1
left join mycrm311x15r..tbl_service t2 on (
	t1.code=t2.code
	or t1.id=t2.id
)
where t2.id is not null
and t1.path like ''common\library%''
group by t1.code
order by t1.code'

set @commandline='q:\tsmergeservices /cfg="mycrm311X15(local)" /usr="Supervisor" /opr=Extract /fmt=true /js=true /code="%CommandLine"'



declare @sql varchar(4000)

set @sql='
Declare curs cursor for '+@UserSelectQuery+'
declare @gg varchar(250)
declare @line varchar(8000)
declare @ItemsCount int
set @ItemsCount=0
set @line=''''
open curs

while 1=1
begin
	FETCH NEXT FROM curs into @gg
	if @@FETCH_STATUS = -1 break;
	if @@FETCH_STATUS = -2 continue;
	if @line<>''''
		set @line=@line+'''+@Divider+'''
	set @line=@line+'''+@PreFix+'''+@gg+'''+@PostFix+'''
	set @ItemsCount=@ItemsCount+1
end
print @line
print ''ItemsCount	''+ cast(@ItemsCount as varchar(15))
print ''CharsCount	''+ cast(len(@line) as varchar(15))
print ''------------------------------------Executing commandline--------------------------''
declare @TheCommandLine varchar(4000)
set @TheCommandLine = replace('''+@commandline+''',''%CommandLine'',@line)
print @TheCommandLine
--exec master..xp_cmdshell @TheCommandLine
print ''------------------------------------Finish--------------------------''

close curs
deallocate curs'
exec (@sql)


--exec master..xp_cmdshell 'ping i.ua'