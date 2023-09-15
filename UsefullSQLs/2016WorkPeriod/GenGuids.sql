Create view v_newid as select newid() ID
GO

CREATE FUNCTION GenGuids (
    @Count int
)
RETURNS @result TABLE
(
    [ID] nvarchar(38)
,   [ID_FFFFFFFF_FFFF_FFFF_FFFF_FFFFFFFFFFFF] nvarchar(36)
,   [ID_FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF] nvarchar(34)
)
AS
BEGIN
    insert into @result
    select 
	   '{' + cast(t.[ID] as nvarchar(38)) +'}' ID
    ,   cast(t.[ID] as nvarchar(38)) ID_FFFFFFFF_FFFF_FFFF_FFFF_FFFFFFFFFFFF
    ,   substring(replace(cast(t.[ID] as nvarchar(36)),'-',''),1,36) AS ID_FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    from (
	   select i.ID as [ID]
	   from v_newid i
	   outer apply GenRows(@Count)
    ) t

    return
END
GO