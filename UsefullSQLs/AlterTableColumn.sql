Kills Collation

alter table [tbl_SystemSetting] ADD [EnumItemID2] [nvarchar] (250) NULL
update tbl_SystemSetting
set EnumItemID2=EnumItemID
alter table [tbl_SystemSetting] drop column [EnumItemID]
alter table [tbl_SystemSetting] alter column [EnumItemID2] [EnumItemID]
alter table [tbl_SystemSetting] ADD [EnumItemID] [nvarchar] (250) NULL
update tbl_SystemSetting
set EnumItemID=EnumItemID2
alter table [tbl_SystemSetting] drop column [EnumItemID2]
