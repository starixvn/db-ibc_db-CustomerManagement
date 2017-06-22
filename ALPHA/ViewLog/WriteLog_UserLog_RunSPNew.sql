CREATE PROCEDURE [dbo].[WriteLog_UserLog_RunSPNew]
		-- Add the parameters for the stored procedure here
		@UserID INT,
		@CustID INT = 0,
		@ActionID INT = 0,	
		@TrackingValue varchar(MAX)
		
/* Created:20100102@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Write xml tracking value to dbo.UserLog_RunSP 	     
	
    Param's Explaination:    	
	- @UserID: UserId perform this action
	- @CustID: 
	- @ActionID: Log action Id
	- @TrackingValue: xml string format
*/
	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;   
	
		INSERT INTO dbo.UserLog_RunSP(UserID, CustID, ActionID, TrackingValue)
			VALUES (@UserID, @CustID, @ActionId, @TrackingValue)
	END

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSPNew] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSPNew] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSPNew] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_RunSPNew] TO [vnteam]
