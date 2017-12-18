CREATE PROCEDURE [dbo].[WriteLog_UserLog_CasinoAPI]
	@SystemID TINYINT = 0,
	@UserID int, 
	@CustID int, 
	@ActionID int, 
	@FuncName varchar(200), 
	@TrackingValue xml,
    @ReturnValue nvarchar(max),
	@ReturnCode int = 0 
AS
/*
Creator: 20100821@QuiNV
Task: Insert Casino API calling statistic
DB: DB052.BODB_CUSTOMERLOG
Original: 

Revisions:

Param's Explanation:
	@SystemID: Sub-system id: Accounting 3, Agent 2, AgentWap 4, AgentIphone 5
	@UserID: Login user id, 
	@CustID: Customer id, 
	@ActionID: Action id (hashed from @FuncName), 
	@FuncName: Name of API, 
	@TrackingValue: API serialized parameters,
    @ReturnValue: Returned value of API
	@ReturnCode: Returned code of API: 1 failed, 0 succeeded.
*/


SET NOCOUNT ON

INSERT INTO dbo.UserLog_CasinoAPI(	
									SystemID,
									UserID, 
									CustID, 
									ActionID, 
									FuncName, 
									TrackingValue,
									ReturnValue,
									ReturnCode
								 ) 
								 VALUES(
									@SystemID,		
									@UserID, 
									@CustID, 
									@ActionID, 
									@FuncName, 
									@TrackingValue,
									@ReturnValue,
									@ReturnCode
								 )

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_CasinoAPI] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_CasinoAPI] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_CasinoAPI] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_CasinoAPI] TO [vnteam]
GO