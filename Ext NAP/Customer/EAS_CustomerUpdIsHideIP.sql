/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[EAS_CustomerUpdIsHideIP]
    @CustId 	INT
	,@isHideIP	BIT				= 0
	,@IP		NVARCHAR(15)	= ''
	,@userid	INT
	,@ErrCode	INT				= 0		OUTPUT
	,@ErrMsg	NVARCHAR(MAX)	= ''	OUTPUT
AS
/*  
	Created: 20251113@Dave
	Task: Update Customer's isHideIP field
	DB: DBCust/Custdb

	Revisions: 
		- 20251113@Dave: EXT - Allow Headline to hide IP info of their downlines [Redmine: #243331]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@oldValue VARCHAR(MAX)
		,@newValue VARCHAR(MAX)
		,@ActionID INT
		,@oldisHideIP BIT;
	
	SELECT @startRun = GETDATE()
		,@ActionID = 848;

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
		SELECT @ErrMsg = 'Error! Error when updating Message Customer Read Status.'
			,@ErrCode = 101;
	END CATCH

	SELECT @oldValue = '<EAS_CustomerUpdIsHideIP isHideIP="' + COALESCE(CAST(@oldIsHideIP AS VARCHAR(1)), SPACE(1))
					+ '" IP="' + COALESCE(@IP, SPACE(1));

	SELECT @newValue = '<EAS_CustomerUpdIsHideIP isHideIP="'  + COALESCE(CAST(ISNULL(@IsHideIP,@oldIsHideIP) AS VARCHAR(1)), SPACE(1))
					+ '" IP="' + COALESCE(@IP, SPACE(1));

	SET @endRun = GETDATE();
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun);

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @userid
		,@CustID = @CustId
		,@ActionID = @ActionID
		,@TrackingValue = @newValue
		,@TrackingValue2 = @oldValue
		,@duration = @duration;

END
GO