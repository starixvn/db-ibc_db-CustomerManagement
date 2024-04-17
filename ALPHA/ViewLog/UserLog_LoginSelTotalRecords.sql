ALTER PROCEDURE [dbo].[UserLog_LoginSelTotalRecords]
    @RequestUserId INT = NULL,
    @UserId INT,	
    @FromDate DATETIME,
    @ToDate DATETIME,    
    @IsAdminAccess BIT = 0,
	@IsSubCust BIT = 0   
AS
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- count total record with input conditions
	
	Revisions:
	- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]

    Param's Explaination:    
	- @RequestUserId: Authenticated user 
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log	
	- @IsAdminAccess: Accouting site TRUE, agent = FALSE
	- @IsSubCust: view logaction affect to sub account or not
	
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON ;

IF (@IsAdminAccess = 0)
BEGIN
	SELECT  COUNT(LogID)                           
	FROM    dbo.UserLog_Login AS ul WITH(NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
	WHERE    LogDate BETWEEN @FromDate AND @ToDate			
			AND IsInternal <= @IsAdminAccess
			AND ((	UserID = @UserId AND SubAccID = 0)
					or (SubAccID = @UserId))
			AND ci.roleid <=4
END
ELSE
BEGIN
	SELECT  COUNT(LogID)                           
	FROM    dbo.UserLog_Login AS ul WITH(NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH(NOLOCK) ON ul.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = ul.UserID
	WHERE     LogDate BETWEEN @FromDate AND @ToDate			
			AND IsInternal <= @IsAdminAccess
			AND ((	UserID = @UserId AND SubAccID <= 0)
					OR (SubAccID = @UserId))
			AND ci.roleid <=4
END
   
GO
GRANT EXECUTE ON [dbo].[UserLog_LoginSelTotalRecords] TO [wsv_nap]
GO
GRANT EXECUTE ON [dbo].[UserLog_LoginSelTotalRecords] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[UserLog_LoginSelTotalRecords] TO [wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[UserLog_LoginSelTotalRecords] TO [vnteam]
