select 
    therow.query('./*')
from tbl_xmls t
cross apply t.[xml].nodes('QBXML/QBXMLMsgsRs/PurchaseOrder/PurchaseRet') x(therow)
--cross apply x.xml.nodes() as x_rows(x_row)
where code='..removed..'
