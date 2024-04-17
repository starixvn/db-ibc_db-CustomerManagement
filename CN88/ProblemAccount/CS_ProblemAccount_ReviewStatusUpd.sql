/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CS_ProblemAccount_ReviewStatusUpd]
	@UserId					INT,
	@SubAccId				INT = 0,
	@RoleId					TINYINT,
	@IsAllDownline			BIT = 0,
	@CustomerList			VARCHAR(MAX) = '',
	@IsAffectedAllDownlines	BIT = 0,
	@Language				VARCHAR(2) = 'E',
	@LoginIP				VARCHAR(20) = '',
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20190812@Alvin
	DB: DBCUST/CustDB
	Task: Problem Accounts

	Revisions:
		- 20190806@Alvin: Initialize SP [RedmineID: #116814]
		- 20190918@Alvin: Hide indirect marked on Problem Account
		- 20191218@Percy: Change using SP CS_DynamicCustSetting_01 to CS_DynamicCustomerInfo_02 [RedmineID: #125186]
		
	Param's Explanation:
		@CustId: Super login
		@SubAccId: SubAccount Id
		@RoleId:
			3: Master Agent
			2: Agent
			1: Member
		@IsAllDownline: is view all downlines
		@CustomerList: list of downline id
		@ErrCode:
			= 0: Update successfully.
			> 0: Specific Error.
		@ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	CREATE TABLE #Downlines(CustId INT)
	DECLARE @CustId INT, @ActionId INT, @SuccessDownlineList VARCHAR(MAX) = ''
	DECLARE @StartRun DATETIME, @Duration INT, @LogDataNew VARCHAR(500), @LogDataOld VARCHAR(500)

	SET @startRun = GETDATE()

	INSERT INTO #Downlines(CustId)
	SELECT CONVERT(INT, Val)
	FROM dbo.f_StringSplit(@CustomerList, ',')
	OPTION(MAXRECURSION 0)

	IF @SubAccId > 0 AND @IsAllDownline = 0
	BEGIN
		IF EXISTS(SELECT 1 
					FROM #Downlines d
					INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON d.CustId = ci.custid
					WHERE ci.roleid <> @RoleId 
						OR ci.srecommend <> @UserId 
						OR NOT EXISTS(SELECT DownlineId 
									FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s 
									WHERE (@RoleId = 3 AND s.DownlineId = ci.custid)
										OR (@RoleId <> 3 AND s.DownlineId = ci.mrecommend)))
		BEGIN
			--Action failed. Please try again.
			SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40049, @Language), @ErrCode = 106
			RETURN
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1
					FROM #Downlines d
						INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON d.CustId = ci.custid
					WHERE ci.roleid <> @RoleId OR ci.srecommend <> @UserId)
		BEGIN
			--Action failed. Please try again.
			SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40049, @Language), @ErrCode = 106
			RETURN
		END
	END

	IF @RoleId = 3
	BEGIN
		SELECT @ActionId = 31608
	END
	ELSE IF @RoleId = 2
	BEGIN
		SELECT @ActionId = 31609
	END
	ELSE IF @RoleId = 1
	BEGIN
		SELECT @ActionId = 31610
	END

	CREATE TABLE #tempCust(CustId INT, IsFinished BIT DEFAULT(0))

	INSERT INTO #tempCust(CustId)
	SELECT d.custid
	FROM #Downlines d
		INNER JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON d.CustId = pa.CustId
	WHERE pa.IsReviewed = 0 AND (pa.ReasonId IS NOT NULL OR pa.IsAbnormalMember = 1)

	UPDATE pa
	SET pa.IsReviewed = 1
	FROM dbo.CS_ProblemAccount pa WITH (NOLOCK)
		INNER JOIN #tempCust t ON pa.CustId = t.CustId
	
	WHILE (1=1)
	BEGIN
		UPDATE TOP (1) #tempCust
		SET IsFinished = 1,
		@CustId = CustId
		WHERE IsFinished = 0

		IF @@ROWCOUNT = 0 BREAK

		IF @RoleId <> 1 AND @IsAffectedAllDownlines = 1
		BEGIN
			EXEC dbo.CS_DynamicCustomerInfo_02
			@CustId = @CustId,
			@RoleId = @RoleId,
			@Action = 'UpdateReviewStatus',
			@SuccessDownlineList = @SuccessDownlineList OUTPUT
		END

		-- Write log
		SELECT @LogDataOld = '<R ReviewStatus="0" ' +
							'SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' +
							'AllDownline="' + COALESCE(CAST(@IsAffectedAllDownlines as VARCHAR(1)),SPACE(1)) + '" ' +
							'IP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

		SELECT @LogDataNew = '<R ReviewStatus="1" ' +
							'SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' +
							'AllDownline="' + COALESCE(CAST(@IsAffectedAllDownlines as VARCHAR(1)),SPACE(1)) + '" ' +
							'IP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

		SELECT @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())
				
		EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @UserId,
			@CustId				= @CustId,
			@ActionId			= @ActionId,
			@TrackingValue		= @LogDataNew,
			@TrackingValue2		= @LogDataOld,
			@Duration			= @Duration,
			@AffectedDownlines	= @SuccessDownlineList
	END
END