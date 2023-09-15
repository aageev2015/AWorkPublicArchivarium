USE [AwesomeSystemV0_TEST_DBTool]
GO

/****** Object:  View [dbo].[LOG_OF_ALL_VIEW]    Script Date: 5/13/2016 16:23:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER view [dbo].[LOG_OF_ALL_VIEW]
as
select
	'REC_ORDER_X' log_name
,	'SP' log_kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	[Action] [Description]
,	convert(nvarchar(500), p_id) Details
,	id Log_Id
from LOG_OF_AUTO_REC_ORDER_X
union all
select
	'DELIVER_LINE_X' log_name
,	'SP' log_kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	[Action] [Description]
,	convert(nvarchar(500), p_id) Details
,	id Log_Id
from LOG_OF_AUTO_DELIVER_LINE_X

union all
select
	'REC_ORDER' log_name
,	'T' log_kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	tag [Description]
,	'ID=' + isnull(convert(nvarchar(500), isnull(old_id,new_id)), 'NULL') Details
,	id Log_Id
from LOG_OF_REC_ORDER

union all
select
	'DELIVER_LINE' log_name
,	'T' log_kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	tag [Description]
,	'ID=' + isnull(convert(nvarchar(500), isnull(old_id,new_id)), 'NULL') Details
,	id Log_Id
from LOG_OF_DELIVER_LINE

union all
select
	'STOCK' log_name
,	'T' log_kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	tag [Description]
,	'ID=' + isnull(convert(nvarchar(500), isnull(old_id,new_id)), 'NULL') Details
,	id Log_Id
from LOG_OF_STOCK

union all
select
	'SEND_LINE' log_name
,	'SP' kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	branch_path [Description]
,	'AREA_ID=' + isnull(convert(nvarchar(500), p_AREA_ID), 'NULL') 
	+',ITEM_ID=' + isnull(convert(nvarchar(500), isnull(p_ITEM_ID, p_LINE_ITEM_ID)), 'NULL') 
	+',ORDER_ID=' + isnull(convert(nvarchar(500), p_LINE_ORDER_ID), 'NULL') 
	+',LINE_ID=' + isnull(convert(nvarchar(500), p_LINE_ID), 'NULL') 
	Details
,	id Log_Id
from LOG_OF_USER_DELIVER_LINE_SP_SEND_LINE

union all
select
	'ALLOCATE' log_name
,	'SP' kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	branch_path [Description]
,	'STOCK_ID=' + isnull(convert(nvarchar(500), p_ID), 'NULL') 
	+',ORDER_NUM=' + isnull(convert(nvarchar(500), p_ORDER_NUM), 'NULL') 
	Details
,	id Log_Id
from LOG_OF_USER_STOCK_SP_ALLOCATE

union all
select
	'ALLOCATE_ALL' log_name
,	'SP' kind
,	CreatedOn CreatedOn
,	Row_ver Row_ver
,	[CONTEXT_INFO] [context_info]
,	branch_path [Description]
,	'ORDER_ID=' + isnull(convert(nvarchar(500), p_ORDER_ID), 'NULL') 
	+',LINE_ID=' + isnull(convert(nvarchar(500), p_LINE_ITEM_ID), 'NULL') 
	Details
,	id Log_Id
from LOG_OF_USER_STOCK_SP_ALLOCATE_ALL
GO
