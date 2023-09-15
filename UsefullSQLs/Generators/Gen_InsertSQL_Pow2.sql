set nocount on
declare @TableName nvarchar(250) = 'SysSettingsValue'
declare @ExcludedFields nvarchar(500) = ';CreatedByID;ModifiedByID;';
declare @where nvarchar(max) = null


declare @Q1 nvarchar(10) = replicate('''', 1);
declare @Q2 nvarchar(10) = replicate(@Q1, 2);
declare @Q3 nvarchar(10) = replicate(@Q1, 3);
declare @Q4 nvarchar(10) = replicate(@Q1, 4);
declare @Q5 nvarchar(10) = replicate(@Q1, 5);
declare @Q6 nvarchar(10) = replicate(@Q1, 6);

declare @tColList nvarchar(max) = ''
declare @tValList nvarchar(max) = ''
declare @tSQL nvarchar(max) = ''

/*
select
COLUMN_NAME,*
from INFORMATION_SCHEMA.COLUMNS
where  TABLE_NAME = @TableName
and @ExcludedFields not like ('%;' + COLUMN_NAME + ';%')
order by ordinal_position asc
*/

select
@tColList=@tColList + (case when @tColList='' then '' else ',' end) + '[' + COLUMN_NAME + ']'
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = @TableName
and @ExcludedFields not like ('%;' + COLUMN_NAME + ';%')
order by ordinal_position asc

print @tColList
/*
print '
@tColList'
print @tColList
*/


select
@tValList=@tValList + (case when @tValList='' then replicate(' ',9) else '
+ '+@Q1+', '+@Q1+' + ' end) + 
	'isnull(' + ( 
		case 
		when Data_type in ('uniqueidentifier', 'datetime', 'time', 'smalldatetime','datetime2' ) 
			then (@Q4 + ' + cast([' + COLUMN_NAME + '] as nvarchar(' + isnull(cast(Character_Maximum_length as nvarchar(20)), 100) + ')) + ' + @Q4)
		when Data_type in ('nvarchar', 'varchar', 'nchar' )
			then (@Q4 + ' + replace([' + COLUMN_NAME + '],' + @Q4 + ',' + @Q6 +') + ' + @Q4)
		else ('cast([' + COLUMN_NAME + '] as nvarchar(' + IIF(Character_Maximum_length = -1, 'max', isnull(cast(Character_Maximum_length as nvarchar(20)), 100)) + '))')
		 end )+
	', ' + @Q1+'null'+@Q1+')'
	
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = @TableName
and @ExcludedFields not like ('%;[' + COLUMN_NAME + '];%')
order by ordinal_position asc



print '
@tValList'
print @tValList



set @tSQL = 'select 
''insert into [' + @TableName + '](' + @tColList + ')
values(' + @Q1 + '+
' +@tValList+'
+' + @Q1 + ')
GO
''
from ' + @TableName + isnull('
where ' + @where, '')


print '
@tSQL'
print @tSQL


exec (@tSQL)