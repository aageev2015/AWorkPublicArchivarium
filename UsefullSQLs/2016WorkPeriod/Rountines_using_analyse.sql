/*
use SqlRegularExpression assembly integration

-- analytical (used as exec in root)
select distinct
    obj_name, use_obj_name
from tmp_routine_using
where use_obj_name like '%LOG%'
and use_tags='exec'
and use_path=obj_name+'\'
order by use_obj_name

-- look simple
select *
,   object_definition(object_id(obj_name)) 
,   object_definition(object_id(use_obj_name)) 
from tmp_routine_using
where use_obj_name like 'history'
--where use_tags like '%exec%'
--where use_tags ='select'

order by obj_name, pos asc

-- look history
select distinct
    s.obj_name stock_obj_name
,   s.use_path stock_use_path
,   h.obj_name history_obj_name
,   h.use_path history_use_path
from tmp_routine_using s
left join (
    select 
	   *
    from tmp_routine_using
    where	  use_obj_name like 'history'
    and	  use_tags in ('insert', 'update', 'delete', 'into')
) h on h.obj_name=s.obj_name
where   s.use_obj_name like 'stock'
    and s.use_tags in ('insert', 'update', 'delete', 'into')

-- look history
select distinct
    s.obj_name stock_obj_name
--,   s.use_path stock_use_path
from tmp_routine_using s
where   s.use_obj_name like 'stock'
    and s.use_tags in ('insert', 'update', 'delete', 'into')

select * from tmp_routine_using
where obj_name='USER_STOCK_SP_CHANGE'
and use_obj_name in ('STOCK', 'history')
-- use_obj_name in ('history')
--and lvl=0


-- find duplicates
with a as (
    select (row_number() over(partition by pos,obj_name, use_path order by id)) num, 
	   *
	, object_definition(object_id(obj_name)) as body from tmp_routine_using
    --where use_tags like '%exec%'
)
select 
    a2.*
from a a1
inner join a a2 on a1.obj_name = a2.obj_name and a2.use_path = a1.use_path and a1.pos=a2.pos
where a1.num>=2
order by  a2.pos,a2.obj_name, a2.use_path, a2.num


select * from tmp_routine_using
where use_path like '%USER_LOG_CONSOLE%'
*/

declare @maxRecurtionLevel int = 7
declare @listDelimiter varchar(5) = '\';
declare @matchOptions int = 1 --case insensitive
declare @skip_obj_name varchar(max) = ';USER_LOG;USER_LOG_CONSOLE;USER_LOG_DATABASE;USER_LOG_DB_LOG;USER_LOG_DEBUG;USER_LOG_ERROR;USER_LOG_WARN;USER_LOG_FATAL;USER_LOG_INFO;'
declare @skipExecs_use_obj_name varchar(max) =	
	   @skip_obj_name
    +   ''

if object_id('tmp_routine_using') is not null 
    drop table tmp_Routine_using

create table tmp_routine_using(
    id int identity(1,1) primary key
,   obj_name varchar(250)  not null	    index ndx_tmp_Routine_obj_name nonclustered
,   pos varchar(max) not null
,   lvl int						    index ndx_tmp_Routine_obj_lvl nonclustered
,   use_obj_name varchar(250) not null	    index ndx_tmp_Routine_obj_use_obj_name nonclustered
,   use_tags varchar(250) not null	    index ndx_tmp_Routine_obj_use_tags nonclustered
,   use_path varchar(max) not null	  --  index ndx_tmp_Routine_obj_use_path nonclustered
,   use_path_pos varchar(max) not null	--    index ndx_tmp_Routine_obj_use_path_pos nonclustered
,   match_full varchar(250)
)




declare @searchMap as table(
    use_tag varchar(250)
,   RegExp varchar(250) --unique
,   getGroupIndex int
,   excludeList varchar(250)
,   Iteration int
)

insert into @searchMap values
    ('insert', '\Winsert\Winto\W1*(dbo\W*)?(\TableName)', 2, '', 1)
,   ('delete', '\Wdelete\Wfrom\W1*(dbo\W*)?(\TableName)', 2, '', 1)
,   ('update', '\Wupdate\W*(dbo\W1*)?(\TableName)', 2, '', 1)
,   ('inner join', '\Winner\s*join\W1*(dbo\W*)?(\TableName)', 2, ';select;', 1)
,   ('left join', '\Wleft\s*join\W1*(dbo\W*)?(\TableName)', 2, ';select;', 1)
,   ('full join', '\Wfull\s*join\W1*(dbo\W*)?(\TableName)', 2, ';select;', 1)
,   ('fetch', '\Wfetch\s*\w*\s*from\W1*(\TableName)\W1*into\W1*(\TableName)', 2, '', 1)
,   ('exec', '\W(execute|exec)[^A-Za-z0-9_@]*(@\w*\W*=\W*)?(dbo\W*)?(\w*)', 4, @skipExecs_use_obj_name, 1)

,   ('select', '\Wselect.*from\W1*(dbo\W*)?(\TableName)', 2, ';select;', 2)
,   ('into', '\Winto\W1*(dbo\W*)?(\TableName)', 2, '', 2)
,   ('inner join', '\Wjoin\W1*(dbo\W1*)?(\TableName)', 2, ';select;', 2)

declare @iteration int 
declare @maxIteration int = (select max(Iteration) from @searchMap);

update @searchMap
set RegExp =	 replace(
			 replace(
				RegExp
			 ,	'\W1', '[^A-Za-z0-9_#@]')
			 --,	'\W1', '\W')
			 ,	'\TableName', '#?@?\w*')

--select * from @searchMap

print 'fill tmp_routine_using roots'

set @iteration = 1
while(1=1)
begin
    insert into tmp_routine_using(
	   obj_name
    ,   pos
    ,   lvl
    ,   use_obj_name
    ,   use_tags
    ,   use_path
    ,   use_path_pos
    ,   match_full   
    )
    select  
	   distinct
	   routine_name
    ,   convert(varchar(200), matches.g_Index) + @listDelimiter
    ,   0
    ,   matches.g_value
    ,   sm.use_tag
    ,   routine_name + @listDelimiter
    ,   routine_name+'('+convert(varchar(200), matches.g_Index)+')' + @listDelimiter
    ,   matches.Value
    from (select	 routine_name
		  ,		 object_definition(object_id(routine_name)) obj_definition
		from INFORMATION_SCHEMA.ROUTINES
		where @skip_obj_name not like '%;' + routine_name + ';%'
	    ) r
    cross join (select * from @searchMap where Iteration=@iteration) sm
    cross apply RegExpMatchesGroups(r.obj_definition, 
	   sm.RegExp, @matchOptions
    ) matches
    --inner join sysobjects obj on obj.name=matches.g_value	-- bad idea
    left join tmp_routine_using existed on 
				existed.obj_name = routine_name
		  and	existed.pos = convert(varchar(200), matches.g_Index) + @listDelimiter
		  and	existed.use_obj_name = matches.g_value
    where   object_definition(object_id(routine_name)) is not null
    and	  matches.g_num=sm.getGroupIndex
    and	  sm.excludeList not like '%;' + matches.g_value+';%'
    and	  existed.id is null
    and	  isnull(matches.g_value,'') <> ''
    if (@iteration >= @maxIteration )
	   break;
    set @iteration = @iteration + 1;
end

declare @rows int;
set @iteration = 1;

print 'fill tmp_routine_using childs'

while(1=1)
begin
    insert into tmp_routine_using(
	   lvl
    ,   obj_name
    ,   pos
    ,   use_obj_name
    ,   use_tags
    ,   use_path
    ,   use_path_pos
    ,   match_full
    )
    select
	   @iteration
    ,   *
    from (
	   select
		  distinct
		  parent.obj_name as obj_name
	   ,   parent.pos + child.pos as pos
	   ,   child.use_obj_name as use_obj_name
	   ,   child.use_tags as use_tags
	   ,   parent.use_path + child.use_path as  use_path
	   ,   parent.use_path_pos + child.use_path_pos as use_path_pos
	   ,   child.match_full as match_full
	   from tmp_routine_using parent
	   inner join tmp_routine_using child on parent.use_obj_name = child.obj_name
	   left join tmp_routine_using existed on  existed.obj_name = parent.obj_name
								and	    existed.pos = parent.pos + child.pos
								and	    existed.use_obj_name = child.use_obj_name
								and	    existed.use_tags = child.use_tags
								and	    existed.use_path = parent.use_path + child.use_path
	   where	  parent.use_tags in ('exec')
		  and existed.id is null
		  and parent.obj_name<>parent.use_obj_name
    ) t
    set @rows = @@ROWCOUNT;
    print 'Recurtion Level: ' +convert(varchar(50), @iteration)
    print 'RowCount: ' + convert(varchar(50), @rows)
    
    if (@rows = 0) or @iteration>=@maxRecurtionLevel
	   break
    set @iteration = @iteration + 1
	   
end


select *
,   object_definition(object_id(obj_name)) 
,   object_definition(object_id(use_obj_name)) 
from tmp_routine_using
--where use_tags like '%exec%'
order by obj_name, pos asc