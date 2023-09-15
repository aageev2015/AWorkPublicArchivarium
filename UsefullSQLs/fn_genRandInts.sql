-- 1. int version. maximum interval size = 2147483646
declare @qty int = 10000
declare @minValue int = -5;					-- inclusive
declare @maxValue int = @minValue + 10;		-- inclusive
declare @interval int = @maxValue - @minValue + 1;
select @minValue + abs(convert(bigint, convert(varbinary(4), newid())) % @interval) number
from fn_GenRows(@qty)

-- 2. bigint version. maximum interval size = 9223372036854775806
declare @qty bigint = 1000;
declare @minValue bigint = -5;				-- inclusive
declare @maxValue bigint = @minValue + 5;	-- inclusive
declare @interval bigint = @maxValue - @minValue + 1;

select 
	@minValue + abs(convert(bigint, convert(varbinary(8), newid())) % @interval) number
from fn_GenRows(@qty)

-- 3. numberic version failed by numeric overflow exception

-- 4. rand(seed) version failed. Generates non random values
-- seed calculation method:
--	declare @baseSeed int = rand(convert(int, convert(bigint, convert(float, getdate())*86400000) & 2147483647));

-- 5 wrap rand or newid by function failed. Exeption "Invalid use of a side-effecting operator 'newid' within a function"


create function tmp_fn_RandIntByGuid(@id uniqueidentifier, @minVal int, @interval int)
returns int
begin
	return @minVal + abs(convert(bigint, convert(varbinary(8), @id)) % @interval)
end
go
