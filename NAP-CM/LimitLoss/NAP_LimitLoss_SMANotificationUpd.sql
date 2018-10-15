/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitLoss_SMANotificationUpd]
    @CustId				INT = NULL,
    @NotifyLetsTalk		BIT,
	@Mode				TINYINT = 0,
    @UserID				INT = 0,
    @IP					NVARCHAR(50) = NULL,    
	@System				BIT = 0,

    @ErrCode			INT = 0 OUT,
    @ErrMsg				NVARCHAR(200)='' OUT

AS
/*
	Created: Elodie
	Date: 20180301
	Task : Update NotifyLetsTalk column
	DB: DBAGE/bodb_Age

	Revisions:
		- 20180301@Elodie: Support send lettalk notification [RedmineID: #91064]
			 
	Parameter's explaination: 
		- Mode =	0: SMA setting
					1: Group Headline Setting
					2: Update All customer
		
	Example:
		EXEC NAP_LimitLoss_SMANotificationUpd_xtest @NotifyLetsTalk = 1, @mode = 2, @userID = 8
	
*/

BEGIN
    SET NOCOUNT ON

	DECLARE	@startRun				DATETIME,
			@endRun					DATETIME,
			@duration				INT,
			@NotifyLetsTalk_Old		BIT,
			@GroupHeadlineID		SMALLINT,
			@i						TINYINT

    SET		 @startRun = GETDATE()

	EXEC DBPOL.NAP_UserControl.dbo.NAP_User_CheckPermission @UserId=@UserID,@SiteKey='CustomerManagement',@FunctionKey='LossMonitor',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	IF @Mode = 0
	BEGIN
		IF @CustId <= 0
		   OR NOT EXISTS (SELECT 1 FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
			RETURN
		END
		
		SELECT @NotifyLetsTalk_Old = ls.NotifyLetsTalk FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId

		UPDATE LimitLoss_Setting WITH(ROWLOCK,UPDLOCK) 
		SET NotifyLetsTalk = @NotifyLetsTalk
		WHERE CustID = @CustID
	END

	IF @Mode = 1
	BEGIN
		SELECT @GroupHeadlineID = groupID FROM bodb02.dbo.custAccount WITH (NOLOCK) WHERE custid = @CustID AND IsGroupHeadLine = 1

		IF @CustId <= 0
		   OR NOT EXISTS (SELECT 1 FROM dbo.LimitLoss_HeadlineSetting ls WITH (NOLOCK) WHERE ls.GroupHeadlineID = @GroupHeadlineID)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Headline.'
			RETURN
		END
		
		SELECT @NotifyLetsTalk_Old = ls.NotifyLetsTalk FROM dbo.LimitLoss_HeadlineSetting ls WITH (NOLOCK) WHERE ls.GroupHeadlineID = @GroupHeadlineID

		UPDATE LimitLoss_HeadlineSetting WITH(ROWLOCK,UPDLOCK) 
		SET NotifyLetsTalk = @NotifyLetsTalk
		WHERE GroupHeadlineID = @GroupHeadlineID
	END

	IF @Mode = 2
	BEGIN
		DECLARE @LevelThreshold TINYINT

		SELECT @LevelThreshold = MIN(LevelID) FROM dbo.LimitLoss_ActionConfig WITH (NOLOCK) WHERE ActionID >= 1
		CREATE TABLE #OldValueSMA(CustID INT, NotifyLetsTalk_Old BIT, IsFinished BIT DEFAULT (0))
		CREATE TABLE #OldValueHeadline(GroupHeadlineID INT, CustID INT, NotifyLetsTalk_Old BIT, IsFinished BIT DEFAULT (0))
		CREATE TABLE #GroupList (CustID INT PRIMARY KEY, GroupID SMALLINT, IsGroupHeadline BIT)

		INSERT INTO #GroupList(CustID, GroupID, IsGroupHeadline)
		SELECT custid, ca.groupID, ca.IsGroupHeadLine
		FROM bodb02.dbo.CustAccount ca WITH (NOLOCK)
			INNER JOIN dbo.LimitLoss_HeadlineSetting hs WITH (NOLOCK) ON ca.groupID = hs.GroupHeadlineID

		INSERT #OldValueHeadline (GroupHeadlineID, CustID, NotifyLetsTalk_Old)
		SELECT gl.GroupID, gl.CustID, hs.NotifyLetsTalk
		FROM LimitLoss_HeadlineSetting hs WITH (NOLOCK)
			INNER JOIN #GroupList gl WITH (NOLOCK) ON hs.GroupHeadlineID = gl.groupID
		WHERE IsGroupHeadLine = 1
			AND hs.LevelID >= @LevelThreshold

		INSERT #OldValueSMA (CustID, NotifyLetsTalk_Old) -- SMA have invidual setting
		SELECT CustID, NotifyLetsTalk
		FROM LimitLoss_Setting t WITH (NOLOCK)
		WHERE NotifyLetsTalk IS NOT NULL AND LevelID >= @LevelThreshold
			AND NOT EXISTS (SELECT 1 FROM #GroupList WHERE CustID = t.CustID)       

		INSERT #OldValueSMA (CustID, NotifyLetsTalk_Old) -- member of group healine
		SELECT t.CustID, t.NotifyLetsTalk
		FROM LimitLoss_Setting t WITH (NOLOCK)
			INNER JOIN #GroupList gl ON gl.CustID = t.CustID
			INNER JOIN LimitLoss_HeadlineSetting hs WITH (NOLOCK) ON gl.GroupID = hs.GroupHeadlineID
		WHERE hs.LevelID >= @LevelThreshold
			AND t.MaxLoss IS NOT NULL

		UPDATE ls
		SET NotifyLetsTalk = @NotifyLetsTalk
		FROM LimitLoss_Setting ls WITH(ROWLOCK,UPDLOCK) 
			INNER JOIN #OldValueSMA o ON o.CustID = ls.CustID
	
		UPDATE ls 
		SET NotifyLetsTalk = @NotifyLetsTalk
		FROM LimitLoss_HeadlineSetting ls WITH(ROWLOCK,UPDLOCK) 	
			INNER JOIN #OldValueHeadline o ON o.GroupHeadlineID = ls.GroupHeadlineID

	END
	DECLARE @LogData NVARCHAR(4000), @LogData2 NVARCHAR(4000)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

	IF @Mode IN (0,1)
	BEGIN
		SELECT @LogData = '<NAP_LimitLoss_SMANotificationUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
							+ 'NotifyLetsTalk="' + COALESCE(CAST(@NotifyLetsTalk AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
					    
		SELECT @LogData2 = '<NAP_LimitLoss_SMANotificationUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
							+ 'NotifyLetsTalk="' + COALESCE(CAST(@NotifyLetsTalk_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
							+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
							+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
							+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'	
		
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@CustID = @CustID,
				@ActionID = 676,
				@TrackingValue = @LogData,
				@TrackingValue2 = @LogData2,
				@Duration = @duration			
		END TRY
		BEGIN CATCH
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@CustID = @CustID,
				@ActionID = 676,
				@TrackingValue = @LogData,
				@TrackingValue2 = @LogData2,
				@Duration = @duration	
		END CATCH
	END
	ELSE											    
	BEGIN
		WHILE (1=1)
		BEGIN
			UPDATE TOP (1) #OldValueHeadline
			SET IsFinished = 1,
				@CustId = CustID,
				@NotifyLetsTalk_Old = NotifyLetsTalk_Old
			WHERE IsFinished = 0

			IF @@ROWCOUNT = 0
				BREAK

			SELECT @LogData = '<NAP_LimitLoss_SMANotificationUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
								+ 'NotifyLetsTalkHeadline="' + COALESCE(CAST(@NotifyLetsTalk AS VARCHAR(20)), SPACE(1)) + '" ' 
								+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
								+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
								+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
								+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
					    
			SELECT @LogData2 = '<NAP_LimitLoss_SMANotificationUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'NotifyLetsTalkHeadline="' + COALESCE(CAST(@NotifyLetsTalk_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
								+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
								+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
								+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
								+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'	
			
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@Userid = @UserID,
					@CustID = @CustID,
					@ActionID = 676,
					@TrackingValue = @LogData,
					@TrackingValue2 = @LogData2,
					@Duration = @duration			
			END TRY
			BEGIN CATCH
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@Userid = @UserID,
					@CustID = @CustID,
					@ActionID = 676,
					@TrackingValue = @LogData,
					@TrackingValue2 = @LogData2,
					@Duration = @duration	
			END CATCH

		END

		WHILE (1=1)
		BEGIN
			UPDATE TOP (1) #OldValueSMA
			SET IsFinished = 1,
				@CustId = CustID,
				@NotifyLetsTalk_Old = NotifyLetsTalk_Old
			WHERE IsFinished = 0

			IF @@ROWCOUNT = 0
				BREAK

			SELECT @LogData = '<NAP_LimitLoss_SMANotificationUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
								+ 'NotifyLetsTalk="' + COALESCE(CAST(@NotifyLetsTalk AS VARCHAR(20)), SPACE(1)) + '" ' 
								+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
								+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
								+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
								+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
					    
			SELECT @LogData2 = '<NAP_LimitLoss_SMANotificationUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'NotifyLetsTalk="' + COALESCE(CAST(@NotifyLetsTalk_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
								+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
								+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
								+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
								+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'	
			
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@Userid = @UserID,
					@CustID = @CustID,
					@ActionID = 676,
					@TrackingValue = @LogData,
					@TrackingValue2 = @LogData2,
					@Duration = @duration			
			END TRY
			BEGIN CATCH
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@Userid = @UserID,
					@CustID = @CustID,
					@ActionID = 676,
					@TrackingValue = @LogData,
					@TrackingValue2 = @LogData2,
					@Duration = @duration	
			END CATCH

		END
	END

END
GO

