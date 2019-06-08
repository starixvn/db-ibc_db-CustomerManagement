/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_CustomerStatusUpd]	
	@CustID			INT,
	@OldStatusID	TINYINT, --4: Active, 3: View Only, 2: Suspended, 1: Inactive
	@NewStatusID	TINYINT,
	@UserId			INT,
	@SubAccId		INT = 0,
	@IP				VARCHAR(15) = '',
	@Language		VARCHAR(2) = 'E',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS
/*  
	Created by: Paul  
	Date: 2019-05-14
	Task: Update status of CN88's customer
	DB: DBCUST/CustDB
	
	Revisions:
		- 20190514@Paul: Create new SP [RedmineID: #113198]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @Duration INT	
	DECLARE @Mode TINYINT, --1: A to I, 2: I to A, 3: A to S, 4: S to A, 5: A to V, 6: V to A
			@RoleID TINYINT, @db_OldStatusID TINYINT, @UserStatus TINYINT, @UplineID INT, @AffectedList VARCHAR(MAX)

	SELECT  @StartRun = GETDATE()

	-- Check disable account
	EXEC dbo.Acc_CustomerSelCheckEnable
		@CustId		= @CustId,
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF @UserID <> @CustID AND CURRENT_USER <> 'bodbAdminNet' AND EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE custid = @CustID AND LockUpd = 1 AND roleid = 1)
	BEGIN
		SELECT  @ErrMsg = CASE @language WHEN 'E' THEN 'You are currently not authorized to perform this action. Please contact the Customer Service Department for further assistance.' 
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40033,@Language) END,
				@ErrCode = 101
		RETURN
	END

	SELECT	@RoleID = roleid,			
			@UplineID = CASE roleid WHEN 3 THEN srecommend
									WHEN 2 THEN mrecommend
									WHEN 1 THEN recommend END
	FROM custInfo WITH(NOLOCK)
	WHERE CustID = @CustID

	IF @RoleID = 4
	BEGIN
		SELECT @UplineID = UplineId FROM dbo.CustSuper WITH (NOLOCK) WHERE custid = @CustID
	END

	IF ISNULL(@RoleId, 0) NOT BETWEEN 1 AND 4
	BEGIN
		SELECT  @ErrMsg = CASE @language WHEN 'E' THEN 'Invalid user!!' 
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
				@ErrCode = 102
		RETURN
	END

	SELECT @db_OldStatusID = CustStatus FROM dbo.f_CS_GetCustomerStatus (@CustID)

	IF @db_OldStatusID = @NewStatusID
	BEGIN		
		RETURN
	END

	IF @db_OldStatusID <> @OldStatusID
	BEGIN
		SELECT  @ErrMsg = CASE @language WHEN 'E' THEN 'Update account status failed, Please try again.' ELSE [dbo].[f_Get_MsgNamebyMsgID](40046,@Language) END,
				@ErrCode = 102
		RETURN
	END

	-- Check allowed downlines during peak hour at weekend
	EXEC dbo.Acc_CustomerSelCheckAllowedDownlines
		@CustId		= @CustId,
		@RoleId		= @RoleId,
		@isExecRep	= 1,
		@Language	= @Language,
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
		
	IF @ErrCode <> 0
		RETURN

	SELECT @UserStatus = CustStatus FROM dbo.f_CS_GetCustomerStatus(@UserId)

	IF @UserStatus <> 4
	BEGIN
		SELECT  @ErrMsg = CASE @language WHEN 'E' THEN 'Update status failed. Upline level is not active.' ELSE [dbo].[f_Get_MsgNamebyMsgID](40043,@Language) END,
				@ErrCode = 103
		RETURN
	END

	SELECT	@OldStatusID = ISNULL(@OldStatusID, 0),
			@NewStatusID = ISNULL(@NewStatusID, 0)

	SELECT @Mode = CASE @OldStatusID 
						WHEN 4 THEN CASE @NewStatusID 
										WHEN 1 THEN 1
										WHEN 2 THEN 3
										WHEN 3 THEN 5
										ELSE 0
									END
						WHEN 1 THEN CASE @NewStatusID WHEN 4 THEN 2 ELSE 0 END
						WHEN 2 THEN CASE @NewStatusID WHEN 4 THEN 4 ELSE 0 END
						WHEN 3 THEN CASE @NewStatusID WHEN 4 THEN 6 ELSE 0 END
						ELSE 0
					END;

	IF @Mode = 0
	BEGIN
		SELECT  @ErrMsg = CASE @language WHEN 'E' THEN ' Update account status failed, Please try again.' ELSE [dbo].[f_Get_MsgNamebyMsgID](40046,@Language) END,
				@ErrCode = 102
		RETURN
	END

	EXEC dbo.CS_DynamicCustomerInfo_01
		@CustId			= @CustId,
		@RoleId			= @RoleId,
		@Action			= 'UpdateStatus',
		@Mode			= @Mode,
		@AffectedList	= @AffectedList OUTPUT

	SELECT @Duration = DATEDIFF (MILLISECOND, @startRun, GETDATE())

	-- Write log
	DECLARE @LogDataOld VARCHAR(500), @LogDataNew VARCHAR(500)
	SELECT  @LogDataOld = '<R'
						+ ' Status="' + COALESCE(CASE @OldStatusID WHEN 1 THEN 'I' WHEN 2 THEN 'S' WHEN 3 THEN 'V' WHEN 4 THEN 'A' END, SPACE(1)) + '"'
						+ ' SubAcc="' + COALESCE(dbo.f_GetSubUsername(@SubAccID), SPACE(1)) + '"'
						+ ' IP="' + COALESCE(@IP, SPACE(1)) + '"'
						+ ' />',
			@LogDataNew = '<R'
						+ ' Status="' + COALESCE(CASE @NewStatusID WHEN 1 THEN 'I' WHEN 2 THEN 'S' WHEN 3 THEN 'V' WHEN 4 THEN 'A' END, SPACE(1)) + '"'
						+ ' SubAcc="' + COALESCE(dbo.f_GetSubUsername(@SubAccID), SPACE(1)) + '"'
						+ ' IP="' + COALESCE(@IP, SPACE(1)) + '"'
						+ ' />'
	
	EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @UserId,
		@CustId				= @CustId,
		@SubAccID			= @SubAccID,
		@ActionId			= 165004,
		@TrackingValue		= @LogDataNew,
		@TrackingValue2		= @LogDataOld,
		@Duration			= @Duration,
		@AffectedDownlines	= @AffectedList
	
END
GO