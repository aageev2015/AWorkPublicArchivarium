select
*
from (
	select lower(column_name) column_name from
	(values 
	(N'QuantityToReceiveUom'),(N'QuantityToReceiveMultiplier'),(N'QuantityToReceiveValue'),(N'ReceivedQuantityUom'),(N'ReceivedQuantityMultiplier'),(N'ReceivedQuantityValue'),(N'LateralOrderId'),(N'AccountId'),(N'Lin'),(N'EquipmentName'),(N'ItemId'),(N'ItemCode'),(N'ItemDescription'),(N'Smco'),(N'EquipmentType'),(N'Serial'),(N'PrimaryHolder'),(N'SubHolder'),(N'State'),(N'ReadinessStatus'),(N'OrderedQuantityUom'),(N'OrderedQuantityMultiplier'),(N'OrderedQuantityValue')
	) v1(column_name)
) v1
full join (
	select lower(replace(column_name,'_', '')) column_name from INFORMATION_SCHEMA.COLUMNS
	where TABLE_NAME = 'LATERAL_ORDER_LINE'
) v2(column_name) on v1.column_name = v2.column_name
