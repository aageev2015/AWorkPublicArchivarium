goto start
------------------------------
call ExecSQL.exe:
database - DB name
bak - path to backup
------------------------------
:start
sqlcmd -S TSCTD\MSSQL2008 -U sa -P removedpwd -i restoreDB.sql -v database="CRMDB_332127" -v bak="\\backshost\DB\MSSQL2008\BAK\CRMDB_332127.bak"
@pause