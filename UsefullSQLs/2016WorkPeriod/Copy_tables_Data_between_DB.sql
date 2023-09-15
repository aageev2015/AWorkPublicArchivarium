declare @TableName nvarchar(100) = 'ITEM'
declare @SourceDatabase nvarchar(100) = 'AwesomeSystemV0_44_Prod'
declare @TargetDatabase nvarchar(100) = 'AwesomeSystemV0_4409_Base'

declare @Fieldlist nvarchar(max) = ''
select 
    @Fieldlist=@Fieldlist+','+Column_Name
from AwesomeSystemV0_3609_UPS_EE_Base.INFORMATION_SCHEMA.COLUMNS
where Table_Name=@TableName
-- exclude field lists
and Column_Name not in ('TS', 'USER_ID')
set @Fieldlist = substring(@Fieldlist, 2, len(@Fieldlist))
print @Fieldlist

declare @sql nvarchar(max)= '
set identity_insert %TargetDB%..%TableName% on 
insert into %TargetDB%..%TableName%
(
    %FieldList%
)
select 
    %FieldList%
from %SourceDB%..%TableName%
set identity_insert %TargetDB%..%TableName% off
'

set @sql=	  replace(
		  replace(
		  replace(
		  replace(
		  @sql
		  , '%TargetDB%', @TargetDatabase)
		  , '%SourceDB%', @SourceDatabase)
		  , '%TableName%', @TableName)
		  , '%FieldList%', @Fieldlist)
print @sql
exec (@sql)
