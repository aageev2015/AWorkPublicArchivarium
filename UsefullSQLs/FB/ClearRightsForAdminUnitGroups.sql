
EXECUTE BLOCK
returns (result varchar(250))
AS
declare variable "RootAdminUnitID" varchar(38);
declare variable "SQLText" varchar(500);
declare variable "RightsTableName" varchar(500);
declare variable "OldCount" int;
BEGIN
--1
select "ID" from "tbl_AdminUnit" where "GroupParentID" is null and "IsGroup" = 1
into :"RootAdminUnitID";
delete from "tbl_UserInGroup"
where "GroupID" <> :"RootAdminUnitID";

--2
FOR
  select
  trim(a.rdb$relation_name)
  from RDB$RELATION_CONSTRAINTS a, rdb$REF_Constraints b, RDB$RELATION_CONSTRAINTS c
  where
   trim(a.rdb$relation_name) like '%Right' and
  c.rdb$relation_name = 'tbl_AdminUnit' and
  a.rdb$constraint_Name=b.rdb$constraint_Name
  and c.rdb$constraint_name=b.RDB$CONST_NAME_UQ
  order by a.rdb$relation_name
        INTO "RightsTableName"
        DO BEGIN
            "SQLText" =   'delete from "'||"RightsTableName"||'"
            where "AdminUnitID" in (
            Select "ID" from "tbl_AdminUnit"
            where "IsGroup"=1 and "GroupParentID" is not null)';
            result = "SQLText";
            suspend;
            execute statement "SQLText";
            result = '       Processed';
            suspend;
        END

END

