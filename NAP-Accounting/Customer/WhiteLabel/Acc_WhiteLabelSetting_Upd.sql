/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_WhiteLabelSetting_Upd
	-- Add the parameters for the stored procedure here
	 @CustID		INT
	,@AgentRate		SMALLMONEY
	,@MasterRate	SMALLMONEY
	,@SuperRate		SMALLMONEY
	,@HeadlineRate	SMALLMONEY
	,@LaunchedDate	DATETIME
	,@Remark		VARCHAR(1000)=NULL
	,@UserID		INT
	,@IP			VARCHAR(50)		= ''
	,@ErrCode		INT				= 0	 OUTPUT
	,@ErrMsg		NVARCHAR(4000)	= '' OUTPUT
AS
/*
	Created: Tacy
	Task: NAP - Configure White Label rate - Update setting
	DB: DBCUST-CUSTDB

	Revisions:
		- 20240827@Tacy: Create SP [Redmine: #209807]

	Param's Explanation:
*/
BEGIN 
	SET NOCOUNT ON;

	DECLARE @LogData NVARCHAR(MAX), @LogDataOld NVARCHAR(MAX)

	DECLARE   @Today	DATETIME
			, @startRun DATETIME
			, @duration INT
			, @FromDate			DATETIME
			, @oldAgentRate		SMALLMONEY
			, @oldMasterRate	SMALLMONEY
			, @oldSuperRate		SMALLMONEY
			, @oldHeadlineRate	SMALLMONEY
			, @oldRemark		VARCHAR(1000)
			, @oldLaunchedDate	DATETIME

	DECLARE @GroupHeadlineID INT

	SELECT	@startRun = GETDATE()
			,@Today = CONVERT(DATE,GETDATE())

	EXEC dbo.Acc_WhiteLabelSetting_Check
		 @Username		= @CustID
		,@CheckCustId	= 1
		,@IsNew			= 0
		,@ErrCode		= @ErrCode	OUTPUT
		,@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	SELECT @oldAgentRate = ws.AgentRate
		, @oldMasterRate = ws.MasterRate
		, @oldSuperRate = ws.SuperRate
		, @oldHeadlineRate = ws.HeadlineRate
		, @oldRemark = ws.Remark
		, @oldLaunchedDate = wi.LaunchedDate
		, @GroupHeadlineID = GroupID
	FROM WhiteLabelInfo wi WITH (NOLOCK)
		CROSS APPLY (SELECT TOP 1 ws.AgentRate, ws.MasterRate
								, ws.SuperRate, ws.HeadlineRate
								, ws.Remark, ws.GroupID
						FROM WhiteLabelSetting ws WITH (NOLOCK)
						WHERE ws.CustID=wi.CustID
						AND ws.ToDate>@Today) ws
	WHERE wi.CustID=@CustID

	-- Check valid --
	IF @oldAgentRate = @AgentRate AND @oldMasterRate = @MasterRate
		AND @oldSuperRate = @SuperRate AND @oldHeadlineRate = @HeadlineRate
		AND ISNULL(@oldRemark,'')=ISNULL(@Remark,'') 
		AND @oldLaunchedDate=@LaunchedDate
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Nothing change.'
		
		RETURN
	END

	--Old log:
	SELECT  @LogDataOld = (SELECT wi.WhiteLabel
								, CONVERT(VARCHAR(10), COALESCE(@GroupHeadlineID,0)) AS GroupID
								, CONVERT(DATE, @oldLaunchedDate) AS LaunchedDate
								, CONVERT(VARCHAR(50), @oldAgentRate) AS AgentRate
								, CONVERT(VARCHAR(50), @oldMasterRate) AS MasterRate
								, CONVERT(VARCHAR(50), @oldSuperRate) AS SuperRate
								, CONVERT(VARCHAR(50), @oldHeadlineRate) AS HeadlineRate
								, CONVERT(VARCHAR(50), @oldRemark) AS Remark
								, CONVERT(VARCHAR(20), @IP) AS IP
							FROM WhiteLabelInfo wi WITH (NOLOCK) 
							WHERE wi.CustID=@CustID
							FOR XML RAW('Acc_WhiteLabelSetting_Upd')
						) 

	BEGIN TRY
		IF @LaunchedDate<>@oldLaunchedDate
		BEGIN
			UPDATE WhiteLabelInfo WITH (ROWLOCK, UPDLOCK)
			SET LaunchedDate=@LaunchedDate
				, RepUpdateTime=dbo.f_GetDateTime2()
			WHERE CustID=@CustID
		END

		IF NOT (@oldAgentRate = @AgentRate AND @oldMasterRate = @MasterRate
				AND @oldSuperRate = @SuperRate AND @oldHeadlineRate = @HeadlineRate
				AND ISNULL(@oldRemark,'')=ISNULL(@Remark,''))
		BEGIN
			--update: WITHIN A DAY
			IF EXISTS (SELECT TOP 1 1 FROM WhiteLabelSetting WITH (NOLOCK)
						WHERE custid = @CustId 
						AND FromDate = DATEADD(DAY,1,@Today)
						AND ToDate > @Today)
			BEGIN
				UPDATE WhiteLabelSetting WITH (ROWLOCK, UPDLOCK)
				SET AgentRate=@AgentRate
					,MasterRate=@MasterRate
					,SuperRate=@SuperRate
					,HeadlineRate=@HeadlineRate
					,Remark=@Remark
					,RepUpdateTime=dbo.f_GetDateTime2()
				WHERE custid = @CustId 
				AND FromDate = DATEADD(DAY,1,@Today)
				AND ToDate > @Today
			END
			ELSE
			BEGIN
				UPDATE WhiteLabelSetting WITH (ROWLOCK, UPDLOCK)
				SET @FromDate=FromDate
					,ToDate = @Today
					,RepUpdateTime=dbo.f_GetDateTime2()
				WHERE custid = @CustId AND ToDate > @Today

				INSERT INTO WhiteLabelSetting (GroupID, CustID, AgentRate, MasterRate, SuperRate, HeadlineRate, FromDate, Remark, RepUpdateTime)
				SELECT GroupID, CustID, @AgentRate, @MasterRate, @SuperRate, @HeadlineRate, DATEADD(DAY, 1, @Today), @Remark, dbo.f_GetDateTime2()
				FROM WhiteLabelSetting WITH(NOLOCK)
				WHERE CustID=@CustID AND FromDate=@FromDate
			END
		END
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	--Writelog
	SELECT  @LogData = (SELECT wi.WhiteLabel
								, CONVERT(VARCHAR(10), COALESCE(@GroupHeadlineID,0)) AS GroupID
								, CONVERT(DATE, @LaunchedDate) AS LaunchedDate
								, CONVERT(VARCHAR(50), @AgentRate)	AS AgentRate
								, CONVERT(VARCHAR(50), @MasterRate)	AS MasterRate
								, CONVERT(VARCHAR(50), @SuperRate)	AS SuperRate
								, CONVERT(VARCHAR(50), @HeadlineRate) AS HeadlineRate
								, CONVERT(VARCHAR(50), @Remark)		AS Remark
								, CONVERT(VARCHAR(20), @IP)			AS IP
							FROM WhiteLabelInfo wi WITH (NOLOCK) 
							WHERE wi.CustID=@CustID
							FOR XML RAW('Acc_WhiteLabelSetting_Upd')
						) 

	SELECT	@duration = DATEDIFF(MILLISECOND, @startRun, GETDATE())

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 711,
		@TrackingValue = @LogData,
		@TrackingValue2 = @LogDataOld,
		@duration = @Duration	
END
GO