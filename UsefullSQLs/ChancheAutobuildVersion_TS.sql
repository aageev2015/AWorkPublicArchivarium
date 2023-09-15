declare @ChangeTo int;
set @ChangeTo=95

if (not exists(select * from sysobjects t1, syscolumns t2 where t1.id=t2.id and t1.Name = 'tbl_DatabaseInfo' and t1.Type='U' and t2.Name = 'DatabaseBuildVersion_Original'))
begin
	alter table tbl_DatabaseInfo
	add DatabaseBuildVersion_Original int
	
	update tbl_DatabaseInfo
	set DatabaseBuildVersion_Original = DatabaseBuildVersion;
end

update tbl_DatabaseInfo
set DatabaseBuildVersion=@ChangeTo

