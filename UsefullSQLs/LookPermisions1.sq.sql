begin tran

--select t2.name,t3.name,t1.* from sysprotects t1,sysusers t2,sysobjects t3
--where t1.uid=t2.uid
--and t3.id=t1.id


select t1.name,
	u1.name,
	p1.uid,
	case p1.action 
		when 193 then '_CR'
		when 195 then '_CI'
		when 196 then '_CD'
		when 197 then '_CU'
	end
from sysobjects t1
left join sysprotects p1 on (
	p1.id=t1.id
	and p1.action <> 26
)
left join sysusers u1 on (
	u1.uid=p1.uid
	and (((right(u1.name,3)='_CR') and  (p1.action=193)) or
		((right(u1.name,3)='_CI') and  (p1.action=195)) or
		((right(u1.name,3)='_CD') and  (p1.action=196)) or
		((right(u1.name,3)='_CU') and  (p1.action=197))
		)
)
where objectproperty(t1.id,'IsView')=1
and right(t1.name,5)<>'Right'
--and u1.name is null
rollback