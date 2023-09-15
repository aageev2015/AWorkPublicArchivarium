select 'dbo.PALLET', count(*) from [dbo].[PALLET] with(nolock) having count(*)>0 
union select 'dbo.__MigrationHistory', count(*) from [dbo].[__MigrationHistory] with(nolock) having count(*)>0 
union select 'dbo.PARTNER', count(*) from [dbo].[PARTNER] with(nolock) having count(*)>0 
union select 'dbo.PROFILE', count(*) from [dbo].[PROFILE] with(nolock) having count(*)>0 
.... removed unions ....
order by 1 desc