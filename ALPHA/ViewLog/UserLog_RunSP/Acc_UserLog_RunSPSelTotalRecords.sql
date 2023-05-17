/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_RunSPSelTotalRecords]     
	@CustId INT, 
	@LoginUserId INT = 0,
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
		- 20171205@Winnie: Provide API for FPS to update dangerous level for evidence member #86627
		- 20180123@Johnson: support view log for status by level for new direction[Redmine: #87328]
		- 20180621@Razor: Exclude log of Message Customer Read Status [Redmind: #94705]
		- 20180911@Eloide: Use Index hint IX_UserLog_RunSP
		- 20180903@Elodie: Revise SP for @ActionTypeID = 5 (status)
		- 20180227@Elodie: Add new range actionID for status of CN88 [Redmind: #105338]
		- 20190405@Patrick: Support archive date range [Redmine: #111476]
		- 20200219@Elodie: Show log of problem account for downline [Redmine:#127446]
		- 20200310@Percy: Add ActionID 705, 706 under Status [RedmineID: #130091]
		- 20200602@Sol: Show log for action update of IsAutoEnableADBMaster [Redmine: #134242]
		- 20210518@Winfred: Show log for Parlay Max Payout [RedmineID:#154104]
		- 20210804@Elodie: Show log betsetting for downlines [RedmineID:#158073]
		- 20230303@Eden: Migrate NG and Keno to DCS structure [Redmine: #179711]
		- 20230508@Luke: Add log when user limit PT update by Site/Currency [Redmine: #186741]

*/
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

	SET NOCOUNT ON ;
	DECLARE @srecommend INT
			,@mrecommend INT
			,@recommend INT
			,@roleid TINYINT
			,@creatdate DATETIME 
			,@LowerActionIdStatus INT
			,@UpperActionIdStatus INT
			,@i INT = 1000000
			,@LoginUserRoleId TINYINT

	SELECT @srecommend = srecommend, 
		@mrecommend = mrecommend, 
		@recommend = recommend, 
		@roleid = roleid,
		@creatdate = creatdate
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE custid = @CustID
	
	SELECT	@LoginUserRoleId = roleid
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE custid = @LoginUserId

	SELECT	@LoginUserRoleId = ISNULL(@LoginUserRoleId,0)

	IF @FromDate < @creatdate
		SELECT @FromDate = DATEADD(SECOND,-30,@creatdate)--@Johnson: backward 30s to get log [#97633]
	
	DECLARE @tmpCust TABLE(Custid INT)
	CREATE TABLE #tmpLog (LogID BIGINT)
	
	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
	DECLARE @__cnt INT, @__cntTemp INT
	SELECT @__cnt = 0, @__cntTemp = 0

	IF (@ActionTypeId = 1 OR @ActionTypeId = -1)	--include limit PT update log
	BEGIN
		DECLARE @tcustid			INT,
				@tuserid			INT,
				@tlogdate			DATETIME,
				@tActionID			INT,
				@tsite				NVARCHAR(50),
				@tcurrency			NVARCHAR(50),
				@tType				NVARCHAR(50),
				@tLogID				BIGINT,
				@tTrackingValue		NVARCHAR(MAX),
				@tTrackingValue2	NVARCHAR(MAX),
				@XMLPath			NVARCHAR(50),
				@DocHandler			INT,
				@custSite			NVARCHAR(50),
				@custCurrency		NVARCHAR(50)

		SELECT	@custSite		=	c.site, 
				@custCurrency	=	e.currency
		FROM		bodb02.dbo.Customer c WITH (NOLOCK)
		INNER JOIN	bodb02.dbo.Exchange e WITH (NOLOCK) ON c.currency = e.ExchangeID
		WHERE c.custid = @custid

		DECLARE @tempLog AS TABLE(	--store all limit PT update log between @fromdate and @todate
			logid			BIGINT,
			userid			INT,
			logdate			DATETIME,
			custid			INT,
			ActionID		INT,
			TrackingValue	NVARCHAR(MAX),
			TrackingValue2	NVARCHAR(MAX)
		)

		DECLARE @allLog AS TABLE(	--add site, currency, type information for all log
			LogId			BIGINT,
			userid			INT,
			logdate			DATETIME,
			custid			INT,
			actionid		INT,
			TrackingValue	NVARCHAR(MAX),
			TrackingValue2	NVARCHAR(MAX),
			Currency		NVARCHAR(50),
			Site			NVARCHAR(50),
			Type			NVARCHAR(50)
		)
		IF (@FromDate >= @__archiveDate)
		BEGIN
			INSERT INTO @tempLog(logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2)
			SELECT logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2
			FROM dbo.UserLog_RunSP WITH (NOLOCK)
			WHERE ActionID IN (470, 471, 473, 474)
			AND logdate BETWEEN @FromDate AND @ToDate
		END
		ELSE IF (@Todate < @__archiveDate)
		BEGIN
			INSERT INTO @tempLog(logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2)
			SELECT logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2
			FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP WITH (NOLOCK)
			WHERE ActionID IN (470, 471, 473, 474)
			AND logdate BETWEEN @FromDate AND @ToDate		
		END
		ELSE
		BEGIN
			INSERT INTO @tempLog(logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2)
			SELECT logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2
			FROM dbo.UserLog_RunSP WITH (NOLOCK)
			WHERE ActionID IN (470, 471, 473, 474)
			AND logdate BETWEEN @__archiveDate AND @ToDate	

			INSERT INTO @tempLog(logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2)
			SELECT logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2
			FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP WITH (NOLOCK)
			WHERE ActionID IN (470, 471, 473, 474)
			AND logdate >= @FromDate AND logdate < @__archiveDate
		END

		WHILE (1=1)
		BEGIN
			SELECT	@tLogID				=	logID, 
					@tuserid			=	userid,
					@tlogdate			=	logdate,
					@tcustid			=	custid,
					@tActionID			=	actionid,
					@tTrackingValue		=	TrackingValue,
					@tTrackingValue2	=	TrackingValue2
			FROM (
				SELECT TOP 1 logid, userid, logdate, custid, ActionID, TrackingValue, TrackingValue2
				FROM @tempLog 
				ORDER BY logdate DESC
			) t
	
			IF @@ROWCOUNT = 0
				BREAK

			IF @tActionID IN (470, 473)	--Create 
			BEGIN
				SELECT @XMLPath = 'NAP_LimitPTDaily_Ins'
			END
			ELSE						--Delete (471, 474)
			BEGIN
				SELECT @XMLPath = 'NAP_LimitPTDaily_Del'
			END

			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @tTrackingValue
			INSERT INTO @allLog(LogId, userid, logdate, custid, actionid, TrackingValue, TrackingValue2, Currency, Site, Type)
			SELECT 
				@tLogID,
				@tuserid,
				@tlogdate,
				@tcustid,
				@tActionID,
				@tTrackingValue,
				@tTrackingValue2,
				Data.Currency,
				Data.Site,
				Data.Type
			FROM OPENXML (@DocHandler, @XMLPath, 1) 
			WITH (
				Currency	NVARCHAR(50),
				Site		NVARCHAR(50),
				Type		NVARCHAR(50)
			) AS Data

			EXEC sp_xml_removedocument @DocHandler

			DELETE 
			FROM @tempLog 
			WHERE logid = @tLogID
		END
	END
	IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)  
	BEGIN
		select @LowerActionId=1100, @UpperActionId=1199	 --exclude to select Customer Status
		IF (@ActionTypeId > 0)
		BEGIN
			IF @ActionTypeID = 5--status
			BEGIN
				INSERT INTO @tmpCust(CustID)
				SELECT @CustID 

				IF @FromDate >= @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					--new range logactionid for status by level
					SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END									
				
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
				
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
							AND la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							--dont show these actions on alpha
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					--new range logactionid for status by level
					SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END									
				
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
				
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
							AND la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							--dont show these actions on alpha
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				ELSE
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @__archiveDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM @tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate >= @FromDate AND LogDate < @__archiveDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE		la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					--new range logactionid for status by level
					SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
														WHEN 3 THEN 65000
														WHEN 2 THEN 70000
														WHEN 1 THEN 75000 END,
							@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
														WHEN 3 THEN 69999
														WHEN 2 THEN 74999
														WHEN 1 THEN 79999 END									
				
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
				
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @__archiveDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
							AND la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							--dont show these actions on alpha
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate >= @FromDate AND LogDate < @__archiveDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
							AND la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							--dont show these actions on alpha
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END

				SELECT @__cnt AS cnt
							
			END--@ActionTypeID = 5
			ELSE
			BEGIN
				IF @ActionTypeId = 1 --Limit PT Update
				BEGIN
					SELECT  @__cntTemp = count(al.LogId)
					FROM	@allLog al 
							INNER JOIN dbo.LogAction la WITH (NOLOCK) ON al.actionid = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo ci WITH (NOLOCK) ON al.userid = ci.custid
					WHERE		al.actionid IN (470, 471)
							AND	al.custid = @custid
							OR(
									al.actionid	IN (473, 474)
								AND	al.Site		=	CASE	WHEN al.type IN ('Site', 'Site - Currency')		THEN @custSite
													ELSE al.site END
								AND	al.Currency =	CASE	WHEN al.type IN ('Currency', 'Site - Currency')	THEN @custCurrency
													ELSE al.Currency END
							)
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				IF @FromDate >= @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
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
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					-- Count  Parlay Max Payout Indirectly
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
									OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
									OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
								OR ul.ActionID BETWEEN 220008 AND 220019)
							AND LogDate > @creatdate

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(mt.LogID)
					FROM dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
							INNER JOIN dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
						WHERE	lt.custid = @CustId
								AND mt.LogDate BETWEEN @FromDate AND @ToDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					-- Count  Parlay Max Payout Indirectly
					SELECT @__cntTemp = COUNT(ul.LogID)
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
							OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
							OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
								OR ul.ActionID BETWEEN 220008 AND 220019)
							AND LogDate > @creatdate

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT @__cntTemp = COUNT(mt.LogID)
					FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
							INNER JOIN bodb_CustomerLog_Archive.dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
						WHERE	lt.custid = @CustId
								AND mt.LogDate BETWEEN @FromDate AND @ToDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
				ELSE
				BEGIN
					SELECT  @__cntTemp = COUNT(LogID) 
					FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate BETWEEN @__archiveDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT  @__cntTemp = COUNT(LogID)
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE   ul.CustID = @CustId
							AND LogDate >= @FromDate AND LogDate < @__archiveDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					
					-- Count  Parlay Max Payout Indirectly
					
					SELECT  @__cntTemp = COUNT(LogID) 
					FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
							OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
							OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
							AND LogDate BETWEEN @__archiveDate AND @ToDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
								OR ul.ActionID BETWEEN 220008 AND 220019)
							AND LogDate > @creatdate
						
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
					
					
					SELECT  @__cntTemp = COUNT(LogID)
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
							OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
							OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
							AND LogDate >= @FromDate AND LogDate < @__archiveDate
							AND ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
								OR ul.ActionID BETWEEN 220008 AND 220019)
							AND LogDate > @creatdate
					
					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT  @__cntTemp = COUNT(mt.LogID)
					FROM dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
						INNER JOIN dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
					WHERE	lt.custid = @CustId
							AND mt.LogDate BETWEEN @__archiveDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0

					SELECT  @__cntTemp = COUNT(mt.LogID)
					FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
							INNER JOIN bodb_CustomerLog_Archive.dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
						WHERE	lt.custid = @CustId
								AND mt.LogDate >= @FromDate AND mt.LogDate < @__archiveDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	

					SET @__cnt = @__cnt + @__cntTemp
					SET @__cntTemp = 0
				END
			END			
		END--@ActionTypeId > 0			
		ELSE
		BEGIN
		--Count Limit PT Update log
			SELECT  @__cntTemp = count(al.LogId)
			FROM	@allLog al 
					INNER JOIN dbo.LogAction la WITH (NOLOCK) ON al.actionid = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo ci WITH (NOLOCK) ON al.userid = ci.custid
			WHERE		al.actionid IN (470, 471)
					AND	al.custid = @custid
					OR(
							al.actionid	IN (473, 474)
						AND	al.Site		=	CASE	WHEN al.type IN ('Site', 'Site - Currency')		THEN @custSite
											ELSE al.site END
						AND	al.Currency =	CASE	WHEN al.type IN ('Currency', 'Site - Currency')	THEN @custCurrency
											ELSE al.Currency END
					)
			SET @__cnt = @__cnt + @__cntTemp
			SET @__cntTemp = 0--end Count Limit PT Update log

			IF @FromDate >= @__archiveDate
			BEGIN
				SELECT  @__cntTemp = COUNT(LogID)                            
				FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
							OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)
						
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				-- check  Parlay Max Payout Indirectly
				SELECT  @__cntTemp = COUNT(LogID)                            
				FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
						OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
						OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal							
						AND IsInternal <= @IsInternal				
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate
						
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
				
				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate BETWEEN @FromDate AND @ToDate
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

			END
			ELSE IF @ToDate < @__archiveDate
			BEGIN
				SELECT  @__cntTemp = COUNT(LogID)
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
							OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				-- check  Parlay Max Payout Indirectly
				SELECT  @__cntTemp = COUNT(LogID)
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
						OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
						OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal				
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate
									 
				-- check  Parlay Max Payout Indirectly
				SELECT  @__cntTemp = COUNT(LogID)
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
						OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
						OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate BETWEEN @FromDate AND @ToDate								
						AND IsInternal <= @IsInternal				
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND ul.ActionID IN (220001,220003,220005)   
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
				
				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN bodb_CustomerLog_Archive.dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate BETWEEN @FromDate AND @ToDate
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
			END
			ELSE
			BEGIN
				SELECT  @__cntTemp = COUNT(LogID)                                 
				FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @__archiveDate AND @ToDate								
						AND IsInternal <= @IsInternal
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
							OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019 
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)
						
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(LogID)          
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate >= @FromDate AND LogDate < @__archiveDate								
						AND IsInternal <= @IsInternal
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999					
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
						OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019  
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)
						
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
				-- check  Parlay Max Payout Indirectly
				SELECT  @__cntTemp = COUNT(LogID)                                 
				FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @__archiveDate AND @ToDate								
						AND IsInternal <= @IsInternal
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate
						
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(LogID)          
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
						OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
						OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate >= @FromDate AND LogDate < @__archiveDate								
						AND IsInternal <= @IsInternal			
						AND c.roleid <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate 
						
				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0


				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	((lt.CustID in ( @srecommend ) AND @roleid  = 3 )
						OR (lt.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
						OR (lt.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND mt.LogDate BETWEEN @__archiveDate AND @ToDate
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0

				SELECT  @__cntTemp = COUNT(mt.LogID)  
				FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN bodb_CustomerLog_Archive.dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate >= @FromDate AND mt.LogDate < @__archiveDate								
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999

				SET @__cnt = @__cnt + @__cntTemp
				SET @__cntTemp = 0
			END

			SELECT @__cnt AS cnt
		END
			
	END--(@LowerActionId IS NULL OR @UpperActionId IS NULL)  
	ELSE
	BEGIN
		IF @FromDate >= @__archiveDate
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
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT  COUNT(LogID)                           
			FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE   ul.CustID = @CustId
					AND LogDate BETWEEN @FromDate AND @ToDate
					AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
					AND IsInternal <= @IsInternal
					AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
		END
		ELSE
		BEGIN
			SELECT SUM(cnt)
			FROM (
				SELECT  COUNT(LogID) AS cnt
				FROM    dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate BETWEEN @__archiveDate AND @ToDate
						AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)

				UNION ALL
				SELECT  COUNT(LogID) 
				FROM    bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ul.CustID = @CustId
						AND LogDate >= @FromDate AND LogDate < @__archiveDate
						AND la.ActionID BETWEEN @LowerActionId AND @UpperActionId
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
			)t
		END
	END
END
GO
