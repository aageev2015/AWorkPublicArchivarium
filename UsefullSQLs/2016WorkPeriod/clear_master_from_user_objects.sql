
use master
with t as (
select 
	(
		case o.xtype 
			--when 'C ' then ''
			when 'F ' then
'
print ''' + o.name + ''';
alter table dbo.[' + o2.name +'] drop constraint [' + o.name + '];
'
			when 'FN' then
'
print ''' + o.name + ''';
drop function dbo.[' + o.name +'];
'
			when 'P ' then
'
print ''' + o.name + ''';
drop procedure dbo.[' + o.name +'];
'
			--when 'PK' then ''
			--when 'TF' then 'drop function dbo.' + o.name +']; '
			when 'TR' then
'
print ''' + o.name + ''';
drop trigger dbo.[' + o.name +'];
'
			when 'U ' then
'
print ''' + o.name + ''';
drop table dbo.[' + o.name +'];
'
			--when 'UQ' then ''
			when 'V ' then
'
print ''' + o.name + ''';
drop view dbo.[' + o.name +'];
'
		end 
	) sql
	, o2.name o2_name
	, o.*
from master..sysobjects o
left join master..sysobjects o2 on o.parent_obj=o2.id
where o.category=0
)
select * from t 
where sql is not null
order by xtype
