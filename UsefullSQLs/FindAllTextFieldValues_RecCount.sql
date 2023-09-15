
select o.name, c.name, ddps.row_count from syscolumns c
inner join sysobjects o on o.id=c.id
left JOIN (select distinct OBJECT_ID, row_count from sys.dm_db_partition_stats ) AS ddps ON o.ID = ddps.OBJECT_ID 
--WHERE 
where 
1=1
and o.Name like 'tbl%'
and not o.name like '%Right'
and not o.name like '%Log'
and c.[type]=39
order by ddps.row_count desc





select 
'union select ''' + o.name + ''' as [Table] , ''' + c.name + ''' as [Column], cast([' + c.name + '] as nvarchar(500)) COLLATE Cyrillic_General_CI_AS as [Value] from [' +o.Name + '] where isnull([' + c.name + '],'''') <> ''''',
o.name, c.name, ddps.row_count from syscolumns c
inner join sysobjects o on o.id=c.id
left JOIN (select distinct OBJECT_ID, row_count from sys.dm_db_partition_stats ) AS ddps ON o.ID = ddps.OBJECT_ID 
--WHERE 
where 
1=1
and o.Name like 'tbl%'
and not o.name like '%Right'
and not o.name like '%Log'
and not o.name like '%Tmp'
and not o.name like '%Temp%'
and c.[type]=39
and not c.name like '%ID'
and ddps.row_count between 1 and 5000
and o.Name not in ('tbl_UserAdminUnit', /*..removed..*/)
order by ddps.row_count desc
