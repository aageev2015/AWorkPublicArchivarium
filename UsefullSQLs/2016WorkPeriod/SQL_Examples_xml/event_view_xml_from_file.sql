DECLARE @XmlFile XML

SELECT @XmlFile = BulkColumn
FROM  OPENROWSET(BULK 'd:\temp\Log\2.xml', SINGLE_BLOB) x;

--declare @A xml;
with XMLNAMESPACES('http://schemas.microsoft.com/win/2004/08/events/event' as n)
select *
from (
    select
	   Data.[all].value('(//n:TimeCreated/@SystemTime)[1]', 'datetime') createdOn,
	   Data.RenderingInfo.value('(//n:Message)[1]', 'nvarchar(4000)') [message],
	   data.* 
    from (
	   select 
		  r.query('.') as [all],
		  r.query('./n:EventData') as [EventData],
		  r.query('./n:RenderingInfo') as RenderingInfo
	   /*
		  therow.value('./ID[1]', 'nvarchar(50)') ID
	   ,   therow.value('./TimeCreated[1]', 'nvarchar(50)') ID
	   ,   therow.value('./Number[1]', 'nvarchar(50)') Number
	   ,   therow.value('(./Vendor/ListID)[1]', 'nvarchar(50)') Vendor_ListID
	   ,   therow.value('(./Vendor/FullName)[1]', 'nvarchar(150)') Vendor_name
	   ,   therow.value('./Date[1]', 'nvarchar(50)') Date
	   ,   therow.value('./Number[1]', 'nvarchar(50)') Number
	   ,   therow.query('./Address') Address
	   */
	   from @xmlFile.nodes('/Events/*') x(r)
    ) data
    where data.[EventData].exist('//*[.="$Printer_Maestro$"]')=0
) data
where 1=1
and data.createdon>dateadd(dd,-1,getdate())
--data.RenderingInfo.value('./.', 'nvarchar(1000)') not like '%Printer_Maestro%'
order by createdon desc

--2016-09-08 10:37:48.113