set nocount on

-- copy settings
declare @TableNames table (
	Name nvarchar(250)
)
declare @CopyPostfix nvarchar(250) = '_19_01_2015'
declare @CopyDatabaseName  nvarchar(250) = DB_NAME() + @CopyPostfix;

/*
select ',	(''' + Name +''')' + char(13)+char(10) from sysobjects
where name like 'tbl_xcl%'
*/

insert into @TableNames values
  ('tbl_xcl_Account')  
, ('tbl_xcl_AccountBillingInfo')  
, ('tbl_xcl_AccountCommunication')  




-- generator settings
DECLARE @CRLF NCHAR(2)
SET @CRLF = Nchar(13) + NChar(10)
DECLARE @PLACEHOLDER NCHAR(3)
SET @PLACEHOLDER = '{:}'

-- the main query
select '
SET NOCOUNT OFF
--------------------------
-- create Copy database
--------------------------
create database ' + QuoteName(@CopyDatabaseName) +'
GO
'
union all
select '
--------------------------
-- Drop tables
--------------------------
'
union all
select 
'
print ''''
print ''drop table ' +  QuoteName(@CopyDatabaseName) + '.' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix) + '''
drop table ' + QuoteName(@CopyDatabaseName) + '.' +  QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix) +'
GO
'
 from sysobjects so
LEFT JOIN information_schema.tables t on  
    t.Table_name = so.Name
WHERE
    xtype = 'U'
    AND name NOT IN ('dtproperties')
     AND so.name in (select name from @TableNames)
     
union all
select
'
--------------------------
-- Generate backup tables
--------------------------
'
SELECT 
    REPLACE(
        'print ''creating ' +  QuoteName(@CopyDatabaseName) + '.' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix) + '''
         create table ' + QuoteName(@CopyDatabaseName) + '.' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix)  + ' (' + @CRLF 
        + LEFT(o.List, Len(o.List) - (LEN(@PLACEHOLDER)+2)) + @CRLF + ');' + @CRLF
        + CASE WHEN tc.Constraint_Name IS NULL THEN '' 
          ELSE
            'ALTER TABLE ' + QuoteName(@CopyDatabaseName) + '.' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.Name + @CopyPostfix) 
            + ' ADD CONSTRAINT ' + tc.Constraint_Name + @CopyPostfix + ' PRIMARY KEY (' + LEFT(j.List, Len(j.List) - 1) + ');' + @CRLF
          END
         + @CRLF + 'GO' + @CRLF,
        @PLACEHOLDER,
        @CRLF
    )
FROM sysobjects so

CROSS APPLY (
    SELECT 
          '   '
          + '['+column_name+'] ' 
          +  data_type 
          + case data_type
                when 'sql_variant' then ''
                when 'text' then ''
                when 'ntext' then ''
                when 'decimal' then '(' + cast(numeric_precision as varchar) + ', ' + cast(numeric_scale as varchar) + ')'
              else 
              coalesce(
                '('+ case when character_maximum_length = -1 
                    then 'MAX' 
                    else cast(character_maximum_length as varchar) end 
                + ')','') 
            end 
        + ' ' 
        + case when exists ( 
            SELECT id 
            FROM syscolumns
            WHERE 
                object_name(id) = so.name
                and name = column_name
                and columnproperty(id,name,'IsIdentity') = 1 
          ) then
            'IDENTITY(' + 
            cast(ident_seed(so.name) as varchar) + ',' + 
            cast(ident_incr(so.name) as varchar) + ')'
          else ''
          end 
        + ' ' 
        + (case when IS_NULLABLE = 'No' then 'NOT ' else '' end) 
        + 'NULL ' 
        + case when information_schema.columns.COLUMN_DEFAULT IS NOT NULL THEN 'DEFAULT '+ information_schema.columns.COLUMN_DEFAULT 
          ELSE '' 
          END 
        + ', ' 
        + @PLACEHOLDER  -- note, can't have a field name or we'll end up with XML

    FROM information_schema.columns where table_name = so.name
    ORDER BY ordinal_position
    FOR XML PATH('')
) o (list)

LEFT JOIN information_schema.table_constraints tc on  
    tc.Table_name = so.Name
    AND tc.Constraint_Type  = 'PRIMARY KEY'

LEFT JOIN information_schema.tables t on  
    t.Table_name = so.Name

CROSS APPLY (
    SELECT QUOTENAME(Column_Name) + ', '
    FROM information_schema.key_column_usage kcu
    WHERE kcu.Constraint_Name = tc.Constraint_Name
    ORDER BY ORDINAL_POSITION
    FOR XML PATH('')
) j (list)

WHERE
    xtype = 'U'
    AND name NOT IN ('dtproperties')
     AND so.name in (select name from @TableNames)

     
union all

select '
--------------------------
-- Truncate records in copy tables
--------------------------
'
union all
select 
'
print ''truncating ' +  QuoteName(@CopyDatabaseName) + '.' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix) + '''
truncate table ' + QuoteName(@CopyDatabaseName) + '.' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix) + '
GO
'
 from sysobjects so
LEFT JOIN information_schema.tables t on  
    t.Table_name = so.Name
WHERE
    xtype = 'U'
    AND name NOT IN ('dtproperties')
     AND so.name in (select name from @TableNames)     

union all

select '
--------------------------
-- Copy records
--------------------------
'
union all
select 
'
print ''''
print ''copiyng ' +  QuoteName(@CopyDatabaseName) + '.' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix) + '''
insert into ' + QuoteName(@CopyDatabaseName) + '.' +  QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name+@CopyPostfix) + 
' select * from ' + QuoteName(t.TABLE_SCHEMA) + '.' + QuoteName(so.name) + '
GO
'
 from sysobjects so
LEFT JOIN information_schema.tables t on  
    t.Table_name = so.Name
WHERE
    xtype = 'U'
    AND name NOT IN ('dtproperties')
     AND so.name in (select name from @TableNames)