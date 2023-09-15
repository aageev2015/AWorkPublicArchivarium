
declare @ValueFind uniqueidentifier;
declare @ReplaceTo uniqueidentifier;
declare @ValToString_MaxLength int;

set @ValueFind =				'B4FF83DA-3FAB-40F1-B13A-A6E8883125D4';
set @ReplaceTo =				'1A80526A-36B8-47D6-9646-504DA3FF872D';


select 
	'union select '''+o.name + ''' as TableN, ''' + c.name+''' ColumnN, ID as RecordID from [' + o.name + '] where ['+c.name+']=''{'+cast(@ValueFind as nvarchar(38))+'}''' as sql_select
,	'update [' + o.name + '] set ['+c.name+']=''{' + cast(@ReplaceTo as nvarchar(38)) + '}'' where ['+c.name+']=''{'+  cast(@ValueFind as nvarchar(38)) + '}''' sql_update
,	c.type
from sysobjects o
inner join syscolumns c on c.id=o.id
inner join syscolumns c_ID on c_ID.name='ID' and c_ID.id=o.id
where	o.xtype in ('U')
	and c.name not in ('ID')

	and c.type=37
	and c.name not in ('CreatedById', 'ModifiedByID')
	and o.name not in ('')
	and o.name like ('%Right')