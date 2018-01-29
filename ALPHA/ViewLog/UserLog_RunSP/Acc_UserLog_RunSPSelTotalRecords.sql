/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
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
    DB: DBLOG/bodb_CustomerLog

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
		- 20180123@Johnson: support view log for status by level for new direction[Redmine: #87328]
*/
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

	SET NOCOUNT ON ;
	DECLARE @srecommend INT
			,@mrecommend INT
			,@recommend INT
			,@roleid TINYINT
	
	SELECT @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @roleid = roleid
	FROM bodb02.dbo.CustInfo WITH(NOLOCK)
	WHERE custid = @CustID
	
	DECLARE @tmpCust TABLE(Custid INT)
	CREATE TABLE #tmpLog (LogID BIGINT)
	
	IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)  
	BEGIN
		select @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
		IF (@ActionTypeId > 0)
		BEGIN
			IF @ActionTypeID = 5--status
			BEGIN
				INSERT #tmpLog
				SELECT ul.LogID
				FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE     ul.CustID = @CustId
					AND LogDate BETWEEN @FromDate AND @ToDate
					AND la.ActionTypeID = @ActionTypeId
					AND la.ActionID BETWEEN 1100 AND 1199
					AND IsInternal <= @IsInternal
					AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
					AND ul.ActionID NOT BETWEEN 31000 AND 31100	
				
				--new range logactionid for status by level
				SELECT @LowerActionId = CASE @roleid WHEN 4 THEN 60000
													WHEN 3 THEN 61000
													WHEN 2 THEN 62000
													WHEN 1 THEN 63000 END,
						@UpperActionId = CASE @roleid WHEN 4 THEN 60999
													WHEN 3 THEN 61999
													WHEN 2 THEN 62999
													WHEN 1 THEN 63999 END									
				
				INSERT INTO @tmpCust(CustID)
				SELECT @CustID 
				UNION SELECT @srecommend WHERE @roleid<4
				UNION SELECT @mrecommend WHERE @roleid<3
				UNION SELECT @recommend WHERE @roleid<2
				
				INSERT #tmpLog
				SELECT ul.LogID
				FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE     ul.CustID IN (SELECT custid FROM @tmpCust)
					AND LogDate BETWEEN @FromDate AND @ToDate
					AND la.ActionTypeID = @ActionTypeId
					AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
					AND IsInternal <= @IsInternal
					AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
					AND ul.ActionID NOT BETWEEN 31000 AND 31100
				
				SELECT COUNT(LogID)
				FROM #tmpLog				
			END--@ActionTypeID = 5
			ELSE
			BEGIN
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
			END			
		END--@ActionTypeId > 0			
		ELSE
			SELECT  COUNT(LogID)                           
			FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE   ul.CustID = @CustId
					AND LogDate BETWEEN @FromDate AND @ToDate								
					AND IsInternal <= @IsInternal
					--exclude log action of status
					AND la.ActionID NOT BETWEEN 1100 AND 1199
					AND la.ActionID NOT BETWEEN 60000 AND 63999					
					AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
	END--(@LowerActionId IS NULL OR @UpperActionId IS NULL)  
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
END
GO
