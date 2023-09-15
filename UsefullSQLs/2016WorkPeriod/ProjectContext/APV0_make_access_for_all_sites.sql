insert into AREA_TO_USERS(USERS_ID,AREA_ID)
select u.id, ss.id from AREA ss
inner join Users u on u.name in ('sa')
where not exists(select * from AREA_TO_USERS s where s.USERS_ID = u.id and s.AREA_ID = ss.ID)


/*
-- make automatic for sa

create trigger TR_AREA_ADD_AREA_TO_USER on dbo.[AREA] after insert
as
begin
	insert into AREA_TO_USERS (users_id, AREA_id)
	select u.id, ss.id from inserted ss
	inner join Users u on u.name in ('sa')
	where not exists(select * from AREA_TO_USERS s where s.USERS_ID = u.id and s.AREA_ID = ss.ID)
end

*/