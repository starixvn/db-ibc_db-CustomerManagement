ALTER PROCEDURE [dbo].[WriteLog_UserLog_ExchangeRate]
	@UserID int, 
	@ExchangeID INT, 
	@actualrate float, 
	@IP varchar(15)='',
	@Doing varchar(1000)=''
AS
/*
Creator: Daniel
Date: 03/10/2009
DB: bodb_CustomerLog
Task: Insert LOGS for update exchange rate

*/

SET NOCOUNT ON;

INSERT INTO dbo.UserLog_Exchange(	UserID,
									ExchangeID,
									actualrate,
									Doing,								
									IP
									) 
							VALUES(	@UserID,
									@ExchangeID,
									@actualrate,
									@Doing,
									@IP)




GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_ExchangeRate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_ExchangeRate] TO [vnteam]