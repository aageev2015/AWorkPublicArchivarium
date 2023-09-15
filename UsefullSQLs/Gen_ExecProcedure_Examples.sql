
select 
(case when ParameterID = 1
	then 
'print '''+ DBName + '.' + SchemaName + '.' + [ObjectName]+	'''
exec '+ DBName + '.' + SchemaName + '.' + [ObjectName]+	'
' else ',' end )
+'		' + (	case 
				when ParameterName='@tt' then 'ConstParamValue'
				else
					ParameterName + '=' 
					+	(	case ParameterDataType 
							when 'uniqueidentifier' then '''{00000000-0000-0000-0000-000000000000}'''
							when 'datetime' then '''2014-'+cast((abs(cast(CRYPT_GEN_RANDOM(4) as int))%12+1) as nvarchar(2))+'-'+cast((abs(cast(CRYPT_GEN_RANDOM(4) as int))%28+1) as nvarchar(2))+' 00:00:00.000'''
							when 'decimal' then cast(round(abs(cast(CRYPT_GEN_RANDOM(4) as int))/100, 2) as nvarchar(250))
							when 'int' then cast(abs(cast(CRYPT_GEN_RANDOM(4) as int))%2 as nvarchar(2))
							when 'nvarchar' then '''Some text ' + cast(abs(cast(CRYPT_GEN_RANDOM(4) as int)) as nvarchar(250)) + ''''
							else 'null'
							end 
						) 
					+	CHAR(13)+char(10)
				end
			)
+ (case when IsLast=1 then CHAR(13)+char(10) else '' end)
 as sql_text
--,*

from (
	SELECT 
		schema_name(so.schema_id) as SchemaName, 
		db_Name(so.parent_object_id) as DBName,
		SO.name AS [ObjectName],
		P.parameter_id AS [ParameterID],
		P.name AS [ParameterName],
		(case when not exists(	select 1 from sys.parameters p2 
								where p2.object_id = so.object_id 
									and p2.parameter_id=p.parameter_id+1) 
			then 1 else 0 end) as IsLast,
		TYPE_NAME(P.user_type_id) AS [ParameterDataType]

	FROM sys.objects AS SO
	INNER JOIN sys.parameters AS P
	ON SO.OBJECT_ID = P.OBJECT_ID
	WHERE SO.TYPE IN ('P','FN')
	and so.name like ('exweb_v2_Edit%')
) t
ORDER BY t.[ObjectName], t.[ParameterID]

