select	
',	('''+cast(k1.ID as nvarchar(250))+''', GETDATE(), ''C3198E84-1F8C-45EC-855D-425A9A5D8618'', GETDATE(), ''C3198E84-1F8C-45EC-855D-425A9A5D8618'', '''+k2.Name+''', ''' +k2.[Description]+''')'
from 
( select top 200 newid() as id, ROW_NUMBER() over(ORDER BY id) num from tbl_service) as k1
inner join (
		select *, ROW_NUMBER() over(order by name asc) as num
		from (
					select 'Additional commission' as Name,'Additional commission' as [Description] 
			union 	select 'Birthday' as Name,'Birthday related' as [Description] 
			...
		 ) as k
) as k2 on k2.num=k1.num