USE [bodb_CustomerLog]
GO
/****** Object:  StoredProcedure [dbo].[UserLog_CreditSel]    Script Date: 02/04/2010 18:20:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[UserLog_CreditSel]
    @RequestUserId INT = NULL ,
    @CustID INT ,
	@CustName varchar(50) = '',
    @FromDate DATETIME ,
    @ToDate DATETIME ,
    @ActionTypeId INT = null,
    @IsInternal TINYINT ,
    @PageIndex INT ,
    @PageSize INT
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Get paged log credit
	
	Revisions:
	- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]

    Param's Explaination:    
	- @RequestUserId: Authenticated user 
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log
	- @ActionTypeId: action type
	- @IsInternal: Accounting: 1 Agent:0
	- @PageIndex: from 0
	- @PageSize: total record per request
*/

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON ;

SET @PageIndex = ABS(@PageIndex)
SET @PageSize = ABS(@PageSize)  


DECLARE @lbound INT 
DECLARE @ubound INT

SET @lbound = @PageIndex * @PageSize       
	
SET @ubound = @lbound + @PageSize 
IF ( @PageIndex > 0 ) 
    SET @lbound = @lbound + 1

DECLARE @ActionName AS NVARCHAR(256)
		
SELECT	LogID,
        UserID,
		CustID,
		LogDate,
		OldValue,
		NewValue,
		IP,
		Doing,
		ActionID,
		IsInternal,
		ActionTypeID,
        SPName,
		UserName,
		CustName,                                                             
		ActionName
					
FROM    ( SELECT    ROW_NUMBER() OVER (ORDER BY LogDate DESC) AS RowNum,
                    LogID,
                    UserID,
					uc.CustID,
					LogDate,
					OldValue,
					NewValue,
					IP,
					Doing,
					la.ActionID,
					IsInternal,
					la.ActionTypeID,
                    la.SPName,
					Username,
					--Username =	CASE 
					--					when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
					--					ELSE ci.Username
					--				END,
					@CustName as CustName,                                         
					'' As ActionName
          FROM      dbo.UserLog_Credit AS uc WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
					INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
          WHERE     uc.CustID = @CustID
                    AND LogDate BETWEEN @FromDate AND @ToDate                            
                    AND IsInternal <= @IsInternal
					AND ci.roleid <=4
        ) AS MyTable
WHERE   RowNum BETWEEN @lbound AND @ubound


GO
GRANT EXECUTE ON [dbo].[UserLog_CreditSel] TO [wsv_nap]
GO
GRANT EXECUTE ON [dbo].[UserLog_CreditSel] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[UserLog_CreditSel] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[UserLog_CreditSel] TO [vnteam]