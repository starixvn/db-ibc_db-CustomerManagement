ALTER PROCEDURE [dbo].[WriteLog_UserLog_Login]
	@UserID int, 
	@RoleID tinyint, 
	@SubAccID int, 
	@ServerID int, 
	@LoginIP varchar(20)='',
	@ActionID int = 0,
	@Doing varchar(300)
	
AS
/*
Creator: 20081129@QuiNV
Task: Insert login count statistic
DB: DB052.BODB_CUSTOMERLOG
Original: 

Revisions:
	- 20100101@Kiwi: Write logs for ActionID and Doing
Param's Explanation:
• @CustID: main account login.
• @RoleID: roleID of main account.
• @SubAccID: subaccount ID(0: main account login, >0: subaccount login, <0: admin login => subaccid stand for admin ID).
• @ServerID: serverID.
• @LoginIP: IP user login.

*/


SET NOCOUNT ON

INSERT INTO dbo.UserLog_Login(	UserID, 
								RoleID, 
								SubAccID, 
								ServerID, 
								IP, 
								LogDate, 
								ActionID, 
								Doing
							  ) 
						VALUES(	@UserID, 
								@RoleID, 
								@SubAccID, 
								@ServerID, 
								@LoginIP, 
								CURRENT_TIMESTAMP, 
								@ActionID, 
								@Doing
							  )

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Login] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Login] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Login] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Login] TO [vnteam]