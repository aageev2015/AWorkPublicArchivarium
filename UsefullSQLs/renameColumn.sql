if exists(select * from information_schema.columns where table_name = 'tbl_Report'
 and column_name = 'FilteredDatasetUSI')
begin
 exec sp_rename 'tbl_Report.FilteredDatasetUSI', 'FilteredDatasetCode', 'COLUMN'
end
