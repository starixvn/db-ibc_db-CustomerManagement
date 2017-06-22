/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	Deploy assembly CLR IBCViewLogCLR
	
    Param's Explaination:    
*/

/* ENABLE clR*/
EXEC sp_configure 'clr enabled' , '1'

go

reconfigure;

/* register assembly */
CREATE assembly IBCViewLogCLR FROM '\\10.20.20.211\Deployment\IBC.ViewLog.CLR.dll' WITH PERMISSION_SET = SAFE