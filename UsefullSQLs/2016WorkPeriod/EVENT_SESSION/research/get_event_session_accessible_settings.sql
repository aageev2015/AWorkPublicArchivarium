
SELECT 
 pkg.guid, pkg.module_guid, pkg.name, pkg.description, mod.*
FROM sys.dm_os_loaded_modules mod
INNER JOIN sys.dm_xe_packages pkg
ON mod.base_address = pkg.module_address 

select pkg.name, c.* from sys.dm_xe_object_columns c
inner join sys.dm_xe_packages pkg on pkg.guid=c.object_package_guid
where c.name='log_record_size'
order by pkg.name, c.name


SELECT pkg.name, v.*
FROM sys.dm_xe_map_values v
inner join sys.dm_xe_packages pkg on pkg.guid=v.object_package_guid
--where v.name='rpc_completed'
order by pkg.name

--WHERE name = 'keyword_map' 

select pkg.name as PackageName, obj.*
from sys.dm_xe_packages pkg
inner join sys.dm_xe_objects obj on pkg.guid = obj.package_guid
--where obj.object_type = 'event'
--where obj.object_type = 'action'
--where obj.object_type = 'target'
where obj.object_type = 'pred_source' 
--where  obj.name='rpc_completed'
order by 1, 2 


SELECT sessions.name AS SessionName, sevents.package as PackageName,
sevents.name AS EventName,
sevents.predicate, sactions.name AS ActionName, stargets.name AS TargetName
FROM sys.server_event_sessions sessions
INNER JOIN sys.server_event_session_events sevents
ON sessions.event_session_id = sevents.event_session_id
INNER JOIN sys.server_event_session_actions sactions
ON sessions.event_session_id = sactions.event_session_id
INNER JOIN sys.server_event_session_targets stargets
ON sessions.event_session_id = stargets.event_session_id
WHERE sessions.name = ''
GO 

