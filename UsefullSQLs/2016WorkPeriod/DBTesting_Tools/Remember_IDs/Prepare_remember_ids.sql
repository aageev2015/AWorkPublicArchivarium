--drop table tbl_diag_Remembered_Ids
create table tbl_diag_Remembered_Ids(
	id int identity(1,1) not null primary key
,	Table_Name nvarchar(250) not null
,	record_id int not null
,	Remember_date datetime not null default(getdate())
)