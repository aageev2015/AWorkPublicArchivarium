select 
    therow.value('./ID[1]', 'nvarchar(50)') ID
,   therow.value('./TimeCreated[1]', 'nvarchar(50)') ID
,   therow.value('./Number[1]', 'nvarchar(50)') Number
,   therow.value('(./Vendor/ListID)[1]', 'nvarchar(50)') Vendor_ListID
,   therow.value('(./Vendor/FullName)[1]', 'nvarchar(150)') Vendor_name
,   therow.value('./Date[1]', 'nvarchar(50)') [Date]
,   therow.value('./Number[1]', 'nvarchar(50)') [Number]
,   therow.query('./Address') Address

from tbl_xmls t
cross apply t.[xml].nodes('QBXML/QBXMLMsgs/PurchaseOrder/PurchaseOrderReturn') x(therow)
where code='..removed..'
