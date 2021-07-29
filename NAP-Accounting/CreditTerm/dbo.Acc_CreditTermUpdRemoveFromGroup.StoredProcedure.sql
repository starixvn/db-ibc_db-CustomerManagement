/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_CreditTermUpdRemoveFromGroup]
	@CustIDList varchar(200),
	@groupID int,
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = '',
	@Case INT = 0 OUTPUT,
	@Old_Headline INT = 0 OUTPUT,
	@New_Headline INT = 0 OUTPUT,
	@AffectedSupers	VARCHAR(MAX) = '' OUTPUT
AS
--Original: ADMIN\account\creditterm_group_feed_add.asp
/*	Created by: [Creator]		
	DB: DBCUST/CUSTDB
	
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
		- 20090916@Shifu: Write log to DB06	
		- 20100112@Kiwi: amend to write log in xml format.			
		- 20101021@Henry: Record execution time 
		- 20130131@Elodie: Change link server DB03 to DBPOLICY
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]				   
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20200120@Tiara: Allow to remove group which has 1 member [Redmine: #125991]
		- 20200717@Malcolm : Integrate Credit Term & Staff/Boss Management [RedmineID : #137144]
		- 20210301@Percy: Auto remove Super into External Group (follow Headline) [RedmineID: #146710]
	Param's Explanation:
		@Case = 0 : No change
		      = 1 : IsGroupHeadline 0-> 0, the user change group
			  = 2 : IsGroupHeadline 1-> 0
			  = 3 : IsGroupHeadline 0-> 1, the user don't change group
			  = 4 : IsGroupHeadline 0-> 1, the user change group
*/
BEGIN

	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	declare @currentDate datetime = convert(date, getdate())
	
	--Check permission for account site: @phuc20080213
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--end

	CREATE TABLE #Super (CustId INT, GroupExtraPTId INT, GroupName VARCHAR(50), GroupTypeId TINYINT, DataType TINYINT DEFAULT(1), EffectiveDate DATETIME, EndDate DATETIME, PRIMARY KEY(CustId, GroupName))

	-- Log for remove mapping
	DECLARE @EaGroupHeadline TABLE (GroupName VARCHAR(100), SiteId INT, Site VARCHAR(50), ExchangeId INT, Currency VARCHAR(50), GroupTypeId TINYINT, EffectiveDate DATETIME, EndDate DATETIME)

	DECLARE @CustIds TABLE (CustId INT)
	INSERT INTO @CustIds (CustId)
	SELECT DISTINCT val FROM dbo.strSplit(@CustIdList, ',')

	--Check an account disabled or not
	declare @username nvarchar(100), @CustID_Headline INT,@HeadlineName VARCHAR(30)
	select top 1 @username = c.username  
	from custinfo c with (nolock)
	where c.custID in (select t.CustId from @CustIds t) and enabled = 0

	if (@username is not null)
	begin 
		set @ErrMsg = @username + ' is disabled'
		set @ErrCode=600
		Return
	end
	--end
	--Check number of member in group -20200120@Tiara
	DECLARE @TotalMember INT, @UsernameHL NVARCHAR(300)
	SELECT @TotalMember= ISNULL(B.TotalMember,0), @UsernameHL= C.username
	FROM custaccount CA WITH (NOLOCK)
		INNER JOIN (SELECT groupID, CASE WHEN groupID=0 THEN 0 ELSE (count(CA.custid)) END TotalMember FROM custAccount CA WITH (NOLOCK) INNER JOIN customer C WITH (NOLOCK) ON CA.custid = C.custid  GROUP BY groupID) B ON B.groupID = CA.groupID
		RIGHT JOIN customer C  WITH (NOLOCK) ON  CA.custid = C.custid 
	WHERE C.custid IN (SELECT val FROM dbo.strSplit(@CustIDList, ',')) 
		AND ISNULL(C.site,'')<>'CN88'
	-- Get Headline
	SELECT @CustID_Headline = CustID FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupID = @groupID
	SELECT @HeadlineName = username FROM dbo.Customer WITH(NOLOCK) WHERE custid = @CustID_Headline
	-- Allow to remove group if group has one member -20200120@Tiara
	IF @TotalMember = 1
	BEGIN
		UPDATE custAccount WITH (ROWLOCK, UPDLOCK) 
		SET groupID = 0, IsGroupHeadLine = 0
		WHERE custid IN (SELECT val FROM dbo.strSplit(@CustIDList, ','))

		DELETE dbo.CustGroupHeadline WHERE custid IN (SELECT val FROM dbo.strSplit(@CustIDList, ','))
		SELECT @ErrMsg = 'Group of ' + COALESCE(CAST(@UsernameHL AS NVARCHAR(300)), SPACE(1)) + ' has been removed.'

		SET @Case = 2
	END
	ELSE
	BEGIN
		UPDATE custAccount WITH (ROWLOCK, UPDLOCK) 
		SET groupid = 0 
		WHERE custid IN (SELECT val FROM dbo.strSplit(@CustIDList, ','))
			AND isgroupheadline <> 1
			-- TO Control: Email Notification
		INSERT INTO dbo.EmailNotification (NotificationInfo, CreatedDate, ActionID)
		SELECT '<GroupHeadline custid="'+ COALESCE(CAST(custid AS VARCHAR(300)), SPACE(1)) + '" ' +
						'GroupID="'+ COALESCE(CAST(@groupID AS VARCHAR(50)),SPACE(1))  + '" />'  AS NotificationInfo
			, @startRun AS CreatedDate
			
			, 1002 AS ActionID		
									
		FROM (SELECT val AS custid FROM dbo.strSplit(@CustIDList, ',')) AS tmp

		SELECT @Case = 1, @New_Headline = 0, @Old_Headline = @CustID_Headline
	END

	-- List Super are removed
	INSERT INTO #Super (CustId, GroupName, GroupTypeId, EffectiveDate)
	SELECT t.CustId, e.GroupName, e.GroupTypeId, @currentDate
	FROM @CustIds t
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.CustId
		INNER JOIN dbo.Site s WITH (NOLOCK) ON c.Site = s.Site
		INNER JOIN dbo.EaGroupHeadline e WITH (NOLOCK) ON c.currency = e.ExchangeId AND s.SiteId = e.SiteId AND e.GroupHeadlineId = @GroupId
	WHERE c.RoleId = 4

	IF @@ROWCOUNT > 0
	BEGIN
		UPDATE s
		SET s.GroupExtraPTId = e.GroupId
		FROM #Super s
			INNER JOIN dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK) ON s.GroupName = e.GroupName
	END

	-- Log Extra PT
	BEGIN
		CREATE TABLE #ExtraPTLog (CustId INT, TrackingValue NVARCHAR(1000), TrackingValue2 NVARCHAR(1000))
		CREATE CLUSTERED INDEX CIX_ExtraPTLog ON #ExtraPTLog (CustId)

		CREATE TABLE #ExtraPTGroup (CustId INT, GroupId INT, GroupName VARCHAR(100), FromDate DATETIME, ToDate DATETIME, PRIMARY KEY (CustId, GroupId, GroupName, FromDate))
		INSERT INTO #ExtraPTGroup (CustId, GroupId, GroupName, FromDate, ToDate)
		SELECT e.SuperId, e.GroupId, e.GroupName, MIN(e.FromDate), MAX(e.ToDate)
		FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
			INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
		WHERE e.ToDate >= @CurrentDate
		GROUP BY e.SuperId, e.GroupId, e.GroupName

		WHILE 1 = 1
		BEGIN
			UPDATE eg
			SET eg.FromDate = e.FromDate
			FROM #ExtraPTGroup eg
				CROSS APPLY (
					SELECT MIN(e.FromDate) AS FromDate
					FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					WHERE e.SuperId = eg.CustId AND eg.GroupId = e.GroupId
						AND e.ToDate = DATEADD(DAY, -1, eg.FromDate)
				) e
			WHERE e.FromDate IS NOT NULL

			IF @@ROWCOUNT = 0
				BREAK
		END

		INSERT INTO #ExtraPTLog (CustId, TrackingValue2)
		SELECT CustId, '<Acc_CreditTermUpdRemoveFromGroup ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />'
		FROM (
			SELECT c.CustId
				,STUFF((
					SELECT ', ' + cg.GroupName
					FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
						INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND eg.ParentId = 0
						LEFT JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName 
					WHERE cg.CustId = c.CustId AND q.CustId IS NULL
					FOR XML PATH ('')), 1, 2, '') AS ExternalGroups
				,STUFF((
					SELECT ', ' + e.GroupName + ': ' + CONVERT(VARCHAR(10), e.FromDate, 120) + ' - ' + CONVERT(VARCHAR(10), e.ToDate, 120)
					FROM #ExtraPTGroup e
					WHERE e.CustId = c.CustId
					FOR XML PATH ('')), 1, 2, '') AS PrimaryExtraGroup
			FROM (SELECT DISTINCT CustId FROM #Super) c
			GROUP BY c.CustId
		) t
	END

	-- EaGroupHeadline
	IF @TotalMember = 1
	BEGIN
		INSERT INTO @EaGroupHeadline (GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate)
		SELECT GroupName, SiteId, ExchangeId, GroupTypeId, EffectiveDate, EndDate
		FROM dbo.EaGroupHeadline WITH (NOLOCK)
		WHERE GroupHeadlineId = @GroupId

		DELETE dbo.EaGroupHeadline WITH (ROWLOCK, UPDLOCK) WHERE GroupHeadlineId = @GroupId
	END

	-- Extra PT Setting
	IF EXISTS (SELECT 1 FROM #Super WHERE GroupTypeId = 2)
	BEGIN
		UPDATE s
		SET s.EffectiveDate = DATEADD(DAY, 1, s.EffectiveDate)
		FROM #Super s
		WHERE s.GroupTypeId = 2
			AND EXISTS (SELECT c.CustId FROM dbo.Customer c WITH (NOLOCK) WHERE s.CustId = c.srecommend AND c.RoleId = 1)

		-- Remove future setting
		DELETE e WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupId = s.GroupExtraPTId
		WHERE s.GroupTypeId = 2
			AND e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate = s.EffectiveDate
			)

		DELETE e WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupId = s.GroupExtraPTId
		WHERE s.GroupTypeId = 2
			AND e.FromDate >= @currentDate
			AND (
				e.FromDate > @currentDate
				OR e.FromDate = s.EffectiveDate
			)
		
		-- Close current setting
		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = DATEADD(DAY, -1, EffectiveDate)
		FROM dbo.Acc_GroupExtraPTSetting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupId = s.GroupExtraPTId
		WHERE s.GroupTypeId = 2
			AND e.ToDate >= @currentDate

		UPDATE e WITH (ROWLOCK)
		SET e.ToDate = DATEADD(DAY, -1, EffectiveDate)
		FROM dbo.Acc_GroupExtraPT2Setting e
			INNER JOIN #Super s ON e.SuperId = s.CustId AND e.GroupId = s.GroupExtraPTId
		WHERE s.GroupTypeId = 2
			AND e.ToDate >= @currentDate
	END

	-- Acc_CustGroup
	DELETE #Super WHERE GroupName = '' -- No Extra PT

	IF EXISTS (SELECT 1 FROM #Super)
	BEGIN
		-- DataType: 1: delete, 2: remove at the end of today
		UPDATE s
		SET s.EndDate = @currentDate, s.DataType = ISNULL(e.DataType, 1)
		FROM #Super s
			OUTER APPLY (
				SELECT TOP 1 CONVERT(TINYINT, 2) AS DataType
				FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
				WHERE e.SuperId = s.CustId AND e.GroupName = s.GroupName
					AND e.ToDate = @currentDate
				ORDER BY e.FromDate
			) e

		-- Remove supers from old normal groups
		DELETE c WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Acc_CustGroup c
			INNER JOIN #Super s ON c.CustId = s.CustId AND c.GroupName = s.GroupName
		WHERE s.DataType = 1

		-- Will remove supers from old extra pt groups at the end of today
		SET @AffectedSupers = NULL
		SELECT @AffectedSupers = COALESCE(@AffectedSupers + ',', '') + c.UserName
		FROM (SELECT DISTINCT CustId FROM #Super WHERE DataType = 2) s
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON s.CustId = c.CustId

		SELECT @AffectedSupers = ISNULL(@AffectedSupers, '')

		MERGE dbo.Acc_CustGroup_Queue AS t
		USING (SELECT CustId, GroupName, EndDate FROM #Super WHERE DataType = 2) AS s ON t.CustId = s.CustId AND t.GroupName = s.GroupName
		WHEN MATCHED THEN UPDATE
			SET t.EndDate = s.EndDate
		WHEN NOT MATCHED THEN INSERT
			(CustId, GroupName, EndDate)
			VALUES (s.CustId, s.GroupName, s.EndDate);
	END

	-- Log Extra PT
	BEGIN
		UPDATE eg
		SET eg.FromDate = e.FromDate, eg.ToDate = DATEADD(DAY, -1, @CurrentDate)
		FROM #ExtraPTGroup eg
			INNER JOIN (
				SELECT e.SuperId, e.GroupName, MIN(e.FromDate) AS FromDate
				FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
				WHERE e.ToDate = DATEADD(DAY, -1, @CurrentDate) -- end yesterday
				GROUP BY e.SuperId, e.GroupName
			) e ON eg.CustId = e.SuperId AND eg.GroupName = e.GroupName

		DELETE #ExtraPTGroup WHERE ToDate >= @CurrentDate

		INSERT INTO #ExtraPTGroup (CustId, GroupId, GroupName, FromDate, ToDate)
		SELECT e.SuperId, e.GroupId, e.GroupName, MIN(e.FromDate), MAX(e.ToDate)
		FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
			INNER JOIN (SELECT DISTINCT CustId FROM #Super) s ON e.SuperId = s.CustId
		WHERE e.ToDate >= @CurrentDate
		GROUP BY e.SuperId, e.GroupId, e.GroupName

		DELETE e
		FROM (
			SELECT CustId, GroupName, ROW_NUMBER() OVER(PARTITION BY CustId, GroupName ORDER BY FromDate DESC) AS RN
			FROM #ExtraPTGroup e
		) e
		WHERE RN > 1

		WHILE 1 = 1
		BEGIN
			UPDATE eg
			SET eg.FromDate = e.FromDate
			FROM #ExtraPTGroup eg
				CROSS APPLY (
					SELECT MIN(e.FromDate) AS FromDate
					FROM dbo.Acc_GroupExtraPTSetting e WITH (NOLOCK)
					WHERE e.SuperId = eg.CustId AND eg.GroupId = e.GroupId
						AND e.ToDate = DATEADD(DAY, -1, eg.FromDate)
				) e
			WHERE e.FromDate IS NOT NULL

			IF @@ROWCOUNT = 0
				BREAK
		END

		INSERT INTO #ExtraPTLog (CustId, TrackingValue)
		SELECT CustId, '<Acc_CreditTermUpdRemoveFromGroup ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" ' + 'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" />' AS TrackingValue
		FROM (
			SELECT c.CustId
				,STUFF((
					SELECT ', ' + cg.GroupName
					FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
						INNER JOIN NAP_UserControl.dbo.EaGroup eg WITH (NOLOCK) ON cg.GroupName = eg.GroupName AND eg.ParentId = 0
						LEFT JOIN dbo.Acc_CustGroup_Queue q WITH (NOLOCK) ON cg.CustId = q.CustId AND cg.GroupName = q.GroupName 
					WHERE cg.CustId = c.CustId AND q.CustId IS NULL
					FOR XML PATH ('')), 1, 2, '') AS ExternalGroups
				,STUFF((
					SELECT ', ' + e.GroupName + ': ' + CONVERT(VARCHAR(10), e.FromDate, 120) + ' - ' + CONVERT(VARCHAR(10), e.ToDate, 120)
					FROM #ExtraPTGroup e
					WHERE e.CustId = c.CustId
					FOR XML PATH ('')), 1, 2, '') AS PrimaryExtraGroup
			FROM (SELECT DISTINCT CustId FROM #Super) c
			GROUP BY c.CustId
		) t

		UPDATE e1
		SET e1.TrackingValue = e2.TrackingValue
		FROM #ExtraPTLog e1
			INNER JOIN #ExtraPTLog e2 ON e1.CustId = e2.CustId

		DELETE e
		FROM (
			SELECT CustId, ROW_NUMBER() OVER(PARTITION BY CustId ORDER BY CASE WHEN TrackingValue IS NOT NULL AND TrackingValue2 IS NOT NULL THEN 0 ELSE 1 END) AS RN
			FROM #ExtraPTLog
		) e
		WHERE RN > 1
	END

	-- Write log
	-- Extra PT
	SET @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())

	DECLARE @CustId INT, @TrackingValue NVARCHAR(1000), @TrackingValue2 NVARCHAR(1000)
	WHILE EXISTS (SELECT 1 FROM #ExtraPTLog)
	BEGIN
		SELECT TOP 1 @CustId = CustId, @TrackingValue = ISNULL(TrackingValue, ''), @TrackingValue2 = ISNULL(TrackingValue2, '') FROM #ExtraPTLog

		IF @TrackingValue = ''
			SELECT @TrackingValue = @TrackingValue2, @TrackingValue2 = ''

		IF @TrackingValue <> ''
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId
				,@CustId			= @CustId
				,@ActionId			= 95055
				,@TrackingValue		= @TrackingValue
				,@TrackingValue2	= @TrackingValue2
				,@Duration			= @Duration

		DELETE #ExtraPTLog WHERE CustId = @CustId
	END

	-- Log remove mapping
	IF EXISTS (SELECT 1 FROM @EaGroupHeadline)
	BEGIN
		UPDATE eg
		SET eg.Site = s.Site, eg.Currency = e.Currency
		FROM @EaGroupHeadline eg
			INNER JOIN dbo.Site s WITH (NOLOCK) ON eg.SiteId = s.SiteId
			INNER JOIN dbo.Exchange e WITH (NOLOCK) ON eg.ExchangeId = e.ExchangeId

		UPDATE @EaGroupHeadline SET GroupTypeId = 1 WHERE GroupTypeId = 2 AND EndDate < @CurrentDate

		DECLARE @SiteId INT, @Site VARCHAR(50), @ExchangeId INT, @Currency VARCHAR(50)

		WHILE EXISTS (SELECT 1 FROM @EaGroupHeadline)
		BEGIN
			SELECT TOP 1 @SiteId = SiteId, @Site = Site, @ExchangeId = ExchangeId, @Currency = Currency FROM @EaGroupHeadline
			
			SELECT @TrackingValue = '<Acc_CreditTermUpdRemoveFromGroup Site="' + COALESCE(@Site, SPACE(1)) + '" ' +
													'Currency="' + COALESCE(@Currency, SPACE(1)) + '" ' +
													'PrimaryGroup="' + COALESCE(PrimaryExtraGroup, SPACE(1)) + '" ' +
													'HeadlineId="' + COALESCE(CONVERT(VARCHAR(20), @GroupId), SPACE(1)) + '" ' +
													'ExternalGroups="' + COALESCE(ExternalGroups, SPACE(1)) + '" />'
			FROM (
				SELECT STUFF((SELECT ', ' + GroupName FROM @EaGroupHeadline WHERE SiteId = @SiteId AND ExchangeId = @ExchangeId AND GroupName <> '' FOR XML PATH('')), 1, 2, '') AS ExternalGroups
				,STUFF((SELECT ', ' + ISNULL(NULLIF(GroupName, ''), 'No Extra PT') + ': ' + CONVERT(VARCHAR(10), EffectiveDate, 120) + ' - ' + + CONVERT(VARCHAR(10), EndDate, 120) FROM @EaGroupHeadline WHERE SiteId = @SiteId AND ExchangeId = @ExchangeId AND GroupTypeId = 2 FOR XML PATH('')), 1, 2, '') AS PrimaryExtraGroup
			) e

			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId			= @UserId
				,@CustId		= @CustID_Headline
				,@ActionId		= 95057
				,@TrackingValue = @TrackingValue
				,@Duration		= @Duration

			DELETE @EaGroupHeadline WHERE SiteId = @SiteId AND ExchangeId = @ExchangeId
		END
	END
	
	declare @LogData nvarchar(1000)
	Select @LogData = 'GroupID="' + convert(varchar(20), @groupID) + '" ' +
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
	'ErrMsg="'+ @ErrMsg  + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		INSERT INTO DBLOG.bodb_CustomerLog.dbo.UserLog_RunSP (UserID, CustID, ActionID, TrackingValue, duration)	
		SELECT	@UserID, 
				CustID,
				1002,
				'<Acc_CreditTermUpdRemoveFromGroup CustID="'+ CustID + '" ' + @LogData,
				@duration
		FROM (SELECT val CustID FROM dbo.strSplit(@CustIDList, ',')) tbCust
	END TRY
	BEGIN CATCH
		Select @LogData = 'GroupID="' + convert(varchar(20), @groupID) + '" ' +
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
							'ErrMsg="'+ @ErrMsg + ' ' + error_message() + '" />'
		INSERT INTO bodb_CustomerLog.dbo.UserLog_RunSP (UserID, CustID, ActionID, TrackingValue, duration)	
		SELECT	@UserID, 
				CustID,
				1002,
				'<Acc_CreditTermUpdRemoveFromGroup CustID="'+ CustID + '" ' + @LogData,
				@duration
		FROM (SELECT val CustID FROM dbo.strSplit(@CustIDList, ',')) tbCust
	END CATCH

	BEGIN TRY
		INSERT INTO DBCRM.bodb_CRM.dbo.crmUserLog_RunSP (LogDate,UserID, CustID, ActionID,NewValues, IP)	
		SELECT	GETDATE(),
				@UserID, 
				CustID,
				911,
				'<Acc_CreditTermUpdRemoveFromGroup HeadlineID="'+ CAST(ISNULL(@CustID_Headline,0)  AS VARCHAR(20))+ '" HeadlineName ="'+ ISNULL(@HeadlineName, '') +'"/>',
				@IP
		FROM (SELECT val CustID FROM dbo.strSplit(@CustIDList, ',')) tbCust
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 107, @ErrMsg = 'Internal error! Please try again or contact the administrator!'
		RETURN
	END CATCH

	DROP TABLE #ExtraPTGroup
	DROP TABLE #ExtraPTLog
	DROP TABLE #Super
END	
GO