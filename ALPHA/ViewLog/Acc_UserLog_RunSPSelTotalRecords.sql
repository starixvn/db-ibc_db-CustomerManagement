/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_CustomerLog]
GO
CREATE PROCEDURE [dbo].[Acc_UserLog_RunSPSelTotalRecords]    
    @CustId INT, 
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT =-1,
    @IsInternal TINYINT,
	@LowerActionId INT = NULL,
	@UpperActionId INT = NULL  
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- count total record with input conditions
	
    Param's Explaination:    
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log	
	- @IsAdminAccess: Accouting site TRUE, agent = FALSE
	- @IsSubCust: view logaction affect to sub account or not

	 Revisions:
		- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]
		- 20160115@Dominic: Do not show logactionid=237 if Trackingvalues is null Redmine: #50937
		- 20171205@Winnie: Provide API for FPS to update dangerous level for evidence member #86627
		- 20180621@Razor: Exclude log of Message Customer Read Status [Redmind: #94705]
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON ;
 
IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)  
BEGIN
	select @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
	IF (@ActionTypeId > 0)
		SELECT  COUNT(LogID)
		FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
				LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
		WHERE   ul.CustID = @CustId
				AND LogDate BETWEEN @FromDate AND @ToDate
				AND ActionTypeID = @ActionTypeId
				AND IsInternal <= @IsInternal
				AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
				AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
				AND ul.ActionId <> 1050 --Message Customer Read Status Update
	ELSE
		SELECT  COUNT(LogID)                           
		FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
				LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
		WHERE   ul.CustID = @CustId
				AND LogDate BETWEEN @FromDate AND @ToDate								
				AND IsInternal <= @IsInternal
				AND la.ActionID NOT BETWEEN @LowerActionId AND @UpperActionId
				AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
				AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
				AND ul.ActionId <> 1050 --Message Customer Read Status Update
END
ELSE
BEGIN
	SELECT  COUNT(LogID)                           
    FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
			LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
    WHERE   ul.CustID = @CustId
            AND LogDate BETWEEN @FromDate AND @ToDate
            AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
            AND IsInternal <= @IsInternal
			AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
			AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
END
GO