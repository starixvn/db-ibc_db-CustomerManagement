/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerDateLimitDel] @userId INT
	,@custId INT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20180429@Razor
	DB: DBCUST-CUSTDB
	Task: 

	Revisions:
		-20180529@Razor: init - [Readmine: #96025]
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		
	Param's Explanation:		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@LogSPData VARCHAR(max)
		,@ActionID INT
		,@minDate DATETIME
		,@limitDays INT

	SELECT @startRun = GETDATE()
		,@ActionID = 31502

	SELECT @minDate = MinDate
		,@limitDays = LimitDays
	FROM dbo.Age_CustDateLimit WITH (NOLOCK)
	WHERE CustId = @custID

	IF (
			EXISTS (
				SELECT 1
				FROM dbo.Age_CustDateLimit WITH (NOLOCK)
				WHERE CustId = @custID
				)
			)
	BEGIN
		BEGIN TRY
			DELETE
			FROM dbo.Age_CustDateLimit
			WHERE CustId = @custID
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg = 'Error! Error when deleting customer date limit.'
				,@ErrCode = 101
		END CATCH

		SELECT @LogSPData = '<Acc_CustomerDateLimitDel custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' + 'LimitDays="' + COALESCE(CAST(@limitDays AS VARCHAR(10)), SPACE(1)) + '" ' + 'minDate="' + COALESCE(CAST(@minDate AS VARCHAR(20)), SPACE(1)) + '" ' + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' + 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'

		SET @endRun = GETDATE()
		SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @userID
			,@CustID = @custID
			,@ActionID = @ActionID
			,@TrackingValue = @LogSPData
			,@duration = @duration
	END
	ELSE
	BEGIN
		SELECT @ErrMsg = 'This customer had been deleted.'
				,@ErrCode = 102
	END
END
GO


