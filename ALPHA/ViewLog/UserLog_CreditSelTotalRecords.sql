ALTER PROCEDURE [dbo].[UserLog_CreditSelTotalRecords]
    @RequestUserId INT = NULL,
    @CustID INT,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @IsInternal TINYINT    
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
	- @IsInternal: AccountingSite: 1 Agent:0
	
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT    COUNT(LogID)                           
           FROM     dbo.UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
          WHERE     uc.CustID = @CustID
                    AND LogDate BETWEEN @FromDate AND @ToDate                           
                    AND IsInternal <= @IsInternal
					AND ci.roleid <=4

GO
GRANT EXECUTE ON [dbo].[UserLog_CreditSelTotalRecords] TO [wsv_nap]
GO
GRANT EXECUTE ON [dbo].[UserLog_CreditSelTotalRecords] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[UserLog_CreditSelTotalRecords] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[UserLog_CreditSelTotalRecords] TO [vnteam]