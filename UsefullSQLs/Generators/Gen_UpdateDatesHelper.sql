--'CCACD52F-B640-477A-8A86-A17032120446'
declare @tableName varchar(250)
set @tableName='tbl_OfferingInDocument'
select 'select max('+name+') as '+Name+' from '+@tableName+' where '+name+'>''2008-11-24 00:00:30.407'' and CreatedByID=''CCACD52F-B640-477A-8A86-A17032120446''' from syscolumns
where xtype=61
and id=(select id from sysobjects where name=@tableName)
and name not in ('CreatedOn','ModifiedOn')
