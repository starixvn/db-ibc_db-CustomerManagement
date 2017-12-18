ALTER PROCEDURE [dbo].[WriteLog_UserLog_RunSP]
		@UserID INT,
		@CustID INT = 0,
		@SPName VARCHAR(50)= NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER
		@Doing	VARCHAR(4000) = NULL, --
		@ActionID INT = NULL,	
		@TrackingValue nvarchar(MAX)= NULL,
		@TrackingValue2 nvarchar(MAX) = NULL,
		@Duration INT = NULL
		
/* Created:
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Revisions:
		- 20100102@Lewin: Write xml tracking value to dbo.UserLog_RunSP 	  
		- 20101019@Henry: add one more parameter: @Duration   
		- 20110519@Johnson: add new column TrackingValue2
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

INSERT INTO dbo.UserLog_RunSP(	UserID, 
								CustID, 
								SPName,
								Doing,
								ActionID, 
								TrackingValue,
								TrackingValue2,
								Duration
								)
					  VALUES (	@UserID, 
								@CustID, 
								@SPName,
								@Doing,
								@ActionId, 
								@TrackingValue,
								@TrackingValue2,
								@Duration
								)
END

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [Dot_Admin]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [bodbLicenseeNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_RunSP] TO [vnteam]
