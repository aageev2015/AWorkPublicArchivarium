select 
'insert into tbl_xcl_AccountContact(ID, SurNAme, FirstName, SalutationID, xcl_AccountID, JobId, Job, CRM_ContactID, AccountID)
values('+
''''+cast(id as nvarchar(38))+''''+
', '+isnull(''''+replace(surname, '''', '''''')+'''', 'null') + 
', '+isnull(''''+replace(FirstName, '''', '''''')+'''', 'null') + 
', '+isnull(''''+cast(SalutationID as nvarchar(38))+'''', 'null') +
', '+isnull(''''+cast(xcl_AccountID as nvarchar(38))+'''', 'null') + 
', '+isnull(''''+cast(JobId as nvarchar(38))+'''', 'null') + 
', '+isnull(''''+replace(Job, '''', '''''')+'''', 'null') + 
', '+isnull(''''+cast(CRM_ContactID as nvarchar(38))+'''', 'null') + 
', '+isnull(''''+cast(AccountID as nvarchar(38))+'''', 'null') + ')
GO
'
from tbl_xcl_AccountContact