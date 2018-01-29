USE [bodb_CustomerLog]
GO
/****** Object:  StoredProcedure [dbo].[Acc_UserLog_RunSPSelTotalRecords]    Script Date: 01/15/2016 04:48:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_UserLog_RunSPSelTotalRecords    Script Date: 1/15/2016 4:22:01 AM ******/
/****** Object:  Stored Procedure dbo.Acc_UserLog_RunSPSelTotalRecords    Script Date: 1/15/2016 12:03:46 PM ******/
/****** Object:  Stored Procedure dbo.Acc_UserLog_RunSPSelTotalRecords    Script Date: 10/28/2014 11:00:20 PM ******/
/****** Object:  Stored Procedure dbo.Acc_UserLog_RunSPSelTotalRecords    Script Date: 10/27/2014 9:07:26 AM ******/
/****** Object:  Stored Procedure dbo.Acc_UserLog_RunSPSelTotalRecords    Script Date: 10/23/2014 2:04:42 PM ******/
ALTER PROCEDURE [dbo].[Acc_UserLog_RunSPSelTotalRecords]    
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
			AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
			AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
END
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_UserLog_RunSPSelTotalRecords] TO [vnteam] AS [dbo]