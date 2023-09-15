if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='STOCK' and COLUMN_NAME='_ModificatedOn')
alter table [STOCK] add [_ModificatedOn] datetime default(getdate())
go
if not exists(select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='STOCK' and COLUMN_NAME='_CreatedOn')
alter table [STOCK] add [_CreatedOn] datetime default(getdate())
go

if (object_id('tr_u_STOCK_ModificatedOn') is not null)
drop trigger [tr_u_STOCK_ModificatedOn]
go

create trigger [tr_u_STOCK_ModificatedOn] on [STOCK]
after update
as
begin
	update s
	set [_ModificatedOn] = getdate()
	from [STOCK] s
	inner join inserted i on i.id=s.id
end
go