/*
delete from User_Permission where User_Id=748 and perm_id not in (51,52,53,54,55,56, 37)

insert into User_Permission(User_Id,Perm_ID) select User_Id,Perm_ID from User_Permission_bak where user_id=748 and perm_id not in (51,52,53,54,55,56, 37)
*/
declare  
  @ViewServiceTicket int = 51,
  @ModifyServiceTicket int = 52,
  @ManageService int = 53,
  @AtHomeService int = 54,
  @Domain1Research int = 55,
  @Domain1QA int = 56



/*
insert into USER_PERMISSION (user_id, perm_id) 
 select 138, perm from (values (22), (54), (45), (53)
) t(perm)
*/

/*
delete from USER_PERMISSION where user_id=748
and PERM_ID in ( (@ManageService), (@AtHomeService), (@Domain1Research), (@Domain1QA))
*/

/*
delete from USER_PERMISSION where ID in (52312)
*/

/*
 insert into USER_PERMISSION (user_id, perm_id) 
 select 148, perm from (values 
		--(@ManageService), (@AtHomeService), (@Domain1Research), (@Domain1QA)
		(@AtHomeService), (@Domain1Research)
) t(perm)

declare @user_id int = 148
insert into USER_PERMISSION(User_id, perm_id)
select @user_id, id from (values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27),-- removed
) perms(id)
where not exists(select * from USER_PERMISSION where user_id = @user_id and perm_id = perms.id)



*/



select * from USER_PERMISSION where User_Id=148 and Perm_id in (
	@ViewServiceTicket, @ModifyServiceTicket, @ManageService, @AtHomeService, @Domain1Research, @Domain1QA
)
order by PERM_ID
