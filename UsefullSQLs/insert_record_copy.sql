declare @ids table(id int)
insert into STORAGE (
	AREA_ID, ITEM_ID, LOCATION_ID, ...
)
output INSERTED.ID into @ids
select
	AREA_ID, ITEM_ID, LOCATION_ID, ...
from	STORAGE 
where	ID = 29292

select * from @ids