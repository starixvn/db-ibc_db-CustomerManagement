/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[EAS_CustomerUpdIsHideIP_Multiple]
    @CustIDList VARCHAR(MAX)
	,@isHideIP	BIT				= 0
	,@IP		NVARCHAR(15)	= ''
	,@userid	INT
	,@ErrMsg	NVARCHAR(MAX)	= '' OUTPUT
AS
/*  
	Created: 20251113@Dave
	Task: Update multiple Customer's isHideIP field
	DB: DBCust/Custdb

	Revisions: 
		- 20251113@Dave: EXT - Allow Headline to hide IP info of their downlines [Redmine: #243331]
	
	Parameter's Explanation:
		@ErrMsg: Error description.
		@ErrMsg = <Root>
						<Error CustID="20650722" ErrCode="101" ErrMsg="Error! Error when updating Message Customer Read Status."/>
					</Root>
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@oldValue VARCHAR(MAX)
		,@newValue VARCHAR(MAX)
		,@ActionID INT
		,@oldisHideIP BIT
		,@CustId INT;

	DECLARE @TempErrMsg NVARCHAR(1000);
	DECLARE @TempErrCode INT;
	
	SET @ErrMsg = '<ROOT>';
	
	SELECT @startRun = GETDATE()
		,@ActionID = 849;

	DECLARE @tblCust TABLE (
		 CustID		INT PRIMARY KEY
		,IsFinished BIT DEFAULT(0)
	);

	--Parse CustID
	INSERT INTO @tblCust (CustID)
	SELECT CONVERT(INT, value)
	FROM string_split(@CustIDList, ',')
	WHERE value <> '';

	--Update info
	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (1) T
		SET	t.IsFinished=1
			,@CustID = CustID
		FROM @tblCust t
		WHERE IsFinished=0;

		IF @@ROWCOUNT = 0 BREAK;
		
		SELECT @TempErrCode = NULL, @TempErrMsg = NULL;

		--Check disable user
		EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid,
			@ErrCode = @TempErrCode OUTPUT, @ErrMsg = @TempErrMsg OUTPUT;

		IF @TempErrCode <> 0 
		BEGIN
			SET @ErrMsg += '<Error CustID="' + CAST(@CustID AS VARCHAR(30))
						+ '" ErrCode="' + CAST(ISNULL(@TempErrCode,'0') AS VARCHAR(5))
						+ '" ErrMsg="' + ISNULL(@TempErrMsg,'') + '" />';
							
			CONTINUE;
		END

		SELECT @oldIsHideIP = ISNULL(isHideIP,0)
		FROM [dbo].[CustSuper] WITH (NOLOCK)
		WHERE custid = @CustId;

		BEGIN TRY
			UPDATE [dbo].[CustSuper] WITH (ROWLOCK, UPDLOCK)
			SET [isHideIP] = ISNULL(@IsHideIP,@oldIsHideIP)
				,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @CustId;

		END TRY
		BEGIN CATCH
			SELECT @TempErrMsg = 'Error! Error when updating Message Customer Read Status.'
				,@TempErrCode = 101;

			SET @ErrMsg += '<Error CustID="' + CAST(@CustID AS VARCHAR(30))
						+ '" ErrCode="' + CAST(ISNULL(@TempErrCode,'0') AS VARCHAR(5))
						+ '" ErrMsg="' + ISNULL(@TempErrMsg,'') + '" />';
		END CATCH

		SELECT @oldValue = '<EAS_CustomerUpdIsHideIP_Multiple isHideIP="' + COALESCE(CAST(@oldIsHideIP AS VARCHAR(1)), SPACE(1))
						+ '" IP="' + COALESCE(@IP, SPACE(1));

		SELECT @newValue = '<EAS_CustomerUpdIsHideIP_Multiple isHideIP="'  + COALESCE(CAST(ISNULL(@IsHideIP,@oldIsHideIP) AS VARCHAR(1)), SPACE(1))
						+ '" IP="' + COALESCE(@IP, SPACE(1));

		SET @endRun = GETDATE();
		SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun);

		DECLARE @tempNewValue NVARCHAR(MAX)
			,@tempOldValue NVARCHAR(MAX);

		SELECT @tempNewValue = @newValue + '" ErrCode="' + COALESCE(CAST(@TempErrCode AS VARCHAR(50)), space(1)) + '" ErrMsg="' + COALESCE(@TempErrMsg, space(1)) + '" />'
			,@tempOldValue = @oldValue + '" ErrCode="' + COALESCE(CAST(@TempErrCode AS VARCHAR(50)), space(1)) + '" ErrMsg="' + COALESCE(@TempErrMsg, space(1)) + '" />';

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
			@UserID = @userid
			,@CustID = @CustId
			,@ActionID = @ActionID
			,@TrackingValue = @tempNewValue
			,@TrackingValue2 = @tempOldValue
			,@duration = @duration;

	END

	SET @ErrMsg += '</ROOT>'
END
GO