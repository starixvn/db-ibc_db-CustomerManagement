/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_RunSPSel]    
    @CustId INT,
	@LoginUserId INT = 0,
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
/*	Created:20100121@Lewin
    Task: ViewLog function 331
    DB: DBLOG/bodb_CustomerLog
    
    Revisions:
		- 20110421@Jamie: Temporiraly fix to show Logs updated from Licensee Risk and Forecast 
		- 20110511@Henry: Change LRF ActionID to new Range (2000-2299)
		- 20110513@Amy: Get more column TrackingValue2 
		- 20110721@Sophia: If is Internal access and @custName is nickname then don't show data
		- 20121029@Elodie: Get UseName = 'Admin' if ActionID BETWEEN 1142 AND 1144
		- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]
		- 20160115@Dominic: Do not show logactionid=237 if Trackingvalues is null Redmine: #50937
		- 20160222@Dominic: Correct TrackingValue when logactionid In (1100,1101,1102,1103) and its value contain 'Hide*Cricket' Redmine: #52667
		- 20160222@Dominic: Correct TrackingValue when logactionid In (1100,1101,1102,1103) and its value contain 'Hide*Cricket' Redmine: #52667
		- 20161018@Winnie: Handle logactionid range of smartpunter RedmineID #63077
		- 20171205@Winnie: Provide API for FPS to update dangerous level for evidence member #86627
		- 20180123@Johnson: support view log for status by level for new direction[Redmine: #87328]
		- 20180621@Razor: Exclude log of Message Customer Read Status [Redmind: #94705]
		- 20180903@Elodie: Revise SP for @ActionTypeID = 5 (status)
		- 20180227@Elodie: Add new range actionID for status of CN88 [Redmind: #105338]
		- 20190405@Patrick: Support archive date range [Redmine: #111476]
		- 20191113@Winnie: Alpha - View Log : user can view total records when searching by nickname [Redmine: #110148]
		- 20200219@Elodie: Show log of problem account for downline [Redmine:#127446]
		- 20200310@Percy: Add ActionID 705, 706 under Status [RedmineID: #130091]
		- 20200602@Sol: Show log for action update of IsAutoEnableADBMaster [Redmine: #134242]
		- 20210518@Winfred: Show log for Parlay Max Payout [RedmineID:#154104]
		- 20210804@Elodie: Show log betsetting for downlines [RedmineID:#158073]
		- 20230303@Eden: Migrate NG and Keno to DCS structure [Redmine: #179711]
		- 20230508@Luke: Add log when user limit PT update by Site/Currency [Redmine: #186741]
		- 20230515@Tacy: EXT NAP - Allow headlines update Bet Settings on multiple supers [RedmineID: #186773]
		- 20230927@Tacy: Show log suspend member account by CWL flow on Alpha [RedmineID: #184911]
		- 20240108@Luke: NAP - Virtual rate - Enhance VR [Redmine: #194939]
		- 20231019@Helios: Customer Setting - Migrate Sportsbook to DCS [RedmineID: #193083] 
	Description:
		- Get paged log run sp. If @LowerActionId and @UpperActionId are both not null, get actions in range 
	
    Param's Explaination:    
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
BEGIN	
	SET NOCOUNT ON 
	
	SET @PageIndex = ABS(@PageIndex)
	SET @PageSize = ABS(@PageSize)  

	DECLARE @lbound INT 
			,@ubound INT
			,@roleid TINYINT
			,@srecommend INT
			,@mrecommend INT
			,@recommend INT
			,@creatdate DATETIME
			,@LowerActionIdStatus INT
			,@UpperActionIdStatus INT
			,@i INT = 1000000
			,@LoginUserRoleId TINYINT

	DECLARE @tmpCust TABLE(Custid INT)		
	CREATE TABLE #tmpLog (LogID BIGINT,
						UserID INT,
						Username NVARCHAR(100),
						TrackingValue NVARCHAR(MAX),
						TrackingValueOld NVARCHAR(MAX),
						LogDate DATETIME,
						ActionID INT,
						ActionTypeID INT,
						SPName VARCHAR(50),
						IsInternal BIT,
						CustID INT,
						CustName NVARCHAR(100),
						ActionName NVARCHAR(512)
					)
					
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

	IF @FromDate < @creatdate
		SELECT @FromDate = DATEADD(SECOND,-30,@creatdate)--@Johnson: backward 30s to get log [#97633]
		
	SET @lbound = @PageIndex * @PageSize       
		
	SET @ubound = @lbound + @PageSize 
	IF ( @PageIndex > 0 ) 
		SET @lbound = @lbound + 1

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

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

	IF (@ActionTypeId = 4 OR @ActionTypeId = -1)	--downlines view upline's actions on VR value
	BEGIN
		--ActionTypeID = 4 (General Info)
		--ActionID in (95116,95117,95118)
		DECLARE @VRUpperActionID INT
				,@VRLowerActionID INT
				,@VRUpperActionID_LRF INT
				,@VRLowerActionID_LRF INT

		SELECT @VRLowerActionID = 95116
				,@VRUpperActionID = CASE @roleid WHEN 4 THEN 95116
												WHEN 3 THEN 95117
												WHEN 2 THEN 95118
												WHEN 1 THEN 95118 END
				,@VRLowerActionID_LRF = 2803
				,@VRUpperActionID_LRF = CASE @roleid WHEN 4 THEN 2803
												WHEN 3 THEN 2804
												WHEN 2 THEN 2805
												WHEN 1 THEN 2805 END

		DECLARE @VRCust TABLE (CustID INT)
		INSERT INTO @VRCust(CustID)
			SELECT @srecommend
			WHERE @roleid <= 4
		UNION
			SELECT @mrecommend
			WHERE @roleid <= 3
		UNION 
			SELECT @recommend
			WHERE @roleid <= 2

		IF @FromDate > @__archiveDate
		BEGIN
			INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
				, SPName, IsInternal, CustID, CustName, ActionName)
			SELECT  LogID,
					UserID,
					Username =	CASE 
									WHEN (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
									WHEN (la.ActionID BETWEEN 2000 AND 3000) THEN 'Admin'
									ELSE c.Username
								END,
					ul.TrackingValue,
					TrackingValue2,
					LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					ul.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
			FROM	@VRCust tmp
					CROSS APPLY (	SELECT TOP (@i) * 
									FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
									WHERE ul.custid = tmp.Custid 
										AND LogDate BETWEEN @FromDate AND @ToDate) ul
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE	((la.ActionID BETWEEN @VRLowerActionID AND @VRUpperActionID) OR (la.ActionID BETWEEN @VRLowerActionID_LRF AND @VRUpperActionID_LRF))
					AND la.ActionTypeID = 4
					AND IsInternal <= @IsInternal
			OPTION (OPTIMIZE FOR (@i = 1))
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
				, SPName, IsInternal, CustID, CustName, ActionName)
			SELECT  LogID,
					UserID,
					Username =	CASE 
									when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
									WHEN (la.ActionID BETWEEN 2000 AND 3000) THEN 'Admin'
									ELSE c.Username
								END,
					ul.TrackingValue,
					TrackingValue2,
					LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					ul.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
			FROM	@VRCust tmp
					CROSS APPLY (	SELECT TOP (@i) * 
									FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
									WHERE ul.custid = tmp.Custid 
										AND LogDate BETWEEN @FromDate AND @ToDate) ul
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE	((la.ActionID BETWEEN @VRLowerActionID AND @VRUpperActionID) OR (la.ActionID BETWEEN @VRLowerActionID_LRF AND @VRUpperActionID_LRF))
					AND la.ActionTypeID = 4
					AND IsInternal <= @IsInternal
			OPTION (OPTIMIZE FOR (@i = 1))
		END
		ELSE
		BEGIN
			INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
				, SPName, IsInternal, CustID, CustName, ActionName)
			SELECT  LogID,
					UserID,
					Username =	CASE 
									when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
									WHEN (la.ActionID BETWEEN 2000 AND 3000) THEN 'Admin'
									ELSE c.Username
								END,
					ul.TrackingValue,
					TrackingValue2,
					LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					ul.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
			FROM	@VRCust tmp
					CROSS APPLY (	SELECT TOP (@i) * 
									FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
									WHERE ul.custid = tmp.Custid 
										AND LogDate BETWEEN @__archiveDate AND @ToDate) ul
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE	((la.ActionID BETWEEN @VRLowerActionID AND @VRUpperActionID) OR (la.ActionID BETWEEN @VRLowerActionID_LRF AND @VRUpperActionID_LRF))
					AND la.ActionTypeID = 4
					AND IsInternal <= @IsInternal
			OPTION (OPTIMIZE FOR (@i = 1))	
			
			INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
				, SPName, IsInternal, CustID, CustName, ActionName)
			SELECT  LogID,
					UserID,
					Username =	CASE 
									when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
									WHEN (la.ActionID BETWEEN 2000 AND 3000) THEN 'Admin'
									ELSE c.Username
								END,
					ul.TrackingValue,
					TrackingValue2,
					LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					ul.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
			FROM	@VRCust tmp
					CROSS APPLY (	SELECT TOP (@i) * 
									FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
									WHERE ul.custid = tmp.Custid 
										AND LogDate >= @FromDate AND logdate < @__archiveDate) ul
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
			WHERE	((la.ActionID BETWEEN @VRLowerActionID AND @VRUpperActionID) OR (la.ActionID BETWEEN @VRLowerActionID_LRF AND @VRUpperActionID_LRF))
					AND la.ActionTypeID = 4
					AND IsInternal <= @IsInternal
			OPTION (OPTIMIZE FOR (@i = 1))	
		END
	END
	IF  (@LowerActionId IS NULL OR @UpperActionId IS NULL)       
	BEGIN
		IF (@ActionTypeId > 0)						
		BEGIN
			IF @ActionTypeID = 5--for status
			BEGIN
				INSERT INTO @tmpCust(CustID)
				SELECT @CustID 
				--new range logactionid for status by level
				SELECT @LowerActionIdStatus = CASE @roleid WHEN 4 THEN 60000
													WHEN 3 THEN 65000
													WHEN 2 THEN 70000
													WHEN 1 THEN 75000 END,
						@UpperActionIdStatus = CASE @roleid WHEN 4 THEN 64999
													WHEN 3 THEN 69999
													WHEN 2 THEN 74999
													WHEN 1 THEN 79999 END

				IF @FromDate >= @__archiveDate
				BEGIN
					--old log status has actionid from 1100 and 1199
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
											ELSE c.Username
										END,
							CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
									THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
									ELSE ul.TrackingValue END TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
					
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT  LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0 and la.ActionID<>75043) THEN 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
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
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 OR la.ActionID=75043 --action: suspend membe by CWL flow
																				THEN 999999 
														   WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					--old log status has actionid from 1100 and 1199
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
											ELSE c.Username
										END,
							CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
									THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
									ELSE ul.TrackingValue END TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @FromDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2
					
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT  LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0 and la.ActionID<>75043) THEN 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
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
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 OR la.ActionID=75043 --action: suspend membe by CWL flow
																				THEN 999999 
														   WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

				END
				ELSE
				BEGIN
					--old log status has actionid from 1100 and 1199
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
											ELSE c.Username
										END,
							CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
									THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
									ELSE ul.TrackingValue END TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate BETWEEN @__archiveDate AND @ToDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))

					--old log status has actionid from 1100 and 1199
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
											ELSE c.Username
										END,
							CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
									THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
									ELSE ul.TrackingValue END TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
						FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate >= @FromDate AND logdate < @__archiveDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionTypeID = @ActionTypeId
							AND (la.ActionID IN (705, 706, 707) OR la.ActionID BETWEEN 1100 AND 1199 OR la.ActionID BETWEEN 165000 AND 169999)
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					INSERT INTO @tmpCust(CustID)
					SELECT @srecommend WHERE @roleid<4
					UNION SELECT @mrecommend WHERE @roleid<3
					UNION SELECT @recommend WHERE @roleid<2

					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT  LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0 and la.ActionID<>75043) THEN 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
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
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 OR la.ActionID=75043 --action: suspend membe by CWL flow
																				THEN 999999 
														   WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
					
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT  LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0 and la.ActionID<>75043) THEN 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
					FROM	@tmpCust tmp
							CROSS APPLY (	SELECT TOP (@i) * 
											FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK) 
											WHERE ul.custid = tmp.Custid 
												AND LogDate > @FromDate AND LogDate < @__archiveDate) ul
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE	la.ActionID BETWEEN @LowerActionIdStatus AND @UpperActionIdStatus
							AND la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							--dont show these actions on alpha
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 OR la.ActionID=75043 --action: suspend membe by CWL flow
																				THEN 999999 
														   WHEN @IsInternal = 0 THEN 4 END
					OPTION (OPTIMIZE FOR (@i = 1))
				END
						
				SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValueOld,
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
								TrackingValue,
								TrackingValueOld,
								LogDate,
								ActionID,
								ActionTypeID,
								SPName,
								IsInternal,
								CustID,
								CustName,
								ActionName
						FROM  #tmpLog
					) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound

			END--end @ActionTypeID = 5
			ELSE
			BEGIN 
				IF @ActionTypeId = 1 --for limit PT update
				BEGIN
					INSERT INTO #tmpLog (
						LogID, 
						UserID, 
						Username, 
						TrackingValue, 
						TrackingValueOld, 
						LogDate, 
						ActionID, 
						ActionTypeID, 
						SPName, 
						IsInternal, 
						CustID, 
						CustName, 
						ActionName
					)

					SELECT  al.LogID,
							al.UserID,
							Username =	
							CASE 
											when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											ELSE ci.Username
										END,
							al.TrackingValue,
							al.TrackingValue2,
							al.LogDate,
							la.ActionID,
							la.ActionTypeID,
							la.SPName,
							la.IsInternal,
							al.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
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
				END--end @ActionTypeID = 1				
				IF @FromDate >= @__archiveDate
				BEGIN	
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT  LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
					FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE     ul.CustID = @CustId
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220038,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)
							--exclude log for VR value update
							AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
						
					IF @ActionTypeId = 3 -- BET LIMIT
					BEGIN
						
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT  LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE     ((ul.CustID in ( @srecommend ) AND @roleid= 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid= 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
								AND LogDate BETWEEN @FromDate AND @ToDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	
								AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
									OR ul.ActionID BETWEEN 220008 AND 220019)
								AND LogDate > @creatdate
					END

					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT mt.MainLogID,
						mt.UserID,
						c.Username,
						mt.TrackingValue,
						TrackingValue2,
						mt.LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						lt.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
					FROM dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
						INNER JOIN dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
					WHERE	lt.custid = @CustId
							AND mt.LogDate BETWEEN @FromDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END		
				END
				ELSE IF @ToDate < @__archiveDate
				BEGIN
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT  LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
					FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE     ul.CustID = @CustId
							AND LogDate BETWEEN @FromDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)
							--exclude log for VR value update
							AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
					IF @ActionTypeId = 3 -- BET LIMIT
					BEGIN
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT  LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE    ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
								AND LogDate BETWEEN @FromDate AND @ToDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
									OR ul.ActionID BETWEEN 220008 AND 220019)
								AND LogDate > @creatdate
					END
							
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT mt.MainLogID,
						mt.UserID,
						c.Username,
						mt.TrackingValue,
						TrackingValue2,
						mt.LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						lt.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
					FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
						INNER JOIN bodb_CustomerLog_Archive.dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
					WHERE	lt.custid = @CustId
							AND mt.LogDate BETWEEN @FromDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	
				END
				ELSE
				BEGIN
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT  LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
					FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE     ul.CustID = @CustId
							AND LogDate BETWEEN @__archiveDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)
							--exclude log for VR value update
							AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT LogID,
							UserID,
							Username =	CASE 
											when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
											when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
											ELSE c.Username
										END,
							ul.TrackingValue,
							TrackingValue2,
							LogDate,
							la.ActionID,
							ActionTypeID,
							la.SPName,
							IsInternal,
							ul.CustID,
							@CustName AS CustName,
							la.ActionNameEN AS ActionName
					FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
							LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
					WHERE     ul.CustID = @CustId
							AND LogDate >= @FromDate AND LogDate < @__archiveDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
							AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)	
							AND ul.ActionID NOT BETWEEN 31000 AND 31100					
							AND ul.ActionId <> 1050 --Message Customer Read Status Update
							AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
							AND ul.ActionID NOT BETWEEN 220008 AND 220019
							--exclude log for limit PT update
							AND ul.ActionID NOT IN (470,471,473,474)
							--exclude log for VR value update
							AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
					IF @ActionTypeId = 3 -- BET LIMIT
					BEGIN
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT  LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE     ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
								AND LogDate BETWEEN @__archiveDate AND @ToDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
									OR ul.ActionID BETWEEN 220008 AND 220019)
								AND LogDate > @creatdate 
															
						INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
							, SPName, IsInternal, CustID, CustName, ActionName)
						SELECT LogID,
								UserID,
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
												ELSE c.Username
											END,
								ul.TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
						WHERE     ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
								AND LogDate >= @FromDate AND LogDate < @__archiveDate
								AND  la.ActionTypeID = @ActionTypeId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
									OR ul.ActionID BETWEEN 220008 AND 220019)
								AND LogDate > @creatdate
					END	
				
					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT mt.MainLogID,
						mt.UserID,
						c.Username,
						mt.TrackingValue,
						mt.TrackingValue2,
						mt.LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						lt.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
					FROM dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
						INNER JOIN dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
					WHERE	lt.custid = @CustId
							AND mt.LogDate BETWEEN @__archiveDate AND @ToDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	


					INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
					SELECT mt.MainLogID,
						mt.UserID,
						c.Username,
						mt.TrackingValue,
						TrackingValue2,
						mt.LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						lt.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
					FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
						INNER JOIN bodb_CustomerLog_Archive.dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
					WHERE	lt.custid = @CustId
							AND mt.LogDate >= @FromDate AND mt.LogDate < @__archiveDate
							AND  la.ActionTypeID = @ActionTypeId
							AND IsInternal <= @IsInternal
							AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END	
				END
					
				SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValueOld,
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
								TrackingValue,
								TrackingValueOld,
								LogDate,
								ActionID,
								ActionTypeID,
								SPName,
								IsInternal,
								CustID,
								CustName,
								ActionName
						FROM  #tmpLog
					) AS MyTable
				WHERE   RowNum BETWEEN @lbound AND @ubound
			END	
		END--end (@ActionTypeId > 0)	
		ELSE 
		BEGIN
		--Insert Limit PT Update log
			INSERT INTO #tmpLog (
					LogID, 
					UserID, 
					Username, 
					TrackingValue, 
					TrackingValueOld, 
					LogDate, 
					ActionID, 
					ActionTypeID, 
					SPName, 
					IsInternal, 
					CustID, 
					CustName, 
					ActionName
				)

				SELECT  al.LogID,
						al.UserID,
						Username =	
						CASE 
										when (ci.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										ELSE ci.Username
									END,
						al.TrackingValue,
						al.TrackingValue2,
						al.LogDate,
						la.ActionID,
						la.ActionTypeID,
						la.SPName,
						la.IsInternal,
						al.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
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
						)--end Insert Limit PT Update log
			IF @FromDate >= @__archiveDate
			BEGIN
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT  LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,							
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE     ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						--AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
						--	OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)
						--exclude log for VR value update
						AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
					
				-- check  Parlay Max Payout Indirectly
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT  LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,							
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate BETWEEN @FromDate AND @ToDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate 		
					
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT mt.MainLogID,
					mt.UserID,
					c.Username,
					mt.TrackingValue,
					mt.TrackingValue2,
					mt.LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					lt.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
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
						--AND (mt.ActionId NOT BETWEEN 31620 AND 31622
						--	OR ( mt.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
			END
			ELSE IF @ToDate < @__archiveDate
			BEGIN
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT  LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,							
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE     ul.CustID = @CustId
						AND LogDate BETWEEN @FromDate AND @ToDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						--AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
						--	OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)
						--exclude log for VR value update
						AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
				-- check  Parlay Max Payout Indirectly
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT  LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,							
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate BETWEEN @FromDate AND @ToDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate   
							
							
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT mt.MainLogID,
					mt.UserID,
					c.Username,
					mt.TrackingValue,
					mt.TrackingValue2,
					mt.LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					lt.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
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
						--AND (mt.ActionId NOT BETWEEN 31620 AND 31622 
						--	OR ( mt.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))
			END
			ELSE
			BEGIN
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT  LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE     ul.CustID = @CustId
						AND LogDate BETWEEN @__archiveDate AND @ToDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						--AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
						--	OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)
						--exclude log for VR value update
						AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE     ul.CustID = @CustId
						AND LogDate >= @FromDate AND LogDate < @__archiveDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						--exclude log action of status
						AND la.ActionID NOT IN (705, 706, 707)
						AND la.ActionID NOT BETWEEN 1100 AND 1199
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						AND la.ActionID NOT BETWEEN 60000 AND 79999
						--exclude log action of smart punter
						AND ul.ActionID NOT BETWEEN 31000 AND 31100
						AND ul.ActionId <> 1050 --Message Customer Read Status Update
						--AND (ul.ActionId NOT BETWEEN 31620 AND 31622 
							--OR ( ul.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
						AND ul.ActionID NOT IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
						AND ul.ActionID NOT BETWEEN 220008 AND 220019
						--exclude log for limit PT update
						AND ul.ActionID NOT IN (470,471,473,474)
						--exclude log for VR value update
						AND ul.ActionID NOT IN (95116,95117,95118,2803,2804,2805)
				-- check  Parlay Max Payout Indirectly
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT  LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate BETWEEN @__archiveDate AND @ToDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate 	
							
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT LogID,
						UserID,
						Username =	CASE 
										when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
										when (la.ActionID BETWEEN 2000 AND 3000) then 'Admin'
										ELSE c.Username
									END,
						ul.TrackingValue,
						TrackingValue2,
						LogDate,
						la.ActionID,
						ActionTypeID,
						la.SPName,
						IsInternal,
						ul.CustID,
						@CustName AS CustName,
						la.ActionNameEN AS ActionName
				FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
						INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
						LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID
				WHERE   ((ul.CustID in ( @srecommend ) AND @roleid  = 3 )
								OR (ul.CustID in ( @srecommend ,@mrecommend ) AND @roleid  = 2 )
								OR (ul.CustID in ( @srecommend ,@mrecommend , @recommend ) AND @roleid  = 1 ))
						AND LogDate >= @FromDate AND LogDate < @__archiveDate				
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
						AND (ul.ActionID IN (220001,220003,220005,220021,220023,220025,220027,220028,220029,220031,220032,220033,220035,220038,220040,220042,220044) 
							OR ul.ActionID BETWEEN 220008 AND 220019)
						AND LogDate > @creatdate 	
							
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT mt.MainLogID,
					mt.UserID,
					c.Username,
					mt.TrackingValue,
					mt.TrackingValue2,
					mt.LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					lt.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
				FROM dbo.UserLog_RunSP_MultiTarget mt WITH (NOLOCK) 													
					INNER JOIN dbo.UserLog_RunSP_LogTarget lt WITH (NOLOCK) ON lt.LogID = mt.LogID										
					INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON mt.ActionID = la.ActionID
					LEFT JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON c.custid = mt.UserID
				WHERE	lt.custid = @CustId
						AND mt.LogDate BETWEEN @__archiveDate AND @ToDate
						AND IsInternal <= @IsInternal
						AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
						--exclude log action of status
						AND la.ActionID NOT BETWEEN 165000 AND 169999
						--AND (mt.ActionId NOT BETWEEN 31620 AND 31622 
						--	OR ( mt.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
					
				INSERT INTO #tmpLog (LogID, UserID, Username, TrackingValue, TrackingValueOld, LogDate, ActionID, ActionTypeID
						, SPName, IsInternal, CustID, CustName, ActionName)
				SELECT mt.MainLogID,
					mt.UserID,
					c.Username,
					mt.TrackingValue,
					mt.TrackingValue2,
					mt.LogDate,
					la.ActionID,
					ActionTypeID,
					la.SPName,
					IsInternal,
					lt.CustID,
					@CustName AS CustName,
					la.ActionNameEN AS ActionName
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
						--AND (mt.ActionId NOT BETWEEN 31620 AND 31622 
						--	OR ( mt.ActionId BETWEEN 31620 AND 31622 AND (@LoginUserRoleId NOT IN (2,3) OR @LoginUserId = 0)))	
			END

			SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValueOld,
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
							TrackingValue,
							TrackingValueOld,
							LogDate,
							ActionID,
							ActionTypeID,
							SPName,
							IsInternal,
							CustID,
							CustName,
							ActionName
					FROM  #tmpLog
				) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END	
	END --end (@LowerActionId IS NULL OR @UpperActionId IS NULL) 
	ELSE
	BEGIN
		IF @FromDate >= @__archiveDate
		BEGIN
			SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValue2 as TrackingValueOld,
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
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000 OR la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
												ELSE c.Username
											END,
								CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
										THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
										ELSE ul.TrackingValue END TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
						WHERE     ul.CustID = @CustId
								AND LogDate BETWEEN @FromDate AND @ToDate
								AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
								
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
		ELSE IF @ToDate < @__archiveDate
		BEGIN
			SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValue2 as TrackingValueOld,
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
								Username =	CASE 
												when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
												when (la.ActionID BETWEEN 2000 AND 3000 OR la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
												ELSE c.Username
											END,
								CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
										THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
										ELSE ul.TrackingValue END TrackingValue,
								TrackingValue2,
								LogDate,
								la.ActionID,
								ActionTypeID,
								la.SPName,
								IsInternal,
								ul.CustID,
								@CustName AS CustName,
								la.ActionNameEN AS ActionName
						FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
								INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
								LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
						WHERE     ul.CustID = @CustId
								AND LogDate BETWEEN @FromDate AND @ToDate
								AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
								AND IsInternal <= @IsInternal
								AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
								AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
								
					) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
		ELSE
		BEGIN
			SELECT  LogID,
					UserID,
					Username,
					TrackingValue,
					TrackingValue2 as TrackingValueOld,
					LogDate,
					ActionID,
					ActionTypeID,
					SPName,
					IsInternal,
					CustID,
					CustName,
					ActionName
								
			FROM ( 
				SELECT ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum, *
				FROM (
					SELECT LogID,
									UserID,
									Username =	CASE 
													when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
													when (la.ActionID BETWEEN 2000 AND 3000 OR la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
													ELSE c.Username
												END,
									CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
											THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
											ELSE ul.TrackingValue END TrackingValue,
									TrackingValue2,
									LogDate,
									la.ActionID,
									ActionTypeID,
									la.SPName,
									IsInternal,
									ul.CustID,
									@CustName AS CustName,
									la.ActionNameEN AS ActionName
							FROM      dbo.UserLog_RunSP AS ul WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
									LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
							WHERE     ul.CustID = @CustId
									AND LogDate BETWEEN @__archiveDate AND @ToDate
									AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
									AND IsInternal <= @IsInternal
									AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
									AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)

						UNION ALL
						SELECT LogID,
									UserID,
									Username =	CASE 
													when (c.RoleId > 4 and @IsInternal=0) THEN 'Admin'
													when (la.ActionID BETWEEN 2000 AND 3000 OR la.ActionID BETWEEN 1142 AND 1144 OR la.ActionID=1165) then 'Admin'
													ELSE c.Username
												END,
									CASE WHEN ul.ActionID IN  (1100,1101,1102,1103) AND ul.TrackingValue LIKE '%Hide*Cricket%' 
											THEN REPLACE(TrackingValue,'Hide*Cricket','HideCricket') 
											ELSE ul.TrackingValue END TrackingValue,
									TrackingValue2,
									LogDate,
									la.ActionID,
									ActionTypeID,
									la.SPName,
									IsInternal,
									ul.CustID,
									@CustName AS CustName,
									la.ActionNameEN AS ActionName
							FROM      bodb_CustomerLog_Archive.dbo.UserLog_RunSP AS ul WITH (NOLOCK)
									INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON ul.ActionID = la.ActionID
									LEFT JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.custid = ul.UserID					
							WHERE     ul.CustID = @CustId
									AND LogDate >= @FromDate AND LogDate < @__archiveDate
									AND la.actionid BETWEEN @LowerActionId AND @UpperActionId
									AND IsInternal <= @IsInternal
									AND ISNULL(c.roleid,0) <= CASE WHEN @IsInternal = 1 THEN 999999 WHEN @IsInternal = 0 THEN 4 END
									AND (ul.ActionID <> 237 OR ul.TrackingValue IS NOT NULL)
				) AS MyTable1
			) AS MyTable
			WHERE   RowNum BETWEEN @lbound AND @ubound
		END
	END

END

