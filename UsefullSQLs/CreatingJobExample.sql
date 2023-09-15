--Use only as template for creation jobs, For generating normal SQL use 'Generate SQL Script...' in Enterprice Manager
--CreatClearingTourPriceMain
if exists(select * from msdb..sysjobs where name='NightlyCreateJourneyHistory')
	exec msdb..sp_delete_job @job_name = 'NightlyCreateJourneyHistory'


EXEC msdb..sp_add_job @job_name = 'NightlyCreateJourneyHistory', 
   @enabled = 1,
   @description = 'Creates Journey History for contacts',
   @owner_login_name = 'sa',
   @notify_level_eventlog = 2,
   @notify_level_email = 0,
   @notify_level_netsend = 0,
   @notify_level_page = 0,
   @delete_level = 1

EXEC msdb..sp_add_jobschedule @job_name = 'NightlyCreateJourneyHistory', 
   @name = 'CreateJourneyHistory',
   @freq_type = 4, -- daily
   @freq_interval = 1,
   @active_start_time = 10000

EXEC msdb..sp_add_jobstep @job_name = 'NightlyCreateJourneyHistory',
   @step_name = 'CreateJourneyHistory',
   @subsystem = 'TSQL',
   @command = 'exec [spCreateJourneyHistory]', 
   @retry_attempts = 5,
   @retry_interval = 5

