ALTER PROCEDURE [dbo].[WriteLog_UserLog_Transfer]
	@UserID int, 
	@FromCustID INT, 
	@ToCustID INT, 
	@IP varchar(15)='',
	@Doing varchar(1000)=''
AS
/*
Creator: Kiwi
Date: 03/10/2009
DB: bodb_CustomerLog
Task: Insert LOGS for Trasfer function

*/

SET NOCOUNT ON;

INSERT INTO dbo.UserLog_Transfer(	UserID,
									FromCustID,
									ToCustID,
									IP,
									Doing) 
							VALUES(	@UserID,
									@FromCustID,
									@ToCustID,
									@IP,
									@Doing)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Transfer] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Transfer] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Transfer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Transfer] TO [vnTeam]