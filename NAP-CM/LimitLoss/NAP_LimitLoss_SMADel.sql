/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_AGE]
GO

ALTER PROCEDURE [dbo].[NAP_LimitLoss_SMADel]
    @CustId		INT,
	@Mode		TINYINT = 0,
    @UserID		INT = 0,
    @IP			NVARCHAR(50) = NULL,
    
    @ErrCode	INT = 0 OUT,
    @ErrMsg		NVARCHAR(200) = '' OUT

AS
/*
	Created: Aaron
	Date: 20160608
	Task : SMA Loss monitor report
	DB: DBAGE/bodb_Age

	Revisions:
		- 20170915@Elodie: Support Group Headline Setting [Redmine: #82892]

	Parameter's explaination: 
		- Mode =	0: SMA setting
					1: Group Headline Setting
					2: Member of group headline
	
	Example:
	
*/

BEGIN
    SET NOCOUNT ON

    DECLARE	@startRun			DATETIME,
			@endRun				DATETIME,
			@duration			INT,
			@MaxLoss_Old		MONEY,
			@GroupHeadlineID	SMALLINT

    SET		@startRun = GETDATE()

    --Check permission 
    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[LossMonitor]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
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
		
		SELECT @MaxLoss_Old = ls.MaxLoss FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId

		DELETE LimitLoss_Setting WITH(ROWLOCK,UPDLOCK) WHERE CustID=@CustID
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

		SELECT @MaxLoss_Old = ls.MaxLoss FROM dbo.LimitLoss_HeadlineSetting ls WITH (NOLOCK) WHERE ls.GroupHeadlineID = @GroupHeadlineID

		DELETE LimitLoss_HeadlineSetting WITH(ROWLOCK,UPDLOCK) WHERE GroupHeadlineID = @GroupHeadlineID

		DELETE ls 
		FROM dbo.LimitLoss_Setting ls WITH (ROWLOCK,UPDLOCK)
			INNER JOIN bodb02.dbo.custAccount ca WITH (NOLOCK) ON ca.custid = ls.CustID
		WHERE ca.groupID = @GroupHeadlineID AND ls.MaxLoss IS NULL
	END

	IF @Mode = 2
	BEGIN
		IF @CustId <= 0
		   OR NOT EXISTS (SELECT 1 FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
			RETURN
		END
		
		SELECT @MaxLoss_Old = ls.MaxLoss FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId

		UPDATE ls 
		SET MaxLoss = NULL
		FROM LimitLoss_Setting ls WITH(ROWLOCK,UPDLOCK) 
		WHERE CustID = @CustID
	END

    DECLARE @LogData NVARCHAR(4000)

    SET @endRun = GETDATE()
    SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

    SELECT @LogData = '<NAP_LimitLoss_SMADel CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					    + 'MaxLoss="' + COALESCE(CAST(@MaxLoss_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
						+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
					    + 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					    + 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					    + 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @UserID,
			@CustID = @CustID,
			@ActionID = 665,
			@TrackingValue = @LogData,
			@Duration = @duration			
	END TRY
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @UserID,
			@CustID = @CustID,
			@ActionID = 665,
			@TrackingValue = @LogData,
			@Duration = @duration	
	END CATCH
END





