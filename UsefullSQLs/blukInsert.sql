create table t_Store (
	number nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL ,
	City nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL ,
	Category nvarchar(255) COLLATE Cyrillic_General_CI_AS NOT NULL 
)


bulk insert t_store 
from '\\a_myname\temp\ins\Stores.csv'
with (fieldterminator = ';', 
rowterminator = '\n', 
keepidentity, keepnulls, 
codepage = 1251, 
datafiletype = 'char', 
batchsize = 1000)
