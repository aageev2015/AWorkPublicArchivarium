CREATE FUNCTION GenRows (
    @Count int
,   @Start int = 1
)
RETURNS @result TABLE(
    [Number] int
)
AS
BEGIN

	declare @I int = @Start;
	while @I<=@Count 
	begin
		insert into @result values(@I)
		set @I=@I+1;
	end
    return;
END