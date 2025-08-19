/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="wsv_CashService,asv_CashService" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[WriteLog_CashService_UserLog_API]
	@CustID INT = 0,
	@UserID INT = 0,
	@SubAccID INT = 0,
	@From VARCHAR(100) = NULL,
	@To VARCHAR(100) = NULL,
	@FuncName VARCHAR(100) = NULL,
	@Duration INT = 0,
	@RequestUrl VARCHAR(MAX) = NULL,
	@RequestBody NVARCHAR(MAX) = NULL,
	@ResponseBody NVARCHAR(MAX)= NULL,
	@StatusCode INT	= 0,
	@Exception VARCHAR(MAX) = NULL
/*
    Created: 20250708@Kan
    Task: Write request/response log of API
    DB: bodb_CustomerLog

	Revisions:
		- 20250708@Kan: Agency Cash Service Write API Log [Redmine: #232347]

    Param's Explaination:
		- @UserID: UserId perform this action
*/
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.Cash_UserLog_API
		(CustID, UserID, SubAccID, [From], [To], FuncName, Duration, RequestUrl, RequestBody, ResponseBody, StatusCode, Exception)
	VALUES
		(@CustID, @UserID, @SubAccID, @From, @To, @FuncName, @Duration, @RequestUrl, @RequestBody, @ResponseBody, @StatusCode, @Exception)
END
GO