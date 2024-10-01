/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdSynced]  
	@CustID			INT
	,@bitmap		TINYINT = 1
	,@Language		VARCHAR(2)		= 'E'
	,@IP			VARCHAR(50)		= ''
	,@ActionID		INT				= 6067
	,@ErrCode		INT				= 0	 OUTPUT
	,@ErrMsg		NVARCHAR(4000)	= '' OUTPUT
AS  
/*  
	Creator: 20241001@Tacy  
	Task : Custinfo synced into Nova Casino.
	DB: DBCUST/CustDB

	Revisions:  
		- 20241001@Tacy: Create SP [Redmine: #211405]
	
	Param's Explanation:
		@bitmap = 1 ~ NovaCasino
*/
BEGIN
    SET NOCOUNT ON;

	DECLARE @LogData NVARCHAR(MAX)
			, @startRun DATETIME
			, @duration INT
			, @IsSynced	BIT = 0

	SELECT	@startRun = GETDATE()

	EXEC [dbo].[Acc_CustomerCheckSynced]  
			@CustID		= @CustID,
			@bitmap		= @bitmap,
			@IsSynced	= @IsSynced OUTPUT

	IF @IsSynced=1 
		RETURN

	DECLARE @roleid tinyint

	SELECT @roleid = roleid 
	FROM custinfo WITH (nolock)
	WHERE custid = @custid AND Enabled=1

	IF @RoleID is null OR @roleid NOT IN (2,3,4)
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user '
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
			@ErrCode = 100
		RETURN
	END

	BEGIN TRY
		IF @RoleID=4
		BEGIN
			UPDATE c
			SET IsSynced=CAST(dbo.f_GenerateProductStatus(c.IsSynced, @bitmap, 1) AS binary(2))
				,RepUpdateTime=dbo.f_GetDateTime2()
			FROM CustSuper c WITH (ROWLOCK, UPDLOCK)
			WHERE CustID=@CustID
		END
		ELSE IF @RoleID=3
		BEGIN
			UPDATE c
			SET  IsSynced=CAST(dbo.f_GenerateProductStatus(c.IsSynced, @bitmap, 1) AS binary(2))
				,RepUpdateTime=dbo.f_GetDateTime2()
			FROM CustMaster c WITH (ROWLOCK, UPDLOCK)
			WHERE CustID=@CustID
		END
		ELSE IF @RoleID=2
		BEGIN
			UPDATE c
			SET  IsSynced=CAST(dbo.f_GenerateProductStatus(c.IsSynced, @bitmap, 1) AS binary(2))
				,RepUpdateTime=dbo.f_GetDateTime2()
			FROM CustAgent c WITH (ROWLOCK, UPDLOCK)
			WHERE CustID=@CustID
		END
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	--Writelog
	SELECT  @LogData = (SELECT @CustID AS CustID
							, @RoleID AS roleid
							, 1 AS IsApplied
							, COALESCE(CAST(@IP AS VARCHAR(50)),SPACE(1)) AS IP
						FOR XML RAW('Age_CustomerUpdSynced')
						) 

	SELECT	@duration = DATEDIFF(MILLISECOND, @startRun, GETDATE())

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @CustID,
		@CustID = @CustID,
		@ActionID = @ActionID,
		@TrackingValue = @LogData,
		@duration = @Duration	
END
GO