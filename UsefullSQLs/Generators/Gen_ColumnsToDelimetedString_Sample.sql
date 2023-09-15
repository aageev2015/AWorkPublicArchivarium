with cols(id, TableName, colid, ColumnList)
as 
(
	select o.id, o.name as TableName, c.colid, 
		cast(
			c.Name 
		as nvarchar(max)) as ColumnList 
	from sysobjects o
	inner join syscolumns c on c.id=o.id
	where c.colid=1
	and
	o.name in (
		'tbl_xcl_Account',
		'tbl_xcl_Booking',
		'tbl_xcl_Booking_In_OrderCalc',
		)
	UNION ALL
	select	o.id, o.TableName as TableName, c.colid, 
			cast((
					o.ColumnList + ', ' + c.name
			) as nvarchar(max)) as ColumnList 
	from cols o
	inner join syscolumns c on c.id=o.id
	where c.colid=o.colid+1
),
maxCols(ID, maxColID)
as (
	select id, max(colid) from cols
	group by id
)
select * from cols c
inner join maxCols as mc on mc.id=c.id and mc.maxColID=c.colid
order by TAbleName, colID