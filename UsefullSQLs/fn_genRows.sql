if object_id('fn_GenRows') is not null drop function dbo.fn_GenRows
go 

-- tests:
-- select * from fn_GenRows(1000000) -- 18 sec with no batch
-- select * from fn_GenRows(1000000) -- 9 sec with batch by 10
-- select * from fn_GenRows(1000000) -- 8 sec with batch by 100

create function dbo.fn_GenRows(@cnt int)
returns @result table(
	number int
)
as
begin
	declare @i int = 0;
	declare @inBatchCount int = 100;


	while(@i < @cnt - @inBatchCount)
	begin
		insert into @result values 
		 (@i), (@i+1), (@i+2), (@i+3), (@i+4), (@i+5), (@i+6), (@i+7), (@i+8), (@i+9)
		,(@i+10), (@i+11), (@i+12), (@i+13), (@i+14), (@i+15), (@i+16), (@i+17), (@i+18), (@i+19)
		,(@i+20), (@i+21), (@i+22), (@i+23), (@i+24), (@i+25), (@i+26), (@i+27), (@i+28), (@i+29)
		,(@i+30), (@i+31), (@i+32), (@i+33), (@i+34), (@i+35), (@i+36), (@i+37), (@i+38), (@i+39)
		,(@i+40), (@i+41), (@i+42), (@i+43), (@i+44), (@i+45), (@i+46), (@i+47), (@i+48), (@i+49)
		,(@i+50), (@i+51), (@i+52), (@i+53), (@i+54), (@i+55), (@i+56), (@i+57), (@i+58), (@i+59)
		,(@i+60), (@i+61), (@i+62), (@i+63), (@i+64), (@i+65), (@i+66), (@i+67), (@i+68), (@i+69)
		,(@i+70), (@i+71), (@i+72), (@i+73), (@i+74), (@i+75), (@i+76), (@i+77), (@i+78), (@i+79)
		,(@i+80), (@i+81), (@i+82), (@i+83), (@i+84), (@i+85), (@i+86), (@i+87), (@i+88), (@i+89)
		,(@i+90), (@i+91), (@i+92), (@i+93), (@i+94), (@i+95), (@i+96), (@i+97), (@i+98), (@i+99)
		set @i = @i + @inBatchCount;
	end

	while(@i < @cnt)
	begin
		-- TODO: fix using insert select top @cnt-@i
		insert into @result values (@i);
		set @i=@i+1;
	end

	return;
end
