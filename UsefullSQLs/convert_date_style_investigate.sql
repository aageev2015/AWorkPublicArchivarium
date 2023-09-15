

declare @val int = 1
declare @vals nvarchar(250)

declare @source datetime = getdate();

declare @result table (num int, nums nvarchar(250))

while(1=1) 
begin
	
	if (@val >= 500) break;
	
	begin try
		set @vals = convert(nvarchar(250), @source, @val);
		insert into @result values(@val, @vals)
	end try
	begin catch
		insert into @result values(@val, null)
	end catch
	set @val = @val + 1
end

select * from @result
where nums is not null
order by num asc