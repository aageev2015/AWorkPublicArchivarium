CREATE OR ALTER PROCEDURE "Pos"(
    "SUBSTR" varchar(8000),
    "STR" varchar(8000))
returns (
    "POS" integer)
as
DECLARE VARIABLE SubStr2 VARCHAR(8000); /* 1 + SubStr-lenght + Str-length */
  DECLARE VARIABLE Tmp VARCHAR(8000);
BEGIN
  IF (SubStr IS NULL OR Str IS NULL)
  THEN BEGIN Pos = NULL; EXIT; END

  SubStr2 = SubStr || '%';
  Tmp = '';
  Pos = 1;
  WHILE (Str NOT LIKE SubStr2 AND Str NOT LIKE Tmp) DO BEGIN
    SubStr2 = '_' || SubStr2;
    Tmp = Tmp || '_';
    Pos = Pos + 1;
  END

  IF (Str LIKE Tmp) THEN Pos = 0;
  SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_AdminUnitTableGroupRoleList"(
    "AdminUnitSQLObjectName" varchar(31) character set unicode_fss)
returns (
    "GroupName" varchar(128) character set unicode_fss,
    "SQLObjectName" varchar(31) character set unicode_fss,
    "Code" varchar(31) character set unicode_fss,
    "CanRead" integer,
    "CanInsert" integer,
    "CanUpdate" integer,
    "CanDelete" integer)
as
DECLARE VARIABLE ROOTID VARCHAR(38);
DECLARE VARIABLE ADMINUNITID VARCHAR(38);
BEGIN
    SELECT FIRST 1
        tg_root."ID"
    FROM "tbl_TableGroup" tg_root
    WHERE tg_root."SQLObjectName" = 'TG'
    INTO :RootID;

    SELECT FIRST 1
        au."ID"
    FROM "tbl_AdminUnit" au
    WHERE au."SQLObjectName" = :"AdminUnitSQLObjectName"
    INTO :AdminUnitID;
    
    FOR SELECT
        tg_main."Name",
        tg_main."SQLObjectName",
        tg_main."Code",
        (CASE WHEN EXISTS(
            SELECT
                tg_au."ID"
            FROM "tbl_TableGroup" tg_au
            WHERE tg_au."AdminUnitID" = :AdminUnitID
            AND tg_au."ParentID" = (
                SELECT tg."ID"
                FROM "tbl_TableGroup" tg
                WHERE tg."Name" = tg_main."SQLObjectName" || '_CR'
            )
        ) THEN 1 ELSE 0
        END),
        (CASE WHEN EXISTS(
            SELECT
                tg_au."ID"
            FROM "tbl_TableGroup" tg_au
            WHERE tg_au."AdminUnitID" = :AdminUnitID
            AND tg_au."ParentID" = (
                SELECT tg."ID"
                FROM "tbl_TableGroup" tg
                WHERE tg."Name" = tg_main."SQLObjectName" || '_CI'
            )
        ) THEN 1 ELSE 0
        END),
        (CASE WHEN EXISTS(
            SELECT
                tg_au."ID"
            FROM "tbl_TableGroup" tg_au
            WHERE tg_au."AdminUnitID" = :AdminUnitID
            AND tg_au."ParentID" = (
                SELECT tg."ID"
                FROM "tbl_TableGroup" tg
                WHERE tg."Name" = tg_main."SQLObjectName" || '_CU'
            )
        ) THEN 1 ELSE 0
        END),
        (CASE WHEN EXISTS(
            SELECT
                tg_au."ID"
            FROM "tbl_TableGroup" tg_au
            WHERE tg_au."AdminUnitID" = :AdminUnitID
            AND tg_au."ParentID" = (
                SELECT tg."ID"
                FROM "tbl_TableGroup" tg
                WHERE tg."Name" = tg_main."SQLObjectName" || '_CD'
            )
        ) THEN 1 ELSE 0
        END)
    FROM "tbl_TableGroup" tg_main
    WHERE tg_main."ParentID" = :RootID
    INTO :"GroupName", :"SQLObjectName", :"Code", :"CanRead", :"CanInsert", :"CanUpdate", :"CanDelete"
    DO SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_AdministratedByRecords"(
    "ATableName" varchar(31),
    "ARightTableName" varchar(31),
    "ATableViewName" varchar(31),
    "ARightTableViewName" varchar(31),
    "AEnabled" integer = 1,
    "AIsLogTable" integer = 0)
as
DECLARE VARIABLE "InsertTriggerName" VARCHAR(31);
DECLARE VARIABLE "UpdateTriggerName" VARCHAR(31);
DECLARE VARIABLE "DeleteTriggerName" VARCHAR(31);
DECLARE VARIABLE "InsertRightTriggerName" VARCHAR(31);
DECLARE VARIABLE "UpdateRightTriggerName" VARCHAR(31);
DECLARE VARIABLE "DeleteRightTriggerName" VARCHAR(31);
DECLARE VARIABLE "BeforeInsertTriggerName" VARCHAR(31);
DECLARE VARIABLE "BeforeInsertRightTriggerName" VARCHAR(31);
DECLARE VARIABLE "TemplateFilter1" VARCHAR(1000);
DECLARE VARIABLE "TemplateFilter2" VARCHAR(1000);
DECLARE VARIABLE "TemplateFilter3" VARCHAR(1000);
DECLARE VARIABLE "Filter" VARCHAR(30000);
DECLARE VARIABLE "CheckReplication" VARCHAR(250);
DECLARE VARIABLE "Columns" VARCHAR(30000);
DECLARE VARIABLE "Column" VARCHAR(31);
DECLARE VARIABLE "ShortTableName" VARCHAR(31);
DECLARE VARIABLE "ShortTableViewName" VARCHAR(31);
DECLARE VARIABLE "ShortRightTableViewName" VARCHAR(31);
DECLARE VARIABLE "ShortRightTableName" VARCHAR(31);
BEGIN

    SELECT "ObjectName" FROM "tsp_TruncObjectName"(:"ATableName", 25)
    INTO :"ShortTableName";
    SELECT "ObjectName" FROM "tsp_TruncObjectName"(:"ATableViewName", 25)
    INTO :"ShortTableViewName";
    SELECT "ObjectName" FROM "tsp_TruncObjectName"(:"ARightTableViewName", 25, 'View')
    INTO :"ShortRightTableViewName";
    SELECT "ObjectName" FROM "tsp_TruncObjectName"(:"ARightTableName", 25)
    INTO :"ShortRightTableName";

    "InsertTriggerName" = 'tr_' || :"ShortTableName" || '_AI';
    "UpdateTriggerName" = 'tr_' || :"ShortTableViewName" || '_BU';
    "DeleteTriggerName" = 'tr_' || :"ShortTableViewName" || '_BD';
    "InsertRightTriggerName" = 'tr_' || :"ShortRightTableViewName" || '_BI';
    "UpdateRightTriggerName" = 'tr_' || :"ShortRightTableViewName" || '_BU';
    "DeleteRightTriggerName" = 'tr_' || :"ShortRightTableViewName" || '_BD';
    "BeforeInsertTriggerName" = 'tr_' || :"ShortTableName" || '_BI';
    "BeforeInsertRightTriggerName" = 'tr_' || :"ShortRightTableName" || '_BI';

    IF (COALESCE(:"AEnabled", 0) = 0) THEN
    BEGIN
        IF (EXISTS(
            SELECT * FROM RDB$RELATIONS
            WHERE (NOT RDB$VIEW_SOURCE IS NULL)
            AND (RDB$SYSTEM_FLAG = 0)
            AND (RDB$RELATION_NAME = :"ARightTableViewName")
            )) THEN
        BEGIN
            EXECUTE STATEMENT 'DROP VIEW "' || :"ARightTableViewName" || '"';
        END

        IF (EXISTS(
            SELECT * FROM RDB$RELATIONS
            WHERE (NOT RDB$VIEW_SOURCE IS NULL)
            AND (RDB$SYSTEM_FLAG = 0)
            AND (RDB$RELATION_NAME = :"ATableViewName")
            )) THEN
        BEGIN
            EXECUTE STATEMENT 'DROP VIEW "' || :"ATableViewName" || '"';
        END

        IF (EXISTS(
            SELECT * FROM RDB$TRIGGERS
            WHERE (RDB$TRIGGER_NAME = :"InsertTriggerName")
            )) THEN
        BEGIN
            EXECUTE STATEMENT 'DROP TRIGGER "' || :"InsertTriggerName" || '"';
        END
    
        EXIT;
    END

    EXECUTE STATEMENT 'REVOKE ALL ON "' || :"ATableName" || '" FROM "PUBLIC"';

    "TemplateFilter1" = 'EXISTS (
        SELECT * FROM "' || :"ARightTableName" || '" R
        WHERE ((R."';

    "TemplateFilter2" =
        '" = 1)
        AND (R."RecordID" = ';

    "TemplateFilter3" = ')
        AND EXISTS(
            SELECT * FROM "tbl_UserAdminUnit" U
            WHERE (R."AdminUnitID" = U."AdminUnitID")
            AND (U."UserName" = USER))))';

    IF (COALESCE(:"AIsLogTable", 0) = 0) THEN
    BEGIN
      "Filter" = "TemplateFilter1" || 'CanRead' || "TemplateFilter2" || 'P."ID"' || "TemplateFilter3";
    END ELSE
    BEGIN
      "Filter" = "TemplateFilter1" || 'CanRead' || "TemplateFilter2" || 'P."RecordID"' || "TemplateFilter3";
    END

    EXECUTE STATEMENT 'RECREATE VIEW "' || :"ATableViewName" ||'" AS ' ||
        '
    SELECT P.* ' || '
    FROM "' || :"ATableName" || '" P ' || '
    WHERE ' || :"Filter";

    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ATableName" || '" TO VIEW "' || :"ATableViewName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "tbl_UserAdminUnit" TO VIEW "' || :"ATableViewName" ||'"';

    IF (COALESCE(:"AIsLogTable", 0) = 1) THEN
    BEGIN
      EXIT;
    END

    "CheckReplication" = 'IF (USER = ''TS_REPLICATION'') THEN BEGIN EXIT; END';
    
    EXECUTE STATEMENT 'RECREATE TRIGGER "' || :"InsertTriggerName" || '"
    FOR "' || :"ATableName" || '"
    ACTIVE AFTER INSERT POSITION 0
    AS
        DECLARE VARIABLE ServiceTableID VARCHAR(38);
        DECLARE VARIABLE AdminUnitID VARCHAR(38);
    BEGIN
        ' || :"CheckReplication" || '

        SELECT "ID" FROM "tbl_Service"
        WHERE "Code" = ''' || :"ATableName" || '''
        AND "ServiceTypeCode" = ''Table''
        INTO :ServiceTableID;

        SELECT "ID"
        FROM "tbl_AdminUnit" WHERE "SQLObjectName" = USER
        INTO :AdminUnitID;

        INSERT INTO "' || :"ARightTableName" || '" ("RecordID", "AdminUnitID", "CanRead", "CanWrite", "CanDelete", "CanChangeAccess")
        VALUES (NEW."ID", :AdminUnitID, 1, 1, 1, 1);

        INSERT INTO "' || :"ARightTableName" || '" ("RecordID", "AdminUnitID", "CanRead", "CanWrite", "CanDelete", "CanChangeAccess")
        SELECT NEW."ID", D."SubjectAdminUnitID", D."CanRead", D."CanWrite", D."CanDelete", D."CanChangeAccess"
        FROM (
            SELECT D."SubjectAdminUnitID", MAX(D."CanRead") AS "CanRead", MAX(D."CanWrite") AS "CanWrite",
            MAX(D."CanDelete") AS "CanDelete", MAX(D."CanChangeAccess") AS "CanChangeAccess"
            FROM "tbl_TableDefaultRight" AS D
            WHERE (D."TableServiceID" = :ServiceTableID)
            AND (NOT D."SubjectAdminUnitID" = :AdminUnitID)
            AND EXISTS(
                SELECT * FROM "tbl_UserAdminUnit" AS U
                WHERE ("D"."AdminUnitID" = U."AdminUnitID")
                AND (U."UserName" = USER))
            GROUP BY D."SubjectAdminUnitID") AS D;
    END';
    
    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ATableName" || '" TO TRIGGER"' || :"InsertTriggerName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ARightTableName" || '" TO TRIGGER"' || :"InsertTriggerName" ||'"';

    "Columns" = '';
    "Column" = '';
    
    FOR
        SELECT RF.RDB$FIELD_NAME FROM RDB$RELATION_FIELDS RF
        WHERE RF.RDB$RELATION_NAME = :"ATableName"
        AND NOT TRIM(RF.RDB$FIELD_NAME) = 'ID'
    INTO :"Column" DO
    BEGIN
      "Columns" = "Columns" || '
        "' || TRIM(:"Column") || '" = NEW."' || TRIM(:"Column") || '",';
    END
    "Columns" = TRIM(TRAILING ',' FROM :"Columns");

    "Filter" = "TemplateFilter1" || 'CanWrite' || "TemplateFilter2" || 'NEW."ID"' || "TemplateFilter3";

    EXECUTE STATEMENT
    'RECREATE TRIGGER "' || :"UpdateTriggerName" ||'"
    FOR "' || :"ATableViewName" || '"
    ACTIVE BEFORE UPDATE POSITION 0
    AS
    BEGIN
        IF (' || :"Filter" || '
        ) THEN
        UPDATE "' || :"ATableName" || '"
        SET ' || :"Columns" || '
        WHERE ("ID" = NEW."ID");
    END';

    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ATableName" || '" TO TRIGGER"' || :"UpdateTriggerName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "tbl_UserAdminUnit" TO TRIGGER"' || :"UpdateTriggerName" ||'"';


    "Filter" = "TemplateFilter1" || 'CanDelete' || "TemplateFilter2" || 'OLD."ID"' || "TemplateFilter3";
    
    EXECUTE STATEMENT 'RECREATE TRIGGER "' || :"DeleteTriggerName" ||'"
    FOR "' || :"ATableViewName" || '"
    ACTIVE BEFORE DELETE POSITION 0
    AS
    BEGIN
        IF (' || :"Filter" || '
        ) THEN
        DELETE FROM "' || :"ATableName" || '"
        WHERE ("ID" = OLD."ID");
    END';

    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ATableName" || '" TO TRIGGER"' || :"DeleteTriggerName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "tbl_UserAdminUnit" TO TRIGGER"' || :"DeleteTriggerName" ||'"';

    EXECUTE STATEMENT 'RECREATE VIEW "' || :"ARightTableViewName" || '"
    AS
        SELECT *
        FROM "' || :"ARightTableName" || '" ';

    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ARightTableName" || '" TO VIEW"' || :"ARightTableViewName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ARightTableViewName" || '" TO "PUBLIC"';


    "Filter" = "TemplateFilter1" || 'CanChangeAccess' || "TemplateFilter2" || 'NEW."RecordID"' || "TemplateFilter3";

    EXECUTE STATEMENT
    'RECREATE TRIGGER "' || :"InsertRightTriggerName" || '"
    FOR "' || :"ARightTableViewName" || '"
    ACTIVE BEFORE INSERT POSITION 0
    AS
    BEGIN
        IF (' || :"Filter" || '
        ) THEN
        INSERT INTO "' || :"ARightTableName" || '"
        ("ID", "RecordID", "AdminUnitID", "CanRead", "CanWrite", "CanDelete", "CanChangeAccess")
        VALUES (NEW."ID", NEW."RecordID", NEW."AdminUnitID", NEW."CanRead", NEW."CanWrite", NEW."CanDelete", NEW."CanChangeAccess");
    END';

    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ARightTableName" || '" TO TRIGGER"' || :"InsertRightTriggerName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "tbl_UserAdminUnit" TO TRIGGER"' || :"InsertRightTriggerName" ||'"';


    "Filter" = "TemplateFilter1" || 'CanChangeAccess' || "TemplateFilter2" || 'OLD."RecordID"' || "TemplateFilter3";
    
    EXECUTE STATEMENT
    'RECREATE TRIGGER "' || :"UpdateRightTriggerName" || '"
    FOR "' || :"ARightTableViewName" || '"
    ACTIVE BEFORE UPDATE POSITION 0
    AS
    BEGIN
        IF (' || :"Filter" || '
        ) THEN
        UPDATE "' || :"ARightTableName" || '" SET
        "RecordID" = NEW."RecordID",
        "AdminUnitID" = NEW."AdminUnitID",
        "CanRead" = NEW."CanRead",
        "CanWrite" = NEW."CanWrite",
        "CanDelete" = NEW."CanDelete",
        "CanChangeAccess" = NEW."CanChangeAccess"
        WHERE ("ID" = NEW."ID");
    END';
    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ARightTableName" || '" TO TRIGGER"' || :"UpdateRightTriggerName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "tbl_UserAdminUnit" TO TRIGGER"' || :"UpdateRightTriggerName" ||'"';


    "Filter" = "TemplateFilter1" || 'CanChangeAccess' || "TemplateFilter2" || 'OLD."RecordID"' || "TemplateFilter3";
    
    EXECUTE STATEMENT
    'RECREATE TRIGGER "' || :"DeleteRightTriggerName" || '"
    FOR "' || :"ARightTableViewName" || '"
    ACTIVE BEFORE DELETE POSITION 0
    AS
    BEGIN
        IF (' || :"Filter" || '
        ) THEN
        DELETE FROM "' || :"ARightTableName" || '"
        WHERE ("ID" = OLD."ID");
    END';

    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ARightTableName" || '" TO TRIGGER"' || :"DeleteRightTriggerName" ||'"';
    EXECUTE STATEMENT 'GRANT ALL ON "tbl_UserAdminUnit" TO TRIGGER"' || :"DeleteRightTriggerName" ||'"';

END
;
CREATE OR ALTER PROCEDURE "tsp_BeforeInsertTrigger"(
    "ATableName" varchar(31))
as
DECLARE VARIABLE "ShortTableName" VARCHAR(31);
  DECLARE VARIABLE "BeforeInsertTriggerName" VARCHAR(31);
BEGIN
  SELECT "ObjectName" FROM "tsp_TruncObjectName"(:"ATableName", 25)
  INTO :"ShortTableName";

  "BeforeInsertTriggerName" = 'tr_' || :"ShortTableName" || '_BI';

  EXECUTE STATEMENT
  'RECREATE TRIGGER "' || :"BeforeInsertTriggerName" || '"
FOR "' || :"ATableName" || '"
ACTIVE BEFORE INSERT POSITION 0
AS
BEGIN
  IF (NEW."ID" IS NULL) THEN
  BEGIN
    SELECT "NewGUID" FROM "tsp_CreateGUID"
    INTO NEW."ID";
  END
END';
  EXECUTE STATEMENT 'GRANT ALL ON "' || :"ATableName" || '" TO TRIGGER "' || :"BeforeInsertTriggerName" ||'"';
END
;
CREATE OR ALTER PROCEDURE "tsp_ChangeTableFieldRight"(
    "AAdminUnitName" varchar(250),
    "ATableName" varchar(250),
    "AFieldName" varchar(250),
    "ANewAccessLevel" integer)
as
DECLARE VARIABLE "CurrentAdminUnitID" VARCHAR(38);
DECLARE VARIABLE "AdminUnitID" VARCHAR(38);
DECLARE VARIABLE "TableServiceID" VARCHAR(38);
DECLARE VARIABLE "TableFieldRightID" VARCHAR(38);
BEGIN
    SELECT "ID" FROM "tbl_AdminUnit"
    WHERE UPPER("SQLObjectName") = UPPER(USER) INTO "CurrentAdminUnitID";
 
    SELECT "ID" FROM "tbl_Service"
    WHERE (UPPER("Code") = UPPER(TRIM(:"ATableName"))
    OR UPPER("Code") = 'TBL_' || TRIM(LEADING 'VW_' FROM
    UPPER(TRIM(:"ATableName"))))
    AND "ServiceTypeCode" = 'Table' INTO "TableServiceID";

    SELECT "ID" FROM "tbl_AdminUnit"
    WHERE UPPER("SQLObjectName") = UPPER(TRIM(:"AAdminUnitName"))
    INTO "AdminUnitID";
 
    SELECT "ID" FROM "tbl_TableFieldRight" tfr
    WHERE tfr."TableServiceID" = :"TableServiceID"
    AND UPPER(tfr."FieldName") = UPPER(TRIM(:"AFieldName"))
    AND tfr."AdminUnitID" = :"AdminUnitID" INTO "TableFieldRightID";

    IF ("TableFieldRightID" IS NULL) THEN
    BEGIN
        SELECT "NewGUID" FROM "tsp_CreateGUID" INTO "TableFieldRightID";

        INSERT INTO "tbl_TableFieldRight" ("ID", "TableServiceID", "FieldName",
        "AdminUnitID", "RightsLevel", "CreatedOn", "CreatedByID", "ModifiedOn",
        "ModifiedByID")
        VALUES(:"TableFieldRightID", :"TableServiceID", :"AFieldName",
        :"AdminUnitID", :"ANewAccessLevel", CURRENT_TIMESTAMP,
        :"CurrentAdminUnitID", CURRENT_TIMESTAMP, :"CurrentAdminUnitID");
    END ELSE
    BEGIN
        UPDATE "tbl_TableFieldRight"
        SET "RightsLevel" = :"ANewAccessLevel",
        "ModifiedOn" = CURRENT_TIMESTAMP,
        "ModifiedByID" = :"CurrentAdminUnitID"
        WHERE "ID" = :"TableFieldRightID";
    END
END
;
CREATE OR ALTER PROCEDURE "tsp_ColumnsRights"(
    "TableName" varchar(31),
    "UserGroup" varchar(250) = '')
returns (
    "FieldName" varchar(31),
    "RightsLevel" integer)
as
DECLARE VARIABLE "UserName" VARCHAR(31);
DECLARE VARIABLE "TableServiceID" VARCHAR(38);
DECLARE VARIABLE "AdminUnitID" VARCHAR(38);
BEGIN
    "TableName" = UPPER(TRIM(:"TableName"));
    "UserName" = UPPER(TRIM(:"UserGroup"));

    SELECT "ID" FROM "tbl_Service"
    WHERE (UPPER("Code") = UPPER(TRIM(:"TableName"))
    OR UPPER("Code") = 'TBL_' || TRIM(LEADING 'VW_' FROM
    :"TableName"))
    AND "ServiceTypeCode" = 'Table' INTO "TableServiceID";

    SELECT "ID" FROM "tbl_AdminUnit"
    WHERE UPPER("SQLObjectName") = :"UserName"
    INTO "AdminUnitID";

    FOR SELECT TRIM(R.RDB$FIELD_NAME) AS "FieldName",
    (SELECT MAX(tfr."RightsLevel") AS "RightsLevel"
    FROM "tbl_TableFieldRight" tfr
    WHERE tfr."TableServiceID" = :"TableServiceID"
    AND TRIM(tfr."FieldName") = TRIM(R.RDB$FIELD_NAME)
    AND tfr."AdminUnitID" = :"AdminUnitID") AS "RightsLevel"
    FROM RDB$RELATION_FIELDS R
    WHERE (R.RDB$SYSTEM_FLAG = 0)
        AND (UPPER(TRIM(R.RDB$RELATION_NAME)) = :"TableName")
        AND (R.RDB$FIELD_NAME NOT IN ('ID', 'CreatedOn', 'CreatedByID',
        'ModifiedOn', 'ModifiedByID'))
    INTO :"FieldName", :"RightsLevel"
    DO
    BEGIN
        "RightsLevel" = COALESCE(:"RightsLevel", :"RightsLevel", 2);
        SUSPEND;
    END
END
;
CREATE OR ALTER PROCEDURE "tsp_ColumnsRightsEx"(
    "TableName" varchar(31))
returns (
    "FieldName" varchar(31),
    "RightsLevel" integer)
as
DECLARE VARIABLE "UserName" VARCHAR(31);
DECLARE VARIABLE "TableServiceID" VARCHAR(38);
DECLARE VARIABLE "AdminUnitID" VARCHAR(38);
BEGIN
    "TableName" = UPPER(TRIM(:"TableName"));
    "UserName" = UPPER(TRIM(USER));

    SELECT "ID" FROM "tbl_Service"
    WHERE (UPPER("Code") = UPPER(TRIM(:"TableName"))
    OR UPPER("Code") = 'TBL_' || TRIM(LEADING 'VW_' FROM
    :"TableName"))
    AND "ServiceTypeCode" = 'Table' INTO "TableServiceID";

    SELECT "ID" FROM "tbl_AdminUnit"
    WHERE UPPER("SQLObjectName") = :"UserName"
    INTO "AdminUnitID";

    FOR SELECT TRIM(R.RDB$FIELD_NAME) AS "FieldName",
    CASE WHEN (EXISTS(SELECT * FROM "tbl_UserAdminUnit" uau1
                WHERE NOT EXISTS(SELECT * FROM "tbl_TableFieldRight" tfr1
                WHERE uau1."AdminUnitID" = tfr1."AdminUnitID"
                AND TRIM(tfr1."FieldName") = TRIM(R.RDB$FIELD_NAME)
                and tfr1."TableServiceID" = :"TableServiceID"
                and UPPER(uau1."UserName") = UPPER(USER))
                and UPPER(uau1."UserName") = UPPER(USER)))
    THEN 2
    ELSE ((
        SELECT MAX(tfr."RightsLevel") AS "RightsLevel"
        FROM "tbl_TableFieldRight" tfr
        WHERE tfr."TableServiceID" = :"TableServiceID"
        AND TRIM(tfr."FieldName") = TRIM(R.RDB$FIELD_NAME)
        AND EXISTS(SELECT * FROM "tbl_UserAdminUnit" uau
                  WHERE uau."AdminUnitID" = tfr."AdminUnitID"
                  AND uau."UserName" = UPPER(USER)))
              )
    END AS "RightsLevel"
    FROM RDB$RELATION_FIELDS R
    WHERE (R.RDB$SYSTEM_FLAG = 0)
    AND (UPPER(TRIM(R.RDB$RELATION_NAME)) = :"TableName")
    INTO :"FieldName", :"RightsLevel"
    DO
    BEGIN
        "RightsLevel" = COALESCE(:"RightsLevel", :"RightsLevel", 2);
        SUSPEND;
    END
END
;
CREATE OR ALTER PROCEDURE "tsp_CreateGUID"
returns (
    "NewGUID" varchar(38))
as
DECLARE VARIABLE ID VARCHAR(38);
BEGIN
    "NewGUID" = '{' || UPPER(GUID_CREATE()) || '}';
    SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_CurUserTableGroupRoleList"
returns (
    "GroupName" varchar(128) character set unicode_fss,
    "SQLObjectName" varchar(31) character set unicode_fss,
    "Code" varchar(31) character set unicode_fss,
    "CanRead" integer,
    "CanInsert" integer,
    "CanUpdate" integer,
    "CanDelete" integer)
as
DECLARE VARIABLE ROOTID VARCHAR(38);
BEGIN
    SELECT FIRST 1
        tg_root."ID"
    FROM "tbl_TableGroup" tg_root
    WHERE tg_root."SQLObjectName" = 'TG'
    INTO :RootID;

    FOR SELECT
        tg_main."Name",
        tg_main."SQLObjectName",
        tg_main."Code",
        (CASE WHEN EXISTS(
            SELECT up_group.RDB$USER
            FROM RDB$USER_PRIVILEGES up_user, RDB$USER_PRIVILEGES up_group
            WHERE up_user.RDB$USER = USER
            AND up_group.RDB$RELATION_NAME = up_user.RDB$RELATION_NAME
            AND up_group.RDB$PRIVILEGE = up_user.RDB$PRIVILEGE
            AND up_group.RDB$USER = tg_main."SQLObjectName" || '_CR'
        ) THEN 1 ELSE 0
        END),
        (CASE WHEN EXISTS(
            SELECT up_group.RDB$USER
            FROM RDB$USER_PRIVILEGES up_user, RDB$USER_PRIVILEGES up_group
            WHERE up_user.RDB$USER = USER
            AND up_group.RDB$RELATION_NAME = up_user.RDB$RELATION_NAME
            AND up_group.RDB$PRIVILEGE = up_user.RDB$PRIVILEGE
            AND up_group.RDB$USER = tg_main."SQLObjectName" || '_CI'
        ) THEN 1 ELSE 0
        END),
        (CASE WHEN EXISTS(
            SELECT up_group.RDB$USER
            FROM RDB$USER_PRIVILEGES up_user, RDB$USER_PRIVILEGES up_group
            WHERE up_user.RDB$USER = USER
            AND up_group.RDB$RELATION_NAME = up_user.RDB$RELATION_NAME
            AND up_group.RDB$PRIVILEGE = up_user.RDB$PRIVILEGE
            AND up_group.RDB$USER = tg_main."SQLObjectName" || '_CU'
        ) THEN 1 ELSE 0
        END),
        (CASE WHEN EXISTS(
            SELECT up_group.RDB$USER
            FROM RDB$USER_PRIVILEGES up_user, RDB$USER_PRIVILEGES up_group
            WHERE up_user.RDB$USER = USER
            AND up_group.RDB$RELATION_NAME = up_user.RDB$RELATION_NAME
            AND up_group.RDB$PRIVILEGE = up_user.RDB$PRIVILEGE
            AND up_group.RDB$USER = tg_main."SQLObjectName" || '_CD'
        ) THEN 1 ELSE 0
        END)
    FROM "tbl_TableGroup" tg_main
    WHERE tg_main."ParentID" = :RootID
    INTO :"GroupName", :"SQLObjectName", :"Code", :"CanRead", :"CanInsert", :"CanUpdate", :"CanDelete"
    DO SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_GetCurrentUserInfo"
returns (
    "ID" varchar(38),
    "Name" varchar(250) character set unicode_fss,
    "ContactID" varchar(38),
    "ContactName" varchar(250) character set unicode_fss,
    "AccountName" varchar(250) character set unicode_fss)
as
DECLARE VARIABLE USERID VARCHAR(38);
DECLARE VARIABLE USERNAME VARCHAR(128) CHARACTER SET UNICODE_FSS;
DECLARE VARIABLE CONTACTUSERNAME VARCHAR(250) CHARACTER SET UNICODE_FSS;
DECLARE VARIABLE ACCOUNTCONTACTUSERNAME VARCHAR(250) CHARACTER SET UNICODE_FSS;
DECLARE VARIABLE USERCONTACTID VARCHAR(38);
DECLARE VARIABLE USERACCOUNTID VARCHAR(38);
BEGIN

    UserName = USER;

    SELECT FIRST 1
        u."ID",
        u."UserContactID"
    FROM "tbl_AdminUnit" u
    JOIN "tbl_Contact" c on c."ID" = u."UserContactID"
    WHERE u."SQLObjectName" = :UserName
    AND COALESCE(u."IsGroup", 0) = 0
    INTO :UserID, :UserContactID;

    SELECT FIRST 1
        "Name",
        "AccountID"
    FROM "tbl_Contact"
    WHERE "ID" = :UserContactID
    INTO :ContactUserName, :UserAccountID;
    

    SELECT FIRST 1
        "Name"
    FROM "tbl_Account"
    WHERE "ID" = :UserAccountID
    INTO :AccountContactUserName;
    

    "ID" = :UserID;
    "Name" = :UserName;
    "ContactID" = :UserContactID;
    "ContactName" = :ContactUserName;
    "AccountName" = :AccountContactUserName;
    SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_GetLoginInfo"(
    "AUserName" varchar(128) character set unicode_fss)
returns (
    "LoginDateTime" timestamp,
    "DatabaseID" varchar(38),
    "ParentDatabaseID" varchar(38),
    "DatabaseMajorVersion" integer,
    "DatabaseMinorVersion" integer,
    "DatabaseReleaseVersion" integer,
    "UseCache" integer,
    "ServiceModifiedOn" timestamp,
    "ServiceDeletedOn" timestamp,
    "ServerSessionsInfo" varchar(2000) character set unicode_fss,
    "UserID" varchar(38),
    "UserName" varchar(250) character set unicode_fss,
    "UserContactID" varchar(38),
    "ContactName" varchar(250) character set unicode_fss,
    "AccountID" varchar(38),
    "AccountName" varchar(250) character set unicode_fss,
    "UserIsEnabled" integer,
    "UserPasswordNeverExpired" integer,
    "UserPasswordChangedOn" timestamp,
    "UserIsAdmin" integer,
    "UserIsSysAdmin" integer,
    "GroupPasswordChangePeriodType" integer,
    "CustomerID" varchar(250))
as
BEGIN
    IF ((UPPER(USER) <> 'SYSDBA') AND (UPPER(:"AUserName") <> USER)) THEN
    BEGIN
        EXIT;
    END
    EXECUTE PROCEDURE "tsp_LoadUserAdminUnit" :"AUserName";
    /*
    ** Get Login Info.
    */
    "UserName" = :"AUserName";
    "LoginDateTime" = CURRENT_TIMESTAMP;

    SELECT
        "ID",
        "ParentID",
        "DatabaseMajorVersion",
        "DatabaseMinorVersion",
        "DatabaseReleaseVersion",
        "UseCache",
        "ServiceModifiedOn",
        "ServiceDeletedOn",
        "ServerSessionsInfo"
    FROM "tbl_DatabaseInfo"
    INTO
        :"DatabaseID",
        :"ParentDatabaseID",
        :"DatabaseMajorVersion",
        :"DatabaseMinorVersion",
        :"DatabaseReleaseVersion",
        :"UseCache",
        :"ServiceModifiedOn",
        :"ServiceDeletedOn",
        :"ServerSessionsInfo";

    SELECT
        "u"."ID",
        "u"."UserContactID",
        "u"."UserIsEnabled",
        "u"."UserPasswordNeverExpired",
        "u"."UserPasswordChangedOn",
        "u"."UserIsAdmin",
        "u"."UserIsSysAdmin",
        "c"."Name" as "ContactName",
        "a"."ID" as "AccountID",
        "a"."Name" as "AccountName"
    FROM "tbl_AdminUnit" "u"
    LEFT JOIN "tbl_Contact" "c" ON "c"."ID" = "u"."UserContactID"
    LEFT JOIN "tbl_Account" "a" ON "a"."ID" = "c"."AccountID"
    WHERE "u"."SQLObjectName" = :"UserName"
    AND COALESCE("u"."IsGroup", 0) = 0
    INTO :"UserID",
        :"UserContactID",
        :"UserIsEnabled",
        :"UserPasswordNeverExpired",
        :"UserPasswordChangedOn",
        :"UserIsAdmin",
        :"UserIsSysAdmin",
        :"ContactName",
        :"AccountID",
        :"AccountName";

    IF (COALESCE(:"UserPasswordNeverExpired",0) <> 1) THEN
    BEGIN
        SELECT 
           MAX(AdminUnit."GroupPasswordChangePeriodType")
        FROM "tbl_AdminUnit" AdminUnit
        WHERE (COALESCE(AdminUnit."IsGroup",0) = 1)
          AND (EXISTS (SELECT *
                FROM "tbl_UserAdminUnit" UserAdminUnit
                WHERE (UserAdminUnit."UserName" = :"UserName")
                AND (AdminUnit."ID" = UserAdminUnit."AdminUnitID")))
        INTO :"GroupPasswordChangePeriodType";
    END ELSE
    BEGIN
        "GroupPasswordChangePeriodType" = 5;
    END

    SELECT
        "StringValue"
    FROM "tbl_SystemSetting"
    WHERE "Code" = 'CustomerID'
    INTO :"CustomerID";
    
    SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_GrantAllForAdmins"(
    "ATableName" varchar(31))
as
DECLARE VARIABLE "AdminName" VARCHAR(31);
BEGIN
  FOR SELECT TRIM("SQLObjectName") FROM "tbl_AdminUnit"
  WHERE (COALESCE("UserIsAdmin", 0) = 1)
    AND (UPPER("SQLObjectName") <> 'SYSDBA')
  INTO :"AdminName"
  DO BEGIN
    EXECUTE STATEMENT 'GRANT ALL ON "' || :"ATableName" || '" TO "' || :"AdminName" ||'" WITH GRANT OPTION';
  END
END
;
CREATE OR ALTER PROCEDURE "tsp_GrantTableOperation"(
    "TableGroup" varchar(250) character set unicode_fss,
    "UserGroup" varchar(250) character set unicode_fss)
as
DECLARE VARIABLE USERGROUPID VARCHAR(38);
DECLARE VARIABLE TABLEGROUPID VARCHAR(38);
DECLARE VARIABLE "UserName" VARCHAR(250) CHARACTER SET UNICODE_FSS;
BEGIN
    --"UserGroup" = TRIM(:"UserGroup");
    --"TableGroup" = TRIM(:"TableGroup");

    SELECT "ID"
    FROM "tbl_AdminUnit"
    WHERE ("SQLObjectName" = :"UserGroup")
    INTO :UserGroupID;

    SELECT "ID"
    FROM "tbl_TableGroup"
    WHERE ("SQLObjectName" = :"TableGroup")
    INTO :TableGroupID;

    IF (NOT EXISTS(
        SELECT * FROM "tbl_TableGroup"
        WHERE ("ParentID" = :TableGroupID)
        AND ("SQLObjectName" = :"TableGroup")
        AND ("AdminUnitID" = :UserGroupID)
    )) THEN
    BEGIN
      INSERT INTO "tbl_TableGroup" ("ParentID", "Name", "SQLObjectName", "AdminUnitID")
      VALUES (:TableGroupID, :"UserGroup", :"UserGroup", :UserGroupID);
    END

    IF (EXISTS(
        SELECT au."ID" FROM "tbl_AdminUnit" au
        WHERE (COALESCE(au."IsGroup",0) = 0)
            AND (au."SQLObjectName" = :"UserGroup")
    )) THEN /* define rights for user */
    BEGIN
        INSERT INTO RDB$USER_PRIVILEGES (
          RDB$USER, RDB$GRANTOR, RDB$PRIVILEGE, RDB$GRANT_OPTION
          ,RDB$RELATION_NAME, RDB$FIELD_NAME, RDB$USER_TYPE, RDB$OBJECT_TYPE)
        SELECT     
          :"UserGroup", RDB$GRANTOR, RDB$PRIVILEGE, RDB$GRANT_OPTION
          ,RDB$RELATION_NAME, RDB$FIELD_NAME, 8, RDB$OBJECT_TYPE
        FROM RDB$USER_PRIVILEGES A
        WHERE (A.RDB$USER = :"TableGroup");
    END ELSE
    BEGIN /* define rights for group and all user in this group */
        IF (NOT EXISTS(SELECT *
            FROM RDB$USER_PRIVILEGES SOURCE, RDB$USER_PRIVILEGES DEST
            WHERE
                (SOURCE.RDB$USER = :"TableGroup")
            AND (DEST.RDB$USER = :"UserGroup")
            AND (COALESCE(SOURCE.RDB$GRANTOR,'') = COALESCE(DEST.RDB$GRANTOR,''))
            AND (COALESCE(SOURCE.RDB$PRIVILEGE,'') = COALESCE(DEST.RDB$PRIVILEGE,''))
            AND (COALESCE(SOURCE.RDB$GRANT_OPTION,0) = COALESCE(DEST.RDB$GRANT_OPTION,0))
            AND (COALESCE(SOURCE.RDB$RELATION_NAME,'') = COALESCE(DEST.RDB$RELATION_NAME,''))
            AND (COALESCE(SOURCE.RDB$FIELD_NAME,'') = COALESCE(DEST.RDB$FIELD_NAME,''))
            AND (COALESCE(SOURCE.RDB$USER_TYPE,0) = COALESCE(DEST.RDB$USER_TYPE,0))
            AND (COALESCE(SOURCE.RDB$OBJECT_TYPE,0) = COALESCE(DEST.RDB$OBJECT_TYPE,0))
        )) THEN
        BEGIN
            INSERT INTO RDB$USER_PRIVILEGES (
              RDB$USER, RDB$GRANTOR, RDB$PRIVILEGE, RDB$GRANT_OPTION
              ,RDB$RELATION_NAME, RDB$FIELD_NAME, RDB$USER_TYPE, RDB$OBJECT_TYPE)
            SELECT     
              :"UserGroup", RDB$GRANTOR, RDB$PRIVILEGE, RDB$GRANT_OPTION
              ,RDB$RELATION_NAME, RDB$FIELD_NAME, RDB$USER_TYPE, RDB$OBJECT_TYPE
            FROM RDB$USER_PRIVILEGES A
            WHERE (A.RDB$USER = :"TableGroup");
        END

        FOR SELECT DISTINCT UAU."UserName"
        FROM "tbl_UserAdminUnit" UAU
        WHERE (UAU."AdminUnitName" = :"UserGroup")
            AND (UAU."UserName" <> 'SYSDBA')
        INTO :"UserName"
        DO BEGIN
            IF (NOT EXISTS(SELECT *
                FROM RDB$USER_PRIVILEGES SOURCE, RDB$USER_PRIVILEGES DEST
                WHERE
                    (SOURCE.RDB$USER = :"TableGroup")
                AND (DEST.RDB$USER = :"UserName")
                AND (COALESCE(SOURCE.RDB$GRANTOR,'') = COALESCE(DEST.RDB$GRANTOR,''))
                AND (COALESCE(SOURCE.RDB$PRIVILEGE,'') = COALESCE(DEST.RDB$PRIVILEGE,''))
                AND (COALESCE(SOURCE.RDB$GRANT_OPTION,0) = COALESCE(DEST.RDB$GRANT_OPTION,0))
                AND (COALESCE(SOURCE.RDB$RELATION_NAME,'') = COALESCE(DEST.RDB$RELATION_NAME,''))
                AND (COALESCE(SOURCE.RDB$FIELD_NAME,'') = COALESCE(DEST.RDB$FIELD_NAME,''))
                AND (COALESCE(SOURCE.RDB$USER_TYPE,0) = COALESCE(DEST.RDB$USER_TYPE,0))
                AND (COALESCE(SOURCE.RDB$OBJECT_TYPE,0) = COALESCE(DEST.RDB$OBJECT_TYPE,0))
            )) THEN
            BEGIN
                INSERT INTO RDB$USER_PRIVILEGES (
                  RDB$USER, RDB$GRANTOR, RDB$PRIVILEGE, RDB$GRANT_OPTION
                  ,RDB$RELATION_NAME, RDB$FIELD_NAME, RDB$USER_TYPE, RDB$OBJECT_TYPE)
                SELECT     
                  :"UserName", RDB$GRANTOR, RDB$PRIVILEGE, RDB$GRANT_OPTION
                  ,RDB$RELATION_NAME, RDB$FIELD_NAME, 8, RDB$OBJECT_TYPE
                FROM RDB$USER_PRIVILEGES A
                WHERE (A.RDB$USER = :"TableGroup");
            END
        END
    END
END
;
CREATE OR ALTER PROCEDURE "tsp_LoadUserAdminUnit"(
    "AUserName" varchar(128) character set unicode_fss = '',
    "AGroupID" varchar(38) = '',
    "Step" integer = 1)
as
DECLARE VARIABLE "GroupID" VARCHAR(38);
DECLARE VARIABLE "GroupParentID" VARCHAR(38);
DECLARE VARIABLE "GroupName" VARCHAR(256);
DECLARE VARIABLE "UserName" VARCHAR(256);
DECLARE VARIABLE "Count" INTEGER;
BEGIN
   /*
   ** use in tsp_UpdateUserRights
   */

    "AUserName" = UPPER(TRIM(:"AUserName"));
    IF (COALESCE(:"Step",0) = 1) THEN
    BEGIN
        IF (:"AUserName" <> '') THEN
        BEGIN
            SELECT COUNT(AU."ID") FROM "tbl_AdminUnit" AU
            WHERE UPPER(AU."Name") = :"AUserName"
            INTO :"Count";

            IF (:"Count" = 0) THEN
            BEGIN
                EXIT;
            END
            DELETE FROM "tbl_UserAdminUnit" uau
            WHERE UPPER(UAU."UserName") = :"AUserName";

            EXECUTE PROCEDURE "tsp_LoadUserAdminUnit" :"AUserName", '', 2;
        END ELSE
        BEGIN
            DELETE FROM "tbl_UserAdminUnit";
    
            FOR SELECT TRIM("Name") FROM "tbl_AdminUnit"
            WHERE COALESCE("IsGroup",0) = 0
            INTO :"UserName"
            DO BEGIN
                EXECUTE PROCEDURE "tsp_LoadUserAdminUnit" :"UserName", '', 2;
            END
        END
        EXIT;
    END

    IF (COALESCE(:"Step",0) = 2) THEN
    BEGIN
        INSERT INTO "tbl_UserAdminUnit" (
            "AdminUnitID",
            "AdminUnitName",
            "UserName")
        VALUES (
            (SELECT FIRST 1 "ID" FROM "tbl_AdminUnit" AU WHERE UPPER(AU."Name") = :"AUserName"),
            :"AUserName",
            :"AUserName");

        FOR SELECT UP.RDB$RELATION_NAME, AU."ID", AU."GroupParentID" FROM RDB$USER_PRIVILEGES UP
        INNER JOIN "tbl_AdminUnit" AU ON UPPER(AU."SQLObjectName") = UPPER(UP.RDB$RELATION_NAME)
        WHERE UP.RDB$PRIVILEGE = 'M'
        AND UPPER(UP.RDB$USER) = UPPER(:"AUserName")
        INTO :"GroupName", :"GroupID", :"GroupParentID"
        DO BEGIN
            INSERT INTO "tbl_UserAdminUnit" (
                "AdminUnitID",
                "AdminUnitName",
                "UserName")
            VALUES (
                :"GroupID",
                UPPER(:"GroupName"),
                UPPER(:"AUserName"));
            IF (:"GroupParentID" IS NOT NULL) THEN
            BEGIN
                EXECUTE PROCEDURE "tsp_LoadUserAdminUnit" :"AUserName", :"GroupParentID", 3;
            END
        END
        EXIT;
    END

    IF (COALESCE(:"Step",0) = 3) THEN
    BEGIN
        FOR SELECT g."SQLObjectName", g."ID", g."GroupParentID"  FROM "tbl_AdminUnit" g
        WHERE g."ID" = :"AGroupID" AND g."IsGroup" = 1
        INTO :"GroupName", :"GroupID", :"GroupParentID"
        DO BEGIN
            INSERT INTO "tbl_UserAdminUnit" (
                "AdminUnitID",
                "AdminUnitName",
                "UserName")
            VALUES (
                :"GroupID",
                UPPER(:"GroupName"),
                UPPER(:"AUserName"));
            IF (:"GroupParentID" IS NOT NULL) THEN
            BEGIN
                EXECUTE PROCEDURE "tsp_LoadUserAdminUnit" :"AUserName", :"GroupParentID", 3;
            END
         END
         EXIT;
    END
END
;
CREATE OR ALTER PROCEDURE "tsp_LogTrigger"(
    "ATableName" varchar(31),
    "TrackFieldsInfo" varchar(8000),
    "TrackFieldsInfoForDelete" varchar(8000),
    "AEnabled" integer = 1)
as
DECLARE VARIABLE "TableName" VARCHAR(31);
  DECLARE VARIABLE "ShortTableName" VARCHAR(31);
  DECLARE VARIABLE "TableLogName" VARCHAR(31);
  DECLARE VARIABLE "ShortTableLogName" VARCHAR(31);
  DECLARE VARIABLE "InsertTriggerName" VARCHAR(31);
  DECLARE VARIABLE "UpdateTriggerName" VARCHAR(31);
  DECLARE VARIABLE "DeleteTriggerName" VARCHAR(31);
  DECLARE VARIABLE "BeforeInsertTriggerName" VARCHAR(31);
  DECLARE VARIABLE "Column" VARCHAR(1000);
  DECLARE VARIABLE "CheckReplication" VARCHAR(250);
  DECLARE VARIABLE "DisplayColumn" VARCHAR(33);
  DECLARE VARIABLE "JoinTable" VARCHAR(33);
  DECLARE VARIABLE "JoinField" VARCHAR(33);
  DECLARE VARIABLE "RecordTitle" VARCHAR(40);
  DECLARE VARIABLE "RecordTitleEx" VARCHAR(40);
  DECLARE VARIABLE "TableID" VARCHAR(38);
  DECLARE VARIABLE "DatabaseLogBegin" VARCHAR(1000);
  DECLARE VARIABLE "ContactID" VARCHAR(200);
  DECLARE VARIABLE "InsertTableLogBegin" VARCHAR(10000);
  DECLARE VARIABLE "InsertTableLog" VARCHAR(10000);
  DECLARE VARIABLE "InsertTableLogEnd" VARCHAR(10000);
  DECLARE VARIABLE "PosIndex" INT;
  DECLARE VARIABLE "EmptyValue" VARCHAR(10);
  DECLARE VARIABLE "Coma" VARCHAR(100);
  DECLARE VARIABLE "CheckChanges" VARCHAR(10000);
  DECLARE VARIABLE "FieldType" INT;
  DECLARE VARIABLE "JoinTables" VARCHAR(10000);
BEGIN
---------------- clear old triggers -----------------

  select "ObjectName" from "tsp_TruncObjectName"(:"ATableName", 24)
  into :"ShortTableName";

  "TableName" = '"' || "ATableName" || '"';
  "InsertTriggerName" = 'tr_' || "ShortTableName" || '_AIL';
  "UpdateTriggerName" = 'tr_' || "ShortTableName" || '_AUL';
  "DeleteTriggerName" = 'tr_' || "ShortTableName" || '_ADL';
  
  IF (EXISTS(
    SELECT * FROM RDB$TRIGGERS
    WHERE (RDB$TRIGGER_NAME = :"InsertTriggerName"))) THEN
  BEGIN
    EXECUTE STATEMENT 'DROP TRIGGER "' || :"InsertTriggerName" || '"';
  END

  IF (EXISTS(
    SELECT * FROM RDB$TRIGGERS
    WHERE (RDB$TRIGGER_NAME = :"UpdateTriggerName"))) THEN
  BEGIN
    EXECUTE STATEMENT 'DROP TRIGGER "' || :"UpdateTriggerName" || '"';
  END

  IF (EXISTS(
    SELECT * FROM RDB$TRIGGERS
    WHERE (RDB$TRIGGER_NAME = :"DeleteTriggerName"))) THEN
  BEGIN
    EXECUTE STATEMENT 'DROP TRIGGER "' || :"DeleteTriggerName" || '"';
  END

  IF (COALESCE(:"AEnabled", 0) = 0) THEN
  BEGIN
    EXIT;
  END

---------------- initialization ---------------------
  "TableLogName" = "ATableName" || 'Log';
  "CheckReplication" = 'IF (USER = ''TS_REPLICATION'') THEN BEGIN EXIT; END';
  
  SELECT TRIM("ID") FROM "tbl_Service" "S"
  WHERE "S"."Code" = :"ATableName"
  INTO :"TableID";
  
  SELECT FIRST 1 "Part" FROM "tsp_ParseString"(:"TrackFieldsInfo", ';')
  INTO :"Column";

  "RecordTitleEx" = '''''';
  IF ((:"Column" IS NOT NULL) AND (:"Column" <> '') AND (:"Column" <> '...')) THEN
  BEGIN
    "RecordTitle" = '"' || :"Column" || '"';
  END ELSE
  BEGIN
    "RecordTitle" = "RecordTitleEx";
  END
     
  "ContactID" = '
  
  SELECT AU."UserContactID" FROM "tbl_AdminUnit" AU
  WHERE AU."SQLObjectName" = USER
  INTO :"ContactID"; ';

  "DatabaseLogBegin" = '
  INSERT INTO "tbl_DatabaseLog" (
    "TableID"
    ,"RecordID"
    ,"RecordTitle"
    ,"ActionID"
    ,"CreatedOn"
    ,"CreatedByID"
  ) ';

  "InsertTableLogBegin" = '
  
  INSERT INTO "' || "TableLogName" || '" (
    "RecordID"
    ,"ActionID"
    ,"CreatedOn"
    ,"CreatedByID"';

------------ instead of update ----------------------
  "InsertTableLog" = "InsertTableLogBegin";
  "Column" = '';
  FOR
    SELECT SKIP(1) "Part" FROM "tsp_ParseString"(:"TrackFieldsInfo", ';')
  INTO :"Column" DO
  BEGIN
    SELECT pos FROM "Pos"(',', :"Column")
    INTO :"PosIndex";
    IF (:"PosIndex" > 0) THEN
    BEGIN
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 2 TO 2
      INTO :"DisplayColumn";   
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 1 TO 1
      INTO :"Column";

      "InsertTableLog" = "InsertTableLog" || '
    ,"' || :"DisplayColumn" || '"';
    END 
    "InsertTableLog" = "InsertTableLog" || '
    ,"' || :"Column" || '"';
  END

  "InsertTableLog" = "InsertTableLog" || ')
  VALUES(
    "OLD"."ID"
    ,''U''
    ,CURRENT_TIMESTAMP
    ,:"ContactID"';

  "JoinTables" = '';

  FOR
    SELECT SKIP(1) "Part" from "tsp_ParseString"(:"TrackFieldsInfo", ';')
  INTO :"Column" DO
  BEGIN
    SELECT POS FROM "Pos"(',', :"Column")
    INTO :"PosIndex";
    IF (:"PosIndex" > 0) THEN
    BEGIN
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 2 TO 2
      INTO :"DisplayColumn";
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 3 TO 3
      INTO :"JoinTable";
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 4 TO 4
      INTO :"JoinField";
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 1 TO 1
      INTO :"Column";

      "InsertTableLog" = "InsertTableLog" || '
    ,(SELECT "' || "JoinTable" || '"."' || "JoinField" || '"
      FROM "' || "JoinTable" || '" AS "' || "JoinTable" || '"
      WHERE  "' || "JoinTable" || '"."ID" = "OLD"."' || "Column" || '")';

      "JoinTables" = "JoinTables" || "JoinTable" || ';';
    END

    "InsertTableLog" = "InsertTableLog" || '
    ,"OLD"."' || "Column" || '"';
  END

  "InsertTableLog" = "InsertTableLog" || ');
  ';

  "CheckChanges" = '
  if (not (';

  "Coma" = '';
  FOR
    SELECT SKIP(1) "Part" from "tsp_ParseString"(:"TrackFieldsInfo", ';')
  INTO :"Column" DO
  BEGIN
    SELECT POS FROM "Pos"(',', :"Column")
    INTO :"PosIndex";
    IF (:"PosIndex" > 0) THEN
    BEGIN
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 1 TO 1
      INTO :"Column";
    END

    select f.rdb$field_type from rdb$fields f
    inner join  RDB$RELATION_FIELDS rf on f.rdb$field_name = rf.rdb$field_source
    and rf.rdb$relation_name = :"ATableName"
    and rf.rdb$field_name = :"Column"
    into :"FieldType";

    if ("FieldType" = 261) then
    begin
      "CheckChanges" = "CheckChanges" || "Coma" ||
      '(("NEW"."' || "Column" || '" <> "OLD"."' || "Column" || '")' || '
      AND ("NEW"."' || "Column" || '" IS NOT NULL) AND ("OLD"."' || "Column" || '" IS NOT NULL)) OR ' || '
    (("NEW"."' || "Column" || '" IS NULL) AND ("OLD"."' || "Column" || '" IS NOT NULL)) OR ' || '
    (("NEW"."' || "Column" || '" IS NOT NULL) AND ("OLD"."' || "Column" || '" IS NULL))';
    end else
    begin
      if (("FieldType" = 37) OR ("FieldType" = 35)) then
      begin
        "EmptyValue" = '''''';
      end else
      begin
        "EmptyValue" = '0';
      end
      "CheckChanges" = "CheckChanges" || "Coma" ||
      '(COALESCE("NEW"."' || "Column" || '",' || "EmptyValue" || ') <> ' ||
      'COALESCE("OLD"."' || "Column" || '",' || "EmptyValue" || '))';
    end

    IF ("Coma" = '') THEN "Coma" = "Coma" || ' OR
    ';
  END

  "CheckChanges" = "CheckChanges" || ')) then
  begin
    exit;
  end';

  IF ("RecordTitle" <> "RecordTitleEx") THEN
  BEGIN
    "RecordTitleEx" = '"OLD".' || "RecordTitle";
  END

  EXECUTE STATEMENT
'RECREATE TRIGGER "' || :"UpdateTriggerName" || '"
FOR "' || :"ATableName" || '"
ACTIVE AFTER UPDATE POSITION 0
AS
DECLARE VARIABLE "ContactID" VARCHAR(38);
BEGIN ' ||
    :"CheckChanges" ||
    :"ContactID" ||
    :"InsertTableLog" ||
    :"DatabaseLogBegin" || '
  VALUES(
    ''' || :"TableID" || '''
    ,"OLD"."ID"
    ,' || :"RecordTitleEx" || '
    ,''U''
    ,CURRENT_TIMESTAMP
    ,:"ContactID");
END';

  EXECUTE STATEMENT 'GRANT INSERT ON "' || :"TableLogName" || '" TO TRIGGER"' || :"UpdateTriggerName" || '"';

  FOR
    SELECT "Part" from "tsp_ParseString"(:"JoinTables", ';')
  INTO :"JoinTable" DO
  BEGIN
    EXECUTE STATEMENT 'GRANT SELECT ON "' || :"JoinTable" || '" TO TRIGGER"' || :"UpdateTriggerName" || '"';
  END

------------ instead of delete ----------------------

  "InsertTableLog" = "InsertTableLogBegin";
  "Column" = '';
  FOR
    SELECT "Part" FROM "tsp_ParseString"(:"TrackFieldsInfoForDelete", ';')
  INTO :"Column" DO
  BEGIN
    SELECT pos FROM "Pos"(',', :"Column")
    INTO :"PosIndex";
    IF (:"PosIndex" > 0) THEN
    BEGIN
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 2 TO 2
      INTO :"DisplayColumn";   
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 1 TO 1
      INTO :"Column";

      "InsertTableLog" = "InsertTableLog" || '
    ,"' || :"DisplayColumn" || '"';
    END 
    "InsertTableLog" = "InsertTableLog" || '
    ,"' || :"Column" || '"';
  END

  "InsertTableLog" = "InsertTableLog" || ')
  VALUES(
    "OLD"."ID"' || '
    ,''D''
    ,CURRENT_TIMESTAMP
    ,:"ContactID"';

  "JoinTables" = '';
  FOR
    SELECT "Part" from "tsp_ParseString"(:"TrackFieldsInfoForDelete", ';')
  INTO :"Column" DO
  BEGIN
    SELECT POS FROM "Pos"(',', :"Column")
    INTO :"PosIndex";
    IF (:"PosIndex" > 0) THEN
    BEGIN
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 2 TO 2
      INTO :"DisplayColumn";
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 3 TO 3
      INTO :"JoinTable";
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 4 TO 4
      INTO :"JoinField";
      SELECT "Part" FROM "tsp_ParseString"(:"Column", ',') ROWS 1 TO 1
      INTO :"Column";

      "InsertTableLog" = "InsertTableLog" || '
    ,(SELECT "' || "JoinTable" || '"."' || "JoinField" || '"
      FROM "' || "JoinTable" || '" AS "' || "JoinTable" || '"
      WHERE  "' || "JoinTable" || '"."ID" = "OLD"."' || "Column" || '")';
      "JoinTables" = "JoinTables" || "JoinTable" || ';';
    END

    "InsertTableLog" = "InsertTableLog" || '
    ,"OLD"."' || "Column" || '"';
  END

  "InsertTableLog" = "InsertTableLog" || ');
  ';

EXECUTE STATEMENT
'RECREATE TRIGGER "' || :"DeleteTriggerName" ||'"
FOR "' || :"ATableName" || '"
ACTIVE AFTER DELETE POSITION 0
AS
DECLARE VARIABLE "ContactID" VARCHAR(38);
BEGIN ' ||
    :"ContactID" ||
    :"InsertTableLog" ||
    :"DatabaseLogBegin" || '
  VALUES(
    ''' || :"TableID" || '''
    ,"OLD"."ID"
    ,' || :"RecordTitleEx" || '
    ,''D''
    ,CURRENT_TIMESTAMP
    ,:"ContactID");
END';

  EXECUTE STATEMENT 'GRANT INSERT ON "' || :"TableLogName" || '" TO TRIGGER"' || :"DeleteTriggerName" ||'"';

  FOR
    SELECT "Part" from "tsp_ParseString"(:"JoinTables", ';')
  INTO :"JoinTable" DO
  BEGIN
    EXECUTE STATEMENT 'GRANT SELECT ON "' || :"JoinTable" || '" TO TRIGGER"' || :"DeleteTriggerName" || '"';
  END

------------------ after insert ----------------------

  IF ("RecordTitle" <> "RecordTitleEx") THEN
  BEGIN
    "RecordTitleEx" = '"NEW".' || "RecordTitle";
  END

EXECUTE STATEMENT
'RECREATE TRIGGER "' || :"InsertTriggerName" ||'"
FOR "' || :"ATableName" || '"
ACTIVE AFTER INSERT POSITION 0
AS
DECLARE VARIABLE "ContactID" VARCHAR(38);
BEGIN
' ||
    :"ContactID" ||
    :"DatabaseLogBegin" || '
  VALUES (
    ''' || :"TableID" || '''
    ,"NEW"."ID"
    ,' || :"RecordTitleEx" || '
    ,''I''
    ,CURRENT_TIMESTAMP
    ,:"ContactID");
END';
  
END
;
CREATE OR ALTER PROCEDURE "tsp_ParseString"(
    "ParseString" varchar(8000),
    "Delimiter" varchar(100))
returns (
    "Part" varchar(8000))
as
DECLARE VARIABLE "Index" INT;
BEGIN
  WHILE ("ParseString" > '') DO
  BEGIN
    SELECT POS FROM "Pos"(:"Delimiter", :"ParseString")
    INTO :"Index";
    IF ("Index" > 0) THEN
    BEGIN
      "Part" = SUBSTRING(:"ParseString" FROM 1 FOR :"Index" -1);
      SUSPEND;
      "ParseString" = SUBSTRING(:"ParseString" FROM :"Index" +1 FOR CHAR_LENGTH(:"ParseString"));
    END ELSE
    BEGIN
      "Part" = SUBSTRING(:"ParseString" FROM 1 FOR CHAR_LENGTH(:"ParseString"));
      SUSPEND;
      BREAK;
    END
  END
END
;
CREATE OR ALTER PROCEDURE "tsp_RevokeTableOperation"(
    "TableGroup" varchar(250) character set unicode_fss,
    "UserGroup" varchar(250) character set unicode_fss)
as
DECLARE VARIABLE USERGROUPID VARCHAR(38);
DECLARE VARIABLE TABLEGROUPID VARCHAR(38);
DECLARE VARIABLE GRANTOR VARCHAR(31);
DECLARE VARIABLE PRIVILEGE VARCHAR(6);
DECLARE VARIABLE GRANT_OPTION SMALLINT;
DECLARE VARIABLE RELATION_NAME VARCHAR(31);
DECLARE VARIABLE FIELD_NAME VARCHAR(31);
DECLARE VARIABLE USER_TYPE SMALLINT;
DECLARE VARIABLE OBJECT_TYPE SMALLINT;
DECLARE VARIABLE "UserName" VARCHAR(250) CHARACTER SET UNICODE_FSS;
BEGIN
    "UserGroup" = TRIM(:"UserGroup");
    "TableGroup" = TRIM(:"TableGroup");

    SELECT "ID"
    FROM "tbl_AdminUnit"
    WHERE ("SQLObjectName" = :"UserGroup")
    INTO :UserGroupID;

    SELECT "ID"
    FROM "tbl_TableGroup"
    WHERE ("SQLObjectName" = :"TableGroup")
    INTO :TableGroupID;

    DELETE FROM "tbl_TableGroup"
    WHERE ("ParentID" = :TableGroupID)
    AND ("SQLObjectName" = :"UserGroup")
    AND ("AdminUnitID" = :UserGroupID);

    FOR SELECT
        TRIM(RDB$GRANTOR), TRIM(RDB$PRIVILEGE), RDB$GRANT_OPTION,
        TRIM(RDB$RELATION_NAME), TRIM(RDB$FIELD_NAME),
        RDB$USER_TYPE, RDB$OBJECT_TYPE
    FROM RDB$USER_PRIVILEGES
    WHERE (RDB$USER = :"TableGroup")
    INTO :GRANTOR, :PRIVILEGE, :GRANT_OPTION, :RELATION_NAME,
     :FIELD_NAME, :USER_TYPE, :OBJECT_TYPE
    DO BEGIN
        DELETE
        FROM RDB$USER_PRIVILEGES
        WHERE (RDB$USER = :"UserGroup")
            AND (COALESCE(RDB$GRANTOR,'') = COALESCE(:GRANTOR,''))
            AND (COALESCE(RDB$PRIVILEGE,'') = COALESCE(:PRIVILEGE,''))
            AND (COALESCE(RDB$GRANT_OPTION,0) = COALESCE(:GRANT_OPTION,0))
            AND (COALESCE(RDB$RELATION_NAME,'') = COALESCE(:RELATION_NAME,''))
            AND (COALESCE(RDB$FIELD_NAME,'') = COALESCE(:FIELD_NAME,''))
            AND (COALESCE(RDB$USER_TYPE,0) = COALESCE(:USER_TYPE,0))
            AND (COALESCE(RDB$OBJECT_TYPE,0) = COALESCE(:OBJECT_TYPE,0));
    END
    
    FOR SELECT DISTINCT TRIM(UAU."UserName")
    FROM "tbl_UserAdminUnit" UAU
    WHERE (UAU."AdminUnitName" = :"UserGroup")
    INTO :"UserName"
    DO BEGIN
        EXECUTE PROCEDURE "tsp_UpdateUserRights" :"UserName";
    END
END
;
CREATE OR ALTER PROCEDURE "tsp_SetUserPassword"(
    "AUSERNAME" varchar(31) character set unicode_fss,
    "AUSERPASSWORD" varchar(100) character set unicode_fss)
as
DECLARE VARIABLE CANUPDATE INTEGER;
DECLARE VARIABLE USERISSYSADMIN INTEGER;
BEGIN
    /*
    ** Set User Password.
    */
    IF ((AUserName = USER) OR (USER = 'SYSDBA')) THEN
    BEGIN
        CanUpdate = 1;
    END ELSE
    BEGIN
        CanUpdate = 0;
    END
    IF (CanUpdate = 1) THEN
    BEGIN
        UPDATE "tbl_AdminUnit"
        SET "UserPasswordChangedOn" = CURRENT_TIMESTAMP
        WHERE "SQLObjectName" = :AUserName;
    END
END
;
CREATE OR ALTER PROCEDURE "tsp_TableGroupRoleList"
returns (
    "GroupName" varchar(128) character set unicode_fss,
    "SQLObjectName" varchar(31) character set unicode_fss)
as
BEGIN
    FOR SELECT
        tg."Name",
        tg."SQLObjectName"
    FROM "tbl_TableGroup" tg
    WHERE tg."ParentID" = (
        SELECT FIRST 1
            tg_root."ID"
        FROM "tbl_TableGroup" tg_root
        WHERE tg_root."SQLObjectName" = 'TG'
    )
    INTO :"GroupName", :"SQLObjectName"
    DO SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_TruncObjectName"(
    "AObjectName" varchar(1000),
    "AMaxLength" integer,
    "AObjectType" varchar(100) = 'Table')
returns (
    "ObjectName" varchar(100))
as
DECLARE VARIABLE "CurLength" INTEGER;
DECLARE VARIABLE i INTEGER;
DECLARE VARIABLE cnt INTEGER;
BEGIN
  "CurLength" = CHAR_LENGTH(:"AObjectName");
  IF ("CurLength" <= "AMaxLength") THEN
  BEGIN
    "ObjectName" = "AObjectName";
    SUSPEND;
    EXIT;
  END
  
  cnt = 1;
  i = 0;
  WHILE (cnt > 0) DO
  BEGIN
    i = i + 1;
    "CurLength" = "AMaxLength" - 1 -
      CHAR_LENGTH(TRIM(CAST(i AS VARCHAR(10))));
    "ObjectName" = SUBSTRING(:"AObjectName" FROM 1 FOR :"CurLength") || '~' ||
      TRIM(CAST(i AS VARCHAR(10)));

    if ("AObjectType" = 'Table') then
    begin
      SELECT COUNT(*) FROM RDB$RELATIONS
      WHERE (RDB$VIEW_SOURCE IS NULL)
      AND (RDB$SYSTEM_FLAG = 0)
      AND (UPPER(RDB$RELATION_NAME) = UPPER(:"ObjectName"))
      INTO cnt;
    end else
    if ("AObjectType" = 'View') then
    begin
      SELECT COUNT(*) FROM RDB$RELATIONS
      WHERE (NOT RDB$VIEW_SOURCE IS NULL)
      AND (RDB$SYSTEM_FLAG = 0)
      AND (UPPER(RDB$RELATION_NAME) = UPPER(:"ObjectName"))
      INTO cnt;
    end
  END
  SUSPEND;
END
;
CREATE OR ALTER PROCEDURE "tsp_UpdateRights"(
    "ViewName" varchar(31))
as
DECLARE VARIABLE "TableGroup" VARCHAR(250) CHARACTER SET UNICODE_FSS;
  DECLARE VARIABLE "UserID" VARCHAR(38);
  DECLARE VARIABLE "UserName" VARCHAR(31) CHARACTER SET UNICODE_FSS;
  DECLARE VARIABLE "GroupID" VARCHAR(38);
  DECLARE VARIABLE "GroupName" VARCHAR(31) CHARACTER SET UNICODE_FSS;
  DECLARE VARIABLE "UserIsAdmin" INTEGER;
BEGIN
  /*
  ** use to update all real users and user's groups rights for view "ViewName"
  */

  -- Load all user admin unit
  EXECUTE PROCEDURE "tsp_LoadUserAdminUnit";

  -- Update rights for user's groups
  FOR SELECT TRIM("SQLObjectName") FROM "tbl_AdminUnit"
  WHERE (COALESCE("IsGroup",0) = 1) AND (TRIM("SQLObjectName") <> '')
  INTO :"GroupName"
  DO BEGIN
    DELETE FROM RDB$USER_PRIVILEGES UP
    WHERE (UP.RDB$USER = :"GroupName") AND (UP.RDB$PRIVILEGE <> 'M')
      AND (UP.RDB$RELATION_NAME = :"ViewName");

    SELECT "ID" FROM "tbl_AdminUnit"
    WHERE (UPPER("SQLObjectName") = :"GroupName")
    INTO :"GroupID";

    FOR SELECT UPPER(TGP."SQLObjectName")
    FROM "tbl_TableGroup" TGP
    INNER JOIN "tbl_TableGroup" TG ON (TG."ParentID" = TGP."ID")
      AND (TG."AdminUnitID" = :"GroupID")
    INTO :"TableGroup"
    DO BEGIN
      INSERT INTO RDB$USER_PRIVILEGES (
        RDB$USER
        ,RDB$GRANTOR
        ,RDB$PRIVILEGE
        ,RDB$GRANT_OPTION
        ,RDB$RELATION_NAME
        ,RDB$FIELD_NAME
        ,RDB$USER_TYPE
        ,RDB$OBJECT_TYPE)
      SELECT
        :"GroupName"
        ,RDB$GRANTOR
        ,RDB$PRIVILEGE
        ,RDB$GRANT_OPTION
        ,RDB$RELATION_NAME
        ,RDB$FIELD_NAME
        ,13
        ,RDB$OBJECT_TYPE
      FROM RDB$USER_PRIVILEGES A
      WHERE (A.RDB$USER = :"TableGroup")
        AND (A.RDB$RELATION_NAME = :"ViewName");
    END
  END

  -- Update rights for users
  FOR SELECT TRIM("SQLObjectName") FROM "tbl_AdminUnit"
  WHERE (COALESCE("IsGroup",0) = 0)
    AND (TRIM("SQLObjectName") <> '')
    AND (TRIM("SQLObjectName") <> 'SYSDBA')
  INTO :"UserName"
  DO BEGIN
    DELETE FROM RDB$USER_PRIVILEGES UP
    WHERE (UP.RDB$USER = :"UserName") AND (UP.RDB$PRIVILEGE <> 'M')
      AND (UP.RDB$RELATION_NAME = :"ViewName");

    SELECT COALESCE("UserIsAdmin",0) FROM "tbl_AdminUnit"
    WHERE (COALESCE("IsGroup",0) = 0)
        AND (UPPER("SQLObjectName") = :"UserName")
    INTO :"UserIsAdmin";

    IF (:"UserIsAdmin" = 1) THEN
    BEGIN
      INSERT INTO RDB$USER_PRIVILEGES (
        RDB$USER
        ,RDB$GRANTOR
        ,RDB$PRIVILEGE
        ,RDB$GRANT_OPTION
        ,RDB$RELATION_NAME
        ,RDB$FIELD_NAME
        ,RDB$USER_TYPE
        ,RDB$OBJECT_TYPE)
      SELECT
        :"UserName"
        ,RDB$GRANTOR
        ,RDB$PRIVILEGE
        ,RDB$GRANT_OPTION
        ,RDB$RELATION_NAME
        ,RDB$FIELD_NAME
        ,8
        ,RDB$OBJECT_TYPE
      FROM RDB$USER_PRIVILEGES A
      WHERE (A.RDB$USER = 'SYSDBA')
        AND (A.RDB$RELATION_NAME = :"ViewName");
    END ELSE
    BEGIN
      FOR SELECT DISTINCT TRIM(UAU."AdminUnitName")
      FROM "tbl_UserAdminUnit" UAU
      WHERE (UPPER(UAU."UserName") = :"UserName")
        AND (UPPER(UAU."UserName") <> UPPER(UAU."AdminUnitName"))
      INTO :"TableGroup"
      DO BEGIN
        INSERT INTO RDB$USER_PRIVILEGES (
          RDB$USER
          ,RDB$GRANTOR
          ,RDB$PRIVILEGE
          ,RDB$GRANT_OPTION
          ,RDB$RELATION_NAME
          ,RDB$FIELD_NAME
          ,RDB$USER_TYPE
          ,RDB$OBJECT_TYPE)
        SELECT
          :"UserName"
          ,RDB$GRANTOR
          ,RDB$PRIVILEGE
          ,RDB$GRANT_OPTION
          ,RDB$RELATION_NAME
          ,RDB$FIELD_NAME
          ,8
          ,RDB$OBJECT_TYPE
        FROM RDB$USER_PRIVILEGES A
        WHERE (A.RDB$USER = :"TableGroup")
          AND (A.RDB$RELATION_NAME = :"ViewName");
      END
  
      SELECT "ID" FROM "tbl_AdminUnit"
      WHERE (UPPER("SQLObjectName") = :"UserName")
      INTO :"UserID";
  
      FOR SELECT UPPER(TGP."SQLObjectName")
      FROM "tbl_TableGroup" TGP
      INNER JOIN "tbl_TableGroup" TG ON (TG."ParentID" = TGP."ID")
        AND (TG."AdminUnitID" = :"UserID")
      INTO :"TableGroup"
      DO BEGIN
        INSERT INTO RDB$USER_PRIVILEGES (
          RDB$USER
          ,RDB$GRANTOR
          ,RDB$PRIVILEGE
          ,RDB$GRANT_OPTION
          ,RDB$RELATION_NAME
          ,RDB$FIELD_NAME
          ,RDB$USER_TYPE
          ,RDB$OBJECT_TYPE)
        SELECT
          :"UserName"
          ,RDB$GRANTOR
          ,RDB$PRIVILEGE
          ,RDB$GRANT_OPTION
          ,RDB$RELATION_NAME
          ,RDB$FIELD_NAME
          ,8
          ,RDB$OBJECT_TYPE
        FROM RDB$USER_PRIVILEGES A
        WHERE (A.RDB$USER = :"TableGroup")
          AND (A.RDB$RELATION_NAME = :"ViewName");
      END
    END
  END
END
;
CREATE OR ALTER PROCEDURE "tsp_UpdateUserRights"(
    "UserName" varchar(31) character set unicode_fss = '',
    "UpdateUserAdminUnit" integer = 1,
    "UserIsAdmin" integer = NULL)
as
DECLARE VARIABLE "TableGroup" VARCHAR(250) CHARACTER SET UNICODE_FSS;
DECLARE VARIABLE "UserID" VARCHAR(38);
BEGIN
    /*
    ** use to update real user rights
    ** use in AddUserToRole and DeleteUserFropRole
    ** use in tsp_RevokeTableOperation
    */
    IF (:"UpdateUserAdminUnit" = 1) THEN
    BEGIN
        EXECUTE PROCEDURE "tsp_LoadUserAdminUnit";
    END

    "UserName" = UPPER(TRIM(:"UserName"));
    IF (:"UserName" = 'SYSDBA') THEN
    BEGIN
        EXIT;
    END

    IF (:"UserName" = '') THEN
    BEGIN
        FOR SELECT TRIM("SQLObjectName") FROM "tbl_AdminUnit"
        WHERE (COALESCE("IsGroup",0) = 0)
            AND (TRIM("SQLObjectName") <> '')
            AND (TRIM("SQLObjectName") <> 'SYSDBA')
        INTO :"UserName"
        DO BEGIN
            EXECUTE PROCEDURE "tsp_UpdateUserRights" :"UserName", 0;
        END
        EXIT;
    END

    DELETE FROM RDB$USER_PRIVILEGES UP
    WHERE UP.RDB$USER = :"UserName"
        AND UP.RDB$PRIVILEGE <> 'M';

    IF ("UserIsAdmin" IS NULL) THEN
    BEGIN
        SELECT COALESCE("UserIsAdmin",0) FROM "tbl_AdminUnit"
        WHERE (COALESCE("IsGroup",0) = 0)
            AND (UPPER("SQLObjectName") = :"UserName")
        INTO :"UserIsAdmin";
    END

    IF (:"UserIsAdmin" = 1) THEN
    BEGIN
        INSERT INTO RDB$USER_PRIVILEGES (
            RDB$USER
            ,RDB$GRANTOR
            ,RDB$PRIVILEGE
            ,RDB$GRANT_OPTION
            ,RDB$RELATION_NAME
            ,RDB$FIELD_NAME
            ,RDB$USER_TYPE
            ,RDB$OBJECT_TYPE)
        SELECT
            :"UserName"
            ,RDB$GRANTOR
            ,RDB$PRIVILEGE
            ,RDB$GRANT_OPTION
            ,RDB$RELATION_NAME
            ,RDB$FIELD_NAME
            ,8
            ,RDB$OBJECT_TYPE
        FROM RDB$USER_PRIVILEGES A
        WHERE (A.RDB$USER = 'SYSDBA');
    END ELSE
    BEGIN
        FOR SELECT DISTINCT TRIM(UAU."AdminUnitName")
        FROM "tbl_UserAdminUnit" UAU
        WHERE (UPPER(UAU."UserName") = :"UserName")
            AND (UPPER(UAU."UserName") <> UPPER(UAU."AdminUnitName"))
        INTO :"TableGroup"
        DO BEGIN
            INSERT INTO RDB$USER_PRIVILEGES (
                RDB$USER
                ,RDB$GRANTOR
                ,RDB$PRIVILEGE
                ,RDB$GRANT_OPTION
                ,RDB$RELATION_NAME
                ,RDB$FIELD_NAME
                ,RDB$USER_TYPE
                ,RDB$OBJECT_TYPE)
            SELECT
                :"UserName"
                ,RDB$GRANTOR
                ,RDB$PRIVILEGE
                ,RDB$GRANT_OPTION
                ,RDB$RELATION_NAME
                ,RDB$FIELD_NAME
                ,8
                ,RDB$OBJECT_TYPE
            FROM RDB$USER_PRIVILEGES A
            WHERE (A.RDB$USER = :"TableGroup");
        END

        SELECT "ID"
        FROM "tbl_AdminUnit"
        WHERE (UPPER("SQLObjectName") = :"UserName")
        INTO :"UserID";

        FOR SELECT UPPER(TGP."SQLObjectName")
        FROM "tbl_TableGroup" TGP
        INNER JOIN "tbl_TableGroup" TG ON (TG."ParentID" = TGP."ID")
            AND (TG."AdminUnitID" = :"UserID")
        INTO :"TableGroup"
        DO BEGIN
            INSERT INTO RDB$USER_PRIVILEGES (
                RDB$USER
                ,RDB$GRANTOR
                ,RDB$PRIVILEGE
                ,RDB$GRANT_OPTION
                ,RDB$RELATION_NAME
                ,RDB$FIELD_NAME
                ,RDB$USER_TYPE
                ,RDB$OBJECT_TYPE)
            SELECT
                :"UserName"
                ,RDB$GRANTOR
                ,RDB$PRIVILEGE
                ,RDB$GRANT_OPTION
                ,RDB$RELATION_NAME
                ,RDB$FIELD_NAME
                ,8
                ,RDB$OBJECT_TYPE
            FROM RDB$USER_PRIVILEGES A
            WHERE (A.RDB$USER = :"TableGroup");
        END
    END
END
;
