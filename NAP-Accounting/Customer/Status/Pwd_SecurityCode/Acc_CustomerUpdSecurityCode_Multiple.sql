/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
 ALTER PROCEDURE [dbo].[Acc_CustomerUpdSecurityCode_Multiple]
	@CustIDList VARCHAR(MAX),
	@userid		INT,
	@isForcedChangeSecurityCode BIT = 1,
	@language	VARCHAR(2) = 'E' ,
	@IP			VARCHAR(20) = '',
	@ErrMsg		NVARCHAR(MAX) = '' OUTPUT
 AS
/*
	Created: Tacy@20240308
	Task : update Security code of customer
	DB: DBCust/Custdb
	Original: Acc_CustomerUpdSecurityCode

	Revisions: 
		- 20240308@Tacy: Create SP [Redmine: #201432] 
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]

	Parameter's Explanation:
		@CustIDList = <Root>
							<SecurityCode CustID="23003140" Code="ec286a9066bdfb076782f6244f92bcbecbb6fea8"/>
							<SecurityCode CustID="20650722" Code="feea6654e22a03fc20620dde603121c3fd6a893f"/>
							<SecurityCode CustID="17241027" Code="cf4c8b6b4003410143c18f7ee09229139ad62e59"/>
						</Root>

	• @ErrMsg: Error description.
		@ErrMsg = <Root>
						<Error CustID="20650722" ErrCode="101" ErrMsg="Reset security code unsuccesful. Please try again."/>
					</Root>
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT
			,@roleid INT
			,@LogSPData VARCHAR(MAX)
			,@SecurityCode	VARCHAR(50)
			,@CustId INT
	
	DECLARE @TempErrMsg NVARCHAR(1000)
	DECLARE @TempErrCode INT

	SET @startRun = GETDATE()
	
	SET @ErrMsg = '<ROOT>';
	
	DECLARE @tblCust TABLE (
		CustID			INT PRIMARY KEY
		,SecurityCode	VARCHAR(50)
		,IsFinished		BIT DEFAULT(0)
	)

	--Parse XML data
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @CustIDList

	--Parse LIST CustID
	INSERT INTO @tblCust (CustID, SecurityCode)
	SELECT  CustID, Code
	FROM OPENXML(@iDoc, '/Root/SecurityCode', 1) WITH (
				 CustID	INT
				,Code	VARCHAR(50)
			)

	EXEC sp_xml_removedocument @iDoc

	WHILE EXISTS (SELECT TOP 1 1 FROM @tblCust WHERE IsFinished=0)
	BEGIN
		GetCustId:
			UPDATE TOP (1) T
			SET	t.IsFinished=1
				,@CustID = t.CustID
				,@SecurityCode=t.SecurityCode
			FROM @tblCust t
			WHERE IsFinished=0

		SELECT @TempErrCode = NULL, @TempErrMsg = NULL

		--Check disable user
		EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid,
			@ErrCode = @TempErrCode OUTPUT, @ErrMsg = @TempErrMsg OUTPUT

		IF @TempErrCode <> 0 
		BEGIN
			GOTO SetErr
		END

		SELECT @roleid = roleid 
		FROM custinfo WITH(NOLOCK)
		WHERE custid = @custid

		IF @roleid BETWEEN 2 AND 4 OR @roleid = 0--headline cn88
		BEGIN	
			IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo WITH(NOLOCK) WHERE custid = @custid)
			BEGIN
				SELECT @TempErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
						@TempErrCode = 100

				GOTO SetErr
			END
		
			UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
			SET SecurityCode = @SecurityCode
				,isForcedChangeSecurityCode = @isForcedChangeSecurityCode
				,LastChangedSecurityCodeDate = GETDATE()		
			WHERE custid = @custid
	
			IF @@Error > 0
			BEGIN
				SELECT @TempErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
						@TempErrCode = 101
				
				GOTO SetErr
			END
		
			SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode_Multiple custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 
								+ 'isForcedChange="' + COALESCE(CAST(@isForcedChangeSecurityCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@TempErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + COALESCE(@TempErrMsg, SPACE(1)) + '" />'
		
			SET @endRun = GETDATE()
			SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = 955, 
				@TrackingValue = @LogSPData,
				@duration = @duration		
		END
		ELSE IF @roleid = 1
		BEGIN	
			IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo_Member WITH(NOLOCK) WHERE custid = @custid)
			BEGIN
				INSERT INTO [CustLoginInfo_Member]([CustID],[SecurityCode],[IP],[LastChangedID],[LastChangedDate])
				VALUES(@custid,@SecurityCode,@IP,@userid,GETDATE())
			END
			ELSE
			BEGIN
				UPDATE CustLoginInfo_Member WITH(UPDLOCK,ROWLOCK)
				SET SecurityCode = @SecurityCode
					,IP = @IP
					,LastChangedID = @userID
					,LastChangedDate = GETDATE()
				WHERE custid = @custid

				IF @@Error > 0
				BEGIN
					SELECT @TempErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
							@TempErrCode = 201
					
					GOTO SetErr
				END
			END
		
			SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode_Multiple custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 							
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@TempErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + COALESCE(@TempErrMsg, SPACE(1)) + '" />'
		
			SET @endRun = GETDATE()
			SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = 955, 
				@TrackingValue = @LogSPData,
				@duration = @duration		
		END
	END

	IF @TempErrCode <> 0
	BEGIN
		SetErr:
			BEGIN
				SET @ErrMsg += '<Error CustID="' + CAST(@CustID AS VARCHAR(30))
							+ '" ErrCode="' + CAST(ISNULL(@TempErrCode,'0') AS VARCHAR(5))
							+ '" ErrMsg="' + ISNULL(@TempErrMsg,'') + '" />'
							
				GOTO GetCustId
			END
	END

	SET @ErrMsg += '</ROOT>'
END
GO