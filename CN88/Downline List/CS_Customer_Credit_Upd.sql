/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,bodbDownlineNet,wsv_alp" isFunction="0" isNested="0"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[CS_Customer_Credit_Upd]
	@UserId		INT,
	@SubAccId	INT,
	@CustId		INT,
	@UpdCredit	MONEY,
	@IP			VARCHAR(15) = '',
	@Language	VARCHAR(2) = 'E',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181218@Percy
	DB: DBCUST/CustDB
	Task: Member Information >> Downline List >> Update Given Credit

	Revisions:
		- 20181218@Percy: Initialize SP [RedmineID: #105338]
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
		- 20190715@Elodie: Change content of error msg [Redmine:#115515]
		- 20190715@Elodie: Support Chinese log [Redmine:#116317]
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @UpdCredit = ISNULL(@UpdCredit, 0)

	DECLARE @srecommend INT, @mrecommend INT, @recommend INT
	DECLARE @username NVARCHAR(50), @RoleId TINYINT, @Credit MONEY, @UsedCredit MONEY, @BetCredit MONEY
	DECLARE @UplineCredit MONEY, @UplineUsedCredit MONEY
	DECLARE @MinCredit MONEY, @MaxCredit MONEY

	SELECT  @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend,
			@username = username, @RoleId = roleId, @Credit = ISNULL(credit, 0)
	FROM dbo.custInfo WITH (NOLOCK) WHERE custId = @custId

	IF ISNULL(@RoleId, 0) NOT BETWEEN 1 AND 4
	BEGIN
		-- Invalid user!!
		SELECT @ErrCode = 101, @ErrMsg = dbo.f_Get_MsgNamebyMsgID (40002, @Language)
		RETURN
	END

	IF ISNULL(@Credit, 0) = ISNULL(@UpdCredit, 0)
	BEGIN
		-- Data not change
		RETURN
	END

	IF @RoleId = 4
	BEGIN
		SELECT	@UsedCredit	= SUM(ISNULL(credit, 0))
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE srecommend = @srecommend
			AND roleId = 3
		
		SELECT	@MinCredit = ISNULL(@UsedCredit, 0)
	END
	ELSE IF @RoleId = 3
	BEGIN
		SELECT	@UplineCredit		= SUM(CASE WHEN roleId = 4 THEN ISNULL(credit, 0) ELSE 0 END),
				@UplineUsedCredit	= SUM(CASE WHEN roleId = 3 THEN ISNULL(credit, 0) ELSE 0 END),
				@UsedCredit			= SUM(CASE WHEN mrecommend = @custId AND roleId = 2 THEN ISNULL(credit, 0) ELSE 0 END) 
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE srecommend = @srecommend

		SELECT	@MinCredit = ISNULL(@UsedCredit, 0),
				@MaxCredit = ISNULL(@UplineCredit, 0) - ISNULL(@UplineUsedCredit, 0) + ISNULL(@Credit, 0)
	END
	ELSE IF @RoleId = 2
	BEGIN
		SELECT	@UplineCredit		= SUM(CASE WHEN roleId = 3 THEN ISNULL(credit, 0) ELSE 0 END),
				@UplineUsedCredit	= SUM(CASE WHEN roleId = 2 THEN ISNULL(credit, 0) ELSE 0 END),
				@UsedCredit			= SUM(CASE WHEN recommend = @custId AND roleId = 1 THEN ISNULL(credit, 0) ELSE 0 END) 
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE mrecommend = @mrecommend

		SELECT	@MinCredit = ISNULL(@UsedCredit, 0),
				@MaxCredit = ISNULL(@UplineCredit, 0) - ISNULL(@UplineUsedCredit, 0) + ISNULL(@Credit, 0)
	END	
	
	-- SP check on SMA/MA/Agent, web check Member
	IF (@RoleId IN (2,3) AND @UpdCredit NOT BETWEEN @MinCredit AND @MaxCredit)
		OR (@RoleId = 4 AND @UpdCredit < @MinCredit) -- SMA not have MaxCredit
	BEGIN
		-- New Credit is out of range, please refresh the form and try again.
		SELECT @ErrCode = 103, @ErrMsg = dbo.f_Get_MsgNamebyMsgID (70026, @Language)

		RETURN
	END

	BEGIN TRY
		UPDATE dbo.custInfo WITH (ROWLOCK, UPDLOCK)
		SET credit = @UpdCredit
			,CreditUpdatedDate = GETDATE()
		WHERE custId = @custId
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful.
		SELECT @ErrCode = 104, @ErrMsg = dbo.f_Get_MsgNamebyMsgID (90001, @Language)
		RETURN
	END CATCH

	-- Write log
	DECLARE @ActionId INT, @levelName VARCHAR(20), @LogData VARCHAR(500)
	SELECT  @ActionId = CASE @RoleId
							WHEN 1 THEN 1217
							WHEN 2 THEN 1218
							WHEN 3 THEN 1219
							WHEN 4 THEN 1220
							END
			,@levelName = CASE @RoleID WHEN 1 THEN '{Member}:' WHEN 2 THEN '{Agent}:' WHEN 3 THEN '{MA}:' WHEN 4 THEN '{SMA}:' END  
	
	SELECT  @LogData = @levelName + @username + ' - {CreditUpdated}'

	IF @SubAccId > 0
		SELECT  @LogData = @levelName + @username + ' - {CreditUpdatedBySubAcc} ' + COALESCE(dbo.f_GetSubUsername(@SubAccId), SPACE(1))

	EXEC dbo.CS_WriteLog_UserLog_Credit_Wrapper
		@UserId		= @UserId,
		@CustId		= @CustId,
		@SubAccId	= @SubAccId,
		@Doing		= @LogData,
		@OldValue	= @Credit,
		@NewValue	= @UpdCredit,
		@IP			= @IP,
		@ActionId	= @ActionId
END
GO