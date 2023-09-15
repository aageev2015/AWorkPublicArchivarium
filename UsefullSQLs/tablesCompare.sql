select q.name, 
(select count(*) from syscolumns sc where sc.id = 
object_id('tbl_Account') and sc.name = q.name) as Account, 
(select count(*) from syscolumns sc where sc.id = 
object_id('tbl_Contact') and sc.name = q.name) as Contact
from (select name 
from syscolumns where id in (
object_id('tbl_Account'), object_id('tbl_Contact')
)) q order by 2, 3