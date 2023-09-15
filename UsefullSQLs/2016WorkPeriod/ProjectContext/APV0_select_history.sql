select
	tran_code.code,	h.*
from history h
left join (values
	('All',0), ---..removed..
) tran_code(code, id) on tran_code.id = h.CODE
order by h.id desc