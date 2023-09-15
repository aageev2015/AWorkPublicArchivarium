select transactionName, area_id, s.code area_code, h.* from history h
inner join area s on s.id=h.area_ID
left join (values
	('All',0),('ChangeFrom',1),('ChangeTo',2),-- ... removed
) transactionCodes(transactionName, transactionCode) on transactionCodes.transactionCode=h.CODE
where SerialNumber='12323344546' and item = (select code from item where id=19191)
order by h.id asc

