print 'query date:'
print getdate()
print ''
print '---------- sys.dm_tran_locks ----------'
print ''
select * from sys.dm_tran_locks 
print '---------- sys.dm_tran_active_transactions ----------'
print ''
select * from sys.dm_tran_active_transactions
print '---------- sys.dm_tran_database_transactions ----------'
print ''
select * from sys.dm_tran_database_transactions
print '---------- sys.dm_exec_sessions ----------'
print ''
select * from sys.dm_exec_sessions
print '---------- sys.databases ----------'
print ''
select database_id, Name from sys.databases
