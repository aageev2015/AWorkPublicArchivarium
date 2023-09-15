select 	t1.Code TableCode,t1.Caption TableCaption,
	t2.Code SelectCode,t2.Caption SelectCaption,
	t3.Code DatasetCode,t3.Caption DatasetCaption
from tbl_service t1
left join tbl_service t2 on (
	t2.code = replace(t1.Code,'tbl_','sq_')
)
left join tbl_service t3 on (
	t3.code = replace(t1.Code,'tbl_','ds_')
)
where t1.servicetypecode ='Table'
union
select 	t1.Code TableCode,t1.Caption TableCaption,
	t2.Code SelectCode,t2.Caption SelectCaption,
	t3.Code DatasetCode,t3.Caption DatasetCaption
from tbl_service t2
left join tbl_service t1 on (
	t1.code = replace(t2.Code,'sq_','tbl_')
)
left join tbl_service t3 on (
	t3.code = replace(t2.Code,'sq_','ds_')
)
where t2.servicetypecode ='SelectQuery'
union
select 	t1.Code TableCode,t1.Caption TableCaption,
	t2.Code SelectCode,t2.Caption SelectCaption,
	t3.Code DatasetCode,t3.Caption DatasetCaption
from tbl_service t3
left join tbl_service t2 on (
	t2.code = replace(t3.Code,'ds_','sq_')
)
left join tbl_service t1 on (
	t1.code = replace(t3.Code,'ds_','tbl_')
)
where t3.servicetypecode ='DBDataset'
group by t1.Code ,t1.Caption ,
	t2.Code ,t2.Caption ,
	t3.Code ,t3.Caption 
order by t3.Caption,t1.Caption desc,t2.Caption desc
