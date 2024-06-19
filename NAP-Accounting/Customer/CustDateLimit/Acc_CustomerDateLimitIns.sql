/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerDateLimitIns] @userId INT
	,@custName NVARCHAR(100)
	,@limitDays INT = NULL
	,@minDate DATETIME = NULL
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20180429@Razor
	DB: DBCUST/CUSTDB
	Task: 

	Revisions:
		-20180429@Razor: init - [Readmine: #96025]
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
		,@custID INT

	SELECT @startRun = GETDATE()
		,@ActionID = 31501

	SELECT @custID = custID
	FROM [dbo].[custInfo] WITH (NOLOCK)
	WHERE userName = @custName

	IF (ISNULL(@custID, 0) = 0)
	BEGIN
		SELECT @ErrMsg = 'Error! Do not exist user name = ' + @custName
			,@ErrCode = 102

		RETURN
	END

	IF (
			EXISTS (
				SELECT 1
				FROM dbo.Age_CustDateLimit WITH (NOLOCK)
				WHERE CustId = @custId
				)
			)
	BEGIN
		SELECT @ErrMsg = 'Error! existed setting for user name = ' + @custName
			,@ErrCode = 103

		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.Age_CustDateLimit (
			CustId
			,MinDate
			,LimitDays
			)
		VALUES (
			@custId
			,@minDate
			,@limitDays
			)
	END TRY

	BEGIN CATCH
		SELECT @ErrMsg = 'Error! Error when adding customer date limit.'
			,@ErrCode = 101
	END CATCH

	SELECT @LogSPData = '<Acc_CustomerDateLimitIns custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' + 'LimitDays="' + COALESCE(CAST(@limitDays AS VARCHAR(10)), SPACE(1)) + '" ' + 'minDate="' + COALESCE(CAST(@minDate AS VARCHAR(20)), SPACE(1)) + '" ' + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' + 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @userID
		,@CustID = @custID
		,@ActionID = @ActionID
		,@TrackingValue = @LogSPData
		,@duration = @duration
END
GO


