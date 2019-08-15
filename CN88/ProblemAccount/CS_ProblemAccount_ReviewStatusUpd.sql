/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CS_ProblemAccount_ReviewStatusUpd]
	@UserId					INT,
	@SubAccId				INT = 0,
	@RoleId					TINYINT,
	@IsAllDownline			BIT = 0,
	@DownlineList			VARCHAR(MAX) = '',
	@IsAffectedAllDownlines	BIT = 0,
	@Language				VARCHAR(2) = 'E',
	@LoginIP				VARCHAR(20)='',
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20190812@Alvin
	DB: DBCUST/CustDB
	Task: Problem Accounts

	Revisions:
		- 20190806@Alvin: Initialize SP [RedmineID: #116814]
		
	Param's Explanation:
		@CustId: Super login
		@SubAccId: SubAccount Id
		@RoleId:
			3: Master Agent
			2: Agent
			1: Member
		@IsAllDownline: is view all downlines
		@DownlineList: list of downline id
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

	IF ISNULL(@DownlineList, '') = ''
	BEGIN
		SELECT @ErrCode = 107, @ErrMsg = 'You do not have any Problem Accounts selected. Please select a Problem Account'
		RETURN
	END

	INSERT INTO #Downlines(CustId)
	SELECT CONVERT(INT, Val)
	FROM dbo.f_StringSplit(@DownlineList, ',')
	OPTION(MAXRECURSION 0)

	IF EXISTS (SELECT 1
				FROM #Downlines d
					INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON d.CustId = ci.custid
				WHERE ci.roleid <> @RoleId
					OR (ci.srecommend <> @UserId AND ci.roleid = @RoleId)
					OR (@IsAllDownline = 0 AND NOT EXISTS(SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = d.custid)))
	BEGIN
		--Action failed. Please try again.
		SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40049, @Language), @ErrCode = 106
		RETURN
	END

	CREATE TABLE #tempCust(CustId INT, Username NVARCHAR(50), IsFinished BIT DEFAULT(0))

	INSERT INTO #tempCust(CustId, Username)
	SELECT ci.custid, ci.username 
	FROM #Downlines d
		INNER JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON d.CustId = pa.CustId
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON d.CustId = ci.custid
	WHERE pa.IsReviewed = 0

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
			EXEC dbo.CS_DynamicCustSetting_01
			@CustId = @CustId,
			@RoleId = @RoleId,
			@Action = 'UpdateReviewStatus',
			@SuccessDownlineList = @SuccessDownlineList OUTPUT
		END

		-- Write log
		SELECT @LogDataOld = '<R ReviewStatus="NotReviewed" ' +
							'SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' +
							'IsAllAffectedDownlines="' + COALESCE(CAST(@IsAffectedAllDownlines as VARCHAR(1)),SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

		SELECT @LogDataNew = '<R ReviewStatus="Reviewed" ' +
							'SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' +
							'IsAllAffectedDownlines="' + COALESCE(CAST(@IsAffectedAllDownlines as VARCHAR(1)),SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'
		
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