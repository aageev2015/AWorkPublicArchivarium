insert into [Transactionall]
(ACCOUNT_STRUC_ID, ADDRESS,AMOUNT,CODE,DISCOUNT_AMOUNT,DISCOUNT_SUM,DISCOUNT_TYPE,DISCOUNT_VALUE,ID_CLIENTS,ID_SERVICE_STATION,ID_TERMINAL,ID_TRANSACTION,N_CLIENT,N_SERVICE_STATION,PLACE,PRICE,SERIAL_VISIBLE,SESSION_DATE,SESSION_TIME,SUM,TERMINAL_SERIAL,TERMINAL_SHIFT,TERMINAL_TRANSACTION)
select top 10 * 
FROM OpenDataSource( 'Microsoft.Jet.OLEDB.4.0',
  'Data Source="D:\Projects\Demos\!CompanyDemo321\New17032010\Unrachived\Transactions2009_01.xls";User ID=Admin;Password=;Extended properties=Excel 5.0')..."List1$"