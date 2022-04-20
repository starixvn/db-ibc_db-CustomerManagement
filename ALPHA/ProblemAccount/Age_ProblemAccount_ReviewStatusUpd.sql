/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Age_ProblemAccount_ReviewStatusUpd]
	@UserId					INT,
	@SubAccId				INT = 0,
	@RoleId					TINYINT,
	@CustomerList			VARCHAR(MAX) = '',
	@IsAffectedAllDownlines	BIT = 0,
	@Language				VARCHAR(2) = 'E',
	@LoginIP				VARCHAR(20) = '',
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200210@Elodie
	DB: DBCUST/CustDB
	Task: Problem Accounts

	Revisions:
		- 20200210@Elodie: Initial SP [Redmine:#127446]
		- 20200306@Elodie: Allow view problem account for master and agent [Redmine:#129881]
		- 20210422@Johnson: change source ProblemAccount to ProblemAccountClassification [redmine:#153059]
		- 20220228@Johnson: add new category for good/bad robot[redmine:#167726]
		- 20220418@Johnson: Change datasource for problem account [redmine:#170692]
	Param's Explanation:
		@UserId: Customer login
		@SubAccId: SubAccount Id
		@RoleId:
			3: Master Agent
			2: Agent
			1: Member
		@CustomerList: list of downline id
		@ErrCode:
			= 0: Update successfully.
			> 0: Specific Error.
		@ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	CREATE TABLE #Downlines(CustId INT)
	DECLARE @CustId INT, @ActionId INT, @SuccessDownlineList VARCHAR(MAX) = '', @UserRoleId TINYINT
	DECLARE @StartRun DATETIME, @Duration INT, @LogDataNew VARCHAR(500), @LogDataOld VARCHAR(500)

	SET @startRun = GETDATE()

	INSERT INTO #Downlines(CustId)
	SELECT CONVERT(INT, Val)
	FROM dbo.f_StringSplit(@CustomerList, ',')
	OPTION(MAXRECURSION 0)

	SELECT @UserRoleId = roleId FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @UserId

	IF EXISTS (SELECT 1
				FROM #Downlines d
					INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON d.CustId = ci.custid
				WHERE ci.roleid <> @RoleId 
					OR (@UserRoleId = 4 AND ci.srecommend <> @UserId) 
					OR (@UserRoleId = 3 AND ci.mrecommend <> @UserId) 
					OR (@UserRoleId = 2 AND ci.recommend <> @UserId))
	BEGIN
		--Action failed. Please try again.
		SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40049, @Language), @ErrCode = 106
		RETURN
	END

	IF @RoleId = 3
	BEGIN
		SELECT @ActionId = 31620
	END
	ELSE IF @RoleId = 2
	BEGIN
		SELECT @ActionId = 31621
	END
	ELSE IF @RoleId = 1
	BEGIN
		SELECT @ActionId = 31622
	END

	CREATE TABLE #tempCust(CustId INT, IsFinished BIT DEFAULT(0))

	INSERT INTO #tempCust(CustId)
	SELECT d.custid
	FROM #Downlines d
		INNER JOIN custInfo ci WITH(NOLOCK) ON d.custid = ci.custid
		INNER JOIN dbo.ProblemAccountClassification pa WITH (NOLOCK) ON d.CustId = pa.CustId
	WHERE pa.IsReviewed = 0 
		AND ci.CustomerClass IN (SELECT CustomerClass FROM CategoryConfig WITH(NOLOCK))
		--AND (pa.ReasonId IS NOT NULL OR pa.IsAbnormalMember = 1)

	UPDATE pa
	SET pa.IsReviewed = 1
	FROM dbo.ProblemAccountClassification pa WITH (NOLOCK)
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
			EXEC dbo.Acc_CustomerInfo_Execrep_12
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
				
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @UserId,
			@CustId				= @CustId,
			@ActionId			= @ActionId,
			@TrackingValue		= @LogDataNew,
			@TrackingValue2		= @LogDataOld,
			@Duration			= @Duration,
			@AffectedDownlines	= @SuccessDownlineList
	END
END