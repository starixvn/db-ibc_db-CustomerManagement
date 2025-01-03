/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_ProblemAccount_ReviewStatusUpd]
	@CustomerList			VARCHAR(MAX) = '',	
	@RoleId					TINYINT,	
	@GroupName				VARCHAR(50) = '',
	@IsAffectedAllDownlines	BIT = 0,
	
	@UserId					INT = 0,
	@Language				VARCHAR(2) = 'E',
	@IP						VARCHAR(20) = '',
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20201012@@Johnson
	DB: DBCUST/CustDB
	Task: Problem Accounts

	Revisions:
		- 20201012@Johnson: Initial SP [Redmine:#142957]		
		- 20210426@Johnson: change source ProblemAccount to ProblemAccountClassification [redmine:#153059]
		- 20220228@Johnson: add new category for good/bad robot[redmine:#167726]
		- 20220418@Johnson: Change datasource for problem account [redmine:#170692]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20241118@Tacy: New CC for SMA [Redmine: #212681]
		- 20240807@Helios: Scale Out DBCUST - Apply Inhouse replication for tables of problem account [Redmine:#209747]
	Param's Explanation:		
		@RoleId: roleid of downlines
		@CustomerList: list of downline id
		@ErrCode:
			= 0: Update successfully.
			> 0: Specific Error.
		@ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #Downlines(CustId INT)
	DECLARE @tmpSuper TABLE (custid INT PRIMARY KEY)
	DECLARE @CustId INT, @ActionId INT, @SuccessDownlineList VARCHAR(MAX) = ''
	DECLARE @StartRun DATETIME, @Duration INT, @LogDataNew VARCHAR(500), @LogDataOld VARCHAR(500)
	
	
	INSERT INTO @tmpSuper(custid)
	SELECT custid
	FROM dbo.Acc_CustGroup WITH(NOLOCK)
	WHERE GroupName = @GroupName
	
	SET @startRun = GETDATE()

	INSERT INTO #Downlines(CustId)
	SELECT CONVERT(INT, value)
	FROM STRING_SPLIT(@CustomerList, ',')
	WHERE value <> ''

	IF EXISTS (SELECT 1
				FROM #Downlines d
					INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON d.CustId = ci.custid
				WHERE ci.roleid <> @RoleId 
					AND srecommend IN (SELECT custid FROM @tmpSuper)
			)		
	BEGIN
		--Action failed. Please try again.
		SELECT @ErrMsg = [dbo].[f_Get_MsgNamebyMsgID](40049, @Language), @ErrCode = 106
		RETURN
	END

	SELECT @ActionId = CASE @roleid WHEN 3 THEN 31634
									WHEN 2 THEN 31635
									WHEN 1 THEN 31636 END
	
	CREATE TABLE #tempCust(CustId INT, IsFinished BIT DEFAULT(0))

	INSERT INTO #tempCust(CustId)
	SELECT d.custid
	FROM #Downlines d
		INNER JOIN custInfo ci WITH(NOLOCK) ON ci.custid = d.custid
		INNER JOIN dbo.ProblemAccountClassification pa WITH (NOLOCK) ON d.CustId = pa.CustId
	WHERE pa.IsReviewed = 0  AND ci.roleid=1
		--AND (pa.ReasonId IS NOT NULL OR pa.IsAbnormalMember = 1)
		AND ci.CustomerClass IN (SELECT CustomerClass FROM CategoryConfig WITH(NOLOCK))
	UNION ALL 
	SELECT d.custid
	FROM #Downlines d
		INNER JOIN custInfo ci WITH(NOLOCK) ON d.custid = ci.custid
		INNER JOIN dbo.ProblemAccountClassification pa WITH (NOLOCK) ON d.CustId = pa.CustId
		INNER JOIN CustomerClassSetting_Agent ca WITH (NOLOCK) ON ca.custid=d.CustId AND ca.SportType=0
	WHERE pa.IsReviewed = 0 AND ci.roleid BETWEEN 2 AND 4
		AND ca.CustomerClass IN (SELECT CustomerClass FROM CategoryConfig WITH(NOLOCK))

	UPDATE pa
	SET pa.IsReviewed = 1 , pa.RepUpdateTime=[dbo].[f_GetDateTime2]()
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
							'AllDownline="' + COALESCE(CAST(@IsAffectedAllDownlines as VARCHAR(1)),SPACE(1)) + '" ' +
							'IP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" />'

		SELECT @LogDataNew = '<R ReviewStatus="1" ' +							
							'AllDownline="' + COALESCE(CAST(@IsAffectedAllDownlines as VARCHAR(1)),SPACE(1)) + '" ' +
							'IP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" />'

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