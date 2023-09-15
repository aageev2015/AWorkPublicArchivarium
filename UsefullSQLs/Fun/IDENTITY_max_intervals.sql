

select
	iif(kind='start-end', 1, lead_id-id + 1) leng, id
from (
	select iif (lag_diff>1 and lead_diff>1, 'start-end', iif(lag_diff>1, 'start', 'end')) kind,
		lead(id) over(order by (id)) lead_id,
		*
	from (
		select id - isnull(lag(id) over(order by id), -1) lag_diff, isnull(lead(id) over(order by id), POWER(2.,31)-1) - id lead_diff, id from item
	) t
	where lag_diff>1 or lead_diff>1
) t
where kind in ('start-end', 'start')
order by leng desc

