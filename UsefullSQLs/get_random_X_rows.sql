select *
from item i
order by id 
offset abs(convert(int, convert(varbinary(4), newid(), 0)) % (select count(*) from item)) rows
fetch first 1 rows only