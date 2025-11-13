/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerUpdSuperInfo_Multiple] 
    @CustIDList VARCHAR(MAX)
	,@firstname NVARCHAR(50)=NULL
	,@lastname	NVARCHAR(50)=NULL
	,@phone		NVARCHAR(50)=NULL
	,@mobilephone NVARCHAR(50)=NULL
	,@IP		NVARCHAR(15) = ''
	,@userid	INT
	,@ErrMsg	NVARCHAR(MAX) = '' OUTPUT

AS
/*  
	Created: Tacy@20240308
	Task : Update Personal Info
	DB: DBCust/Custdb
	Original: EAS_CustomerUpdSuperInfo

	Revisions: 
		- 20240308@Tacy: Create SP [Redmine: #201432] 
		- 20241209@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
		- 20251113@Dave: EXT - Allow Headline to hide IP info of their downlines - change conditon break LOOP WHILE [Redmine: #243331]
	Parameter's Explanation:
	� @ErrMsg: Error description.
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
		,@oldFirstName VARCHAR(50)
		,@oldLastName VARCHAR(50)
		,@oldPhone VARCHAR(50)
		,@oldMobilephone VARCHAR(50)
		,@CustId INT

	DECLARE @TempErrMsg NVARCHAR(1000)
	DECLARE @TempErrCode INT
	
	SET @ErrMsg = '<ROOT>';
	
	SELECT @startRun = GETDATE()
		,@ActionID = 709

	DECLARE @tblCust TABLE (
		 CustID		INT PRIMARY KEY
		,IsFinished BIT DEFAULT(0)
	)

	--Parse CustID
	INSERT INTO @tblCust (CustID)
	SELECT CONVERT(INT, value)
	FROM string_split(@CustIDList, ',')
	WHERE value <> ''

	--Update info
	WHILE (1 = 1)
	BEGIN
	
		UPDATE TOP (1) T
		SET	t.IsFinished=1
			,@CustID = CustID
		FROM @tblCust t
		WHERE IsFinished=0

		IF @@ROWCOUNT = 0
			BREAK;

		SELECT @TempErrCode = NULL, @TempErrMsg = NULL

		--Check disable user
		EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid,
			@ErrCode = @TempErrCode OUTPUT, @ErrMsg = @TempErrMsg OUTPUT

		IF @TempErrCode <> 0 
		BEGIN
			SET @ErrMsg += '<Error CustID="' + CAST(@CustID AS VARCHAR(30))
						+ '" ErrCode="' + CAST(ISNULL(@TempErrCode,'0') AS VARCHAR(5))
						+ '" ErrMsg="' + ISNULL(@TempErrMsg,'') + '" />'
							
			CONTINUE;
		END

		SELECT @oldFirstName	= FirstName
				,@oldLastName	= LastName
				,@oldPhone		= Phone
				,@oldMobilephone= Mobilephone
		FROM [dbo].[CustSuperProfile] WITH (NOLOCK)
		WHERE custid = @CustId

		BEGIN TRY
			UPDATE [dbo].[CustSuperProfile] WITH (ROWLOCK, UPDLOCK)
			SET [firstname] = ISNULL(@firstname,@oldFirstName)
				,[lastname] = ISNULL(@lastname,@oldLastName)
				,[phone] = ISNULL(@phone,@oldPhone)
				,[mobilephone] = ISNULL(@mobilephone, @oldMobilephone)
				,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @CustId
		END TRY

		BEGIN CATCH
			SELECT @TempErrMsg = 'Error! Error when updating Message Customer Read Status.'
				,@TempErrCode = 101

			SET @ErrMsg += '<Error CustID="' + CAST(@CustID AS VARCHAR(30))
						+ '" ErrCode="' + CAST(ISNULL(@TempErrCode,'0') AS VARCHAR(5))
						+ '" ErrMsg="' + ISNULL(@TempErrMsg,'') + '" />'
		END CATCH

		SELECT @oldValue = '<EAS_CustomerUpdSuperInfo_Multiple FirstName="' + COALESCE(@oldFirstName, SPACE(1)) 
						+ '" LastName ="' + COALESCE(@oldLastName, SPACE(1)) 
						+ '" Phone="' + COALESCE(@oldPhone, SPACE(1))  
						+ '" Mobilephone="' + COALESCE(@oldMobilephone, SPACE(1)) 
						+ '" IP="' + COALESCE(@IP, SPACE(1))

		SELECT @newValue = '<EAS_CustomerUpdSuperInfo_Multiple FirstName="'  + COALESCE(ISNULL(@firstname,@oldFirstName), SPACE(1)) 
						+ '" LastName ="' + COALESCE(ISNULL(@lastname,@oldLastName), SPACE(1))
						+ '" Phone="' + COALESCE(ISNULL(@phone,@oldPhone), SPACE(1)) 
						+ '" Mobilephone="' + COALESCE(ISNULL(@mobilephone, @oldMobilephone), SPACE(1)) 
						+ '" IP="' + COALESCE(@IP, SPACE(1))

		SET @endRun = GETDATE()
		SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

		BEGIN TRY
			DECLARE @tempNewValue NVARCHAR(MAX)
				,@tempOldValue NVARCHAR(MAX)

			SELECT @tempNewValue = @newValue + '" ErrCode="' + COALESCE(CAST(@TempErrCode AS VARCHAR(50)), space(1)) + '" ErrMsg="' + COALESCE(@TempErrMsg, space(1)) + '" />'
				,@tempOldValue = @oldValue + '" ErrCode="' + COALESCE(CAST(@TempErrCode AS VARCHAR(50)), space(1)) + '" ErrMsg="' + COALESCE(@TempErrMsg, space(1)) + '" />'

			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @userid
				,@CustID = @CustId
				,@ActionID = @ActionID
				,@TrackingValue = @tempNewValue
				,@TrackingValue2 = @tempOldValue
				,@duration = @duration
		END TRY

		BEGIN CATCH
			SELECT @oldValue = @oldValue + '" ErrMsg="' + ERROR_MESSAGE() + '" />'

			SELECT @newValue = @newValue + '" ErrMsg="' + ERROR_MESSAGE() + '" />'

			EXEC DBCUST.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @userid
				,@CustID = @CustID
				,@ActionID = @ActionID
				,@TrackingValue = @newValue
				,@TrackingValue2 = @oldValue
				,@duration = @duration
		END CATCH
	END

	SET @ErrMsg += '</ROOT>'
END
GO