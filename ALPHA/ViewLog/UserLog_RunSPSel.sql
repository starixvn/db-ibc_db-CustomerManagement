ALTER PROCEDURE [dbo].[UserLog_RunSPSel]
    @RequestUserId INT = NULL,
    @CustId INT,
	@CustName VARCHAR(50) = '',
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT = -1,
    @IsInternal TINYINT,
    @LowerActionId INT = NULL,
	@UpperActionId INT = NULL,
    @PageIndex INT,
    @PageSize INT
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Get paged log run sp. If @LowerActionId and @UpperActionId are both not null, get actions in range 
	
	Revisions:
	- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]

    Param's Explaination:    
	- @RequestUserId: Authenticated user 
	- @UserId: a customer which we want to view actions affect to.
	- @CustName: customer name type in textbox to search
	- @FromDate: date range to view log
	- @ToDate: date range to view log
	- @ActionTypeId: action type. If ActionType < 0: select all type
	- @IsInternal: accounting site = 1, agent = 0
	- @LowerActionId: query actionid in range
	- @UpperActionId: query actionid in range	
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

IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)       
BEGIN
	select @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
	IF (@ActionTypeId > 0)						
	SELECT  LogID,
			UserID,
			Username,
			TrackingValue,
			LogDate,
			ActionID,
			ActionTypeID,
			SPName,
			IsInternal,
			CustID,
			CustName,
			ActionName
						
	FROM    (
			 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
						LogID,
						UserID,
						c.Username,
						--Username =	CASE 
						--				when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
						--				ELSE c.Username
						--			END,
						TrackingValue,
						LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						'' AS ActionName
			  FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			  WHERE     ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate
						AND  la.ActionTypeID = @ActionTypeId
						AND IsInternal <= @IsInternal
						AND c.roleid <= 4
			) AS MyTable
	WHERE   RowNum BETWEEN @lbound AND @ubound
	ELSE
	SELECT  LogID,
			UserID,
			Username,
			TrackingValue,
			LogDate,
			ActionID,
			ActionTypeID,
			SPName,
			IsInternal,
			CustID,
			CustName,
			ActionName
						
	FROM    (
			 SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
						LogID,
						UserID,
						Username,
						--Username =	CASE 
						--				when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
						--				ELSE c.Username
						--			END,
						TrackingValue,
						LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						'' AS ActionName
			 FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			  WHERE     ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate				
						AND IsInternal <= @IsInternal
						AND la.ActionID NOT BETWEEN @LowerActionId AND @UpperActionId
						AND c.roleid <= 4

			) AS MyTable
	WHERE   RowNum BETWEEN @lbound AND @ubound
END
ELSE
BEGIN
	SELECT  LogID,
			UserID,
			Username,
			TrackingValue,
			LogDate,
			ActionID,
			ActionTypeID,
			SPName,
			IsInternal,
			CustID,
			CustName,
			ActionName
						
	FROM    ( SELECT    ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
						LogID,
						UserID,
						Username,
						--Username =	CASE 
						--				when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
						--				ELSE c.Username
						--			END,
						TrackingValue,
						LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						'' AS ActionName
			 FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
			  WHERE     ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate
						AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
						AND IsInternal <= @IsInternal
						AND c.roleid <= 4
			) AS MyTable
	WHERE   RowNum BETWEEN @lbound AND @ubound
END
GO
GRANT EXECUTE ON [dbo].[UserLog_RunSPSel] TO [wsv_nap]
GO
GRANT EXECUTE ON [dbo].[UserLog_RunSPSel] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[UserLog_RunSPSel] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[UserLog_RunSPSel] TO [vnteam]
